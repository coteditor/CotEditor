//
//  SyntaxParser.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2024 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import AppKit.NSTextStorage
import OSLog
import EditedRangeSet
import StringUtils
import Syntax

extension NSAttributedString.Key {
    
    static let syntaxType = NSAttributedString.Key("CotEditor.SyntaxType")
}


@MainActor final class SyntaxParser {
    
    // MARK: Public Properties
    
    private(set) var name: String
    private(set) var syntax: Syntax
    
    var theme: Theme?
    
    @Published private(set) var outlineItems: [OutlineItem]?
    
    
    // MARK: Private Properties
    
    private static let bufferLength = 5_000
    
    private let textStorage: NSTextStorage
    
    private lazy var outlineExtractors: [OutlineExtractor] = self.syntax.outlineExtractors
    private lazy var highlightParser: HighlightParser = self.syntax.highlightParser
    
    private var outlineParseTask: Task<Void, any Error>?
    private var highlightParseTask: Task<Void, any Error>?
    private var invalidRanges: EditedRangeSet
    
    
    // MARK: Lifecycle
    
    init(textStorage: NSTextStorage, syntax: Syntax, name: String) {
        
        self.textStorage = textStorage
        self.syntax = syntax
        self.name = name
        
        self.invalidRanges = EditedRangeSet(range: textStorage.range)
    }
    
    
    /// Cancels all remaining tasks.
    func cancel() {
        
        self.outlineParseTask?.cancel()
        self.outlineParseTask = nil
        self.highlightParseTask?.cancel()
        self.highlightParseTask = nil
    }
    
    
    /// Updates the syntax definition for parsing.
    ///
    /// - Parameters:
    ///   - syntax: The syntax.
    ///   - name: The name of the syntax.
    func update(syntax: Syntax, name: String) {
        
        self.cancel()
        
        self.outlineExtractors = syntax.outlineExtractors
        self.highlightParser = syntax.highlightParser
        
        self.syntax = syntax
        self.name = name
        self.invalidRanges.clear()
    }
}


// MARK: Outline

extension SyntaxParser {
    
    /// Parses outline.
    func invalidateOutline() {
        
        self.outlineParseTask?.cancel()
        
        guard
            !self.outlineExtractors.isEmpty,
            !self.textStorage.range.isEmpty
        else {
            self.outlineItems = []
            return
        }
        
        self.outlineItems = nil
        
        let extractors = self.outlineExtractors
        let string = self.textStorage.string.immutable
        self.outlineParseTask = Task.detached {
            let outlineItems = try await withThrowingTaskGroup(of: [OutlineItem].self) { group in
                for extractor in extractors {
                    group.addTask { try extractor.items(in: string, range: string.range) }
                }
                
                return try await group.reduce(into: []) { $0 += $1 }
                    .sorted(using: SortDescriptor(\.range.location))
            }
            
            await MainActor.run {
                self.outlineItems = outlineItems
            }
        }
    }
}


// MARK: Syntax Highlight

extension SyntaxParser {
    
    /// Updates the ranges to update the syntax highlight..
    ///
    /// - Parameters:
    ///   - editedRange: The edited range.
    ///   - delta: The change in length.
    func invalidateHighlight(in editedRange: NSRange, changeInLength delta: Int) {
        
        self.highlightParseTask?.cancel()
        self.highlightParseTask = nil
        
        self.invalidRanges.append(editedRange: editedRange, changeInLength: delta)
    }
    
    
    /// Updates highlights of the entire range.
    func highlightAll() {
        
        self.invalidRanges.update(editedRange: self.textStorage.range)
        self.highlightIfNeeded()
    }
    
    
    /// Updates highlights around the invalid ranges.
    func highlightIfNeeded() {
        
        guard let invalidRange = self.invalidRanges.range else { return }
        
        self.highlightParseTask?.cancel()
        
        guard !self.textStorage.string.isEmpty else {
            self.invalidRanges.clear()
            return
        }
        
        // just clear current highlight and return if no coloring required
        guard !self.highlightParser.isEmpty else {
            self.invalidRanges.clear()
            self.apply(highlights: [], in: self.textStorage.range)
            return
        }
        
        let wholeRange = self.textStorage.range
        
        // in case that wholeRange length becomes shorter than invalidRange
        guard invalidRange.upperBound <= wholeRange.upperBound else {
            return Logger.app.debug("Invalid range \(invalidRange.description) for \(self.textStorage.length) length textStorage is passed in to \(#function)")
        }
        
        let highlightRange: NSRange = {
            guard invalidRange != wholeRange else { return wholeRange }
            
            // highlight whole if string is enough short
            if wholeRange.length <= Self.bufferLength {
                return wholeRange
            }
            
            // highlight whole visible area if edited point is visible
            var highlightRange = self.textStorage.layoutManagers
                .compactMap(\.textViewForBeginningOfSelection?.visibleRange)
                .filter { $0.intersects(invalidRange) }
                .reduce(into: invalidRange) { $0.formUnion($1) }
            
            highlightRange = (self.textStorage.string as NSString).lineRange(for: highlightRange)
            
            // expand highlight area if the character just before/after the highlighting area is the same syntax type
            if let layoutManager = self.textStorage.layoutManagers.first {
                if highlightRange.lowerBound > 0,
                   let effectiveRange = layoutManager.effectiveRange(of: .syntaxType, at: highlightRange.lowerBound)
                {
                    highlightRange = NSRange(effectiveRange.lowerBound..<highlightRange.upperBound)
                }
                
                if highlightRange.upperBound < wholeRange.upperBound,
                   let effectiveRange = layoutManager.effectiveRange(of: .syntaxType, at: highlightRange.upperBound)
                {
                    highlightRange = NSRange(highlightRange.lowerBound..<effectiveRange.upperBound)
                }
            }
            
            if highlightRange.upperBound < Self.bufferLength {
                return NSRange(location: 0, length: highlightRange.upperBound)
            }
            
            return highlightRange
        }()
        
        // make sure the string is immutable
        // -> `string` of NSTextStorage is actually a mutable object
        //    and it can cause crash when a mutable string is given to NSRegularExpression instance.
        //    (2016-11, macOS 10.12.1 SDK)
        let string = self.textStorage.string.immutable
        
        self.parse(string: string, range: highlightRange)
    }
    
    
    // MARK: Private Methods
    
    /// Parses the given string and performs highlighting.
    ///
    /// - Parameters:
    ///   - string: The string to parse.
    ///   - range: The character range where updates highlights.
    private func parse(string: String, range: NSRange) {
        
        assert(!(string as NSString).className.contains("Mutable"))
        assert(!range.isEmpty)
        assert(!self.highlightParser.isEmpty)
        
        self.highlightParseTask?.cancel()
        self.highlightParseTask = Task {
            let parser = self.highlightParser
            let highlights = try await parser.parse(string: string, range: range)
            
            self.apply(highlights: highlights, in: range)
            self.invalidRanges.clear()
        }
    }
    
    
    /// Applies highlights to all the layout managers.
    ///
    /// - Parameters:
    ///   - highlights: The syntax highlights to apply.
    ///   - range: The character range where updates highlights.
    private func apply(highlights: [Highlight], in range: NSRange) {
        
        for layoutManager in self.textStorage.layoutManagers {
            layoutManager.apply(highlights: highlights, theme: self.theme, in: range)
        }
    }
}
