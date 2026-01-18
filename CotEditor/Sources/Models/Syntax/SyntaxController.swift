//
//  SyntaxController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2026 1024jp
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
import Combine
import AppKit.NSTextStorage
import OSLog
import StringUtils
import Syntax

extension NSAttributedString.Key {
    
    static let syntaxType = NSAttributedString.Key("CotEditor.SyntaxType")
}


@MainActor final class SyntaxController {
    
    // MARK: Public Properties
    
    private(set) var syntax: Syntax
    
    var theme: Theme?
    
    @Published private(set) var outlineItems: [OutlineItem]?
    
    
    // MARK: Private Properties
    
    private let minimumParseLength = 5_000
    
    private let textStorage: NSTextStorage
    
    private var outlineExtractors: [OutlineExtractor]
    private var highlightParser: HighlightParser
    
    private var outlineParseTask: Task<Void, any Error>?
    private var highlightParseTask: Task<Void, any Error>?
    private var invalidRanges: EditedRangeSet
    
    
    // MARK: Lifecycle
    
    init(textStorage: NSTextStorage, syntax: Syntax) {
        
        self.textStorage = textStorage
        self.syntax = syntax
        
        self.outlineExtractors = syntax.outlineExtractors
        self.highlightParser = syntax.highlightParser
        
        self.invalidRanges = EditedRangeSet(range: textStorage.range)
    }
    
    
    isolated deinit {
        self.cancel()
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
    func update(syntax: Syntax) {
        
        self.cancel()
        
        self.syntax = syntax
        
        self.outlineExtractors = syntax.outlineExtractors
        self.highlightParser = syntax.highlightParser
        
        self.invalidateAllHighlight()
    }
}


// MARK: Outline

extension SyntaxController {
    
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
        self.outlineParseTask = Task {
            self.outlineItems = try await Task.detached {
                try await withThrowingTaskGroup { group in
                    for extractor in extractors {
                        group.addTask { try extractor.items(in: string, range: string.range) }
                    }
                    
                    return try await group.reduce(into: []) { $0 += $1 }
                        .sorted(using: KeyPathComparator(\.range.location))
                }
            }.value
        }
    }
}


// MARK: Syntax Highlight

extension SyntaxController {
    
    /// Updates the ranges to update the syntax highlight.
    ///
    /// - Parameters:
    ///   - editedRange: The edited range.
    ///   - delta: The change in length.
    func invalidateHighlight(in editedRange: NSRange, changeInLength delta: Int) {
        
        self.highlightParseTask?.cancel()
        self.highlightParseTask = nil
        
        self.invalidRanges.append(editedRange: editedRange, changeInLength: delta)
    }
    
    
    /// Make the entire text dirty for syntax highlighting.
    func invalidateAllHighlight() {
        
        self.highlightParseTask?.cancel()
        self.highlightParseTask = nil
        
        self.invalidRanges.update(editedRange: self.textStorage.range)
    }
    
    
    /// Updates highlights around the invalid ranges.
    func highlightIfNeeded() {
        
        guard let invalidRange = self.invalidRanges.range else { return }
        
        self.highlightParseTask?.cancel()
        self.highlightParseTask = Task {
            guard let (highlights, range) = try await self.parseHighlights(around: invalidRange) else { return }
            
            self.invalidRanges.clear()
            
            for layoutManager in self.textStorage.layoutManagers {
                layoutManager.apply(highlights: highlights, theme: self.theme, in: range)
            }
        }
    }
    
    
    // MARK: Private Methods
    
    /// Updates highlights around the invalid ranges.
    private func parseHighlights(around invalidRange: NSRange) async throws -> (highlights: [Highlight], range: NSRange)? {
        
        guard !self.textStorage.string.isEmpty else {
            return nil
        }
        
        // just clear current highlight and return if no coloring required
        guard !self.highlightParser.isEmpty else {
            return ([], self.textStorage.range)
        }
        
        // in case that wholeRange length becomes shorter than invalidRange
        guard invalidRange.upperBound <= self.textStorage.length else {
            Logger.app.debug("Invalid range \(invalidRange.description) for \(self.textStorage.length) length textStorage is passed to \(#function)")
            return nil
        }
        
        let highlightRange: NSRange = {
            let wholeRange = self.textStorage.range
            
            if invalidRange == wholeRange || wholeRange.length <= self.minimumParseLength {
                return wholeRange
            }
            
            var highlightRange = (self.textStorage.string as NSString).lineRange(for: invalidRange)
            
            // expand highlight range if the characters just before/after it is the same syntax type
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
            
            return if highlightRange.upperBound < self.minimumParseLength {
                NSRange(0..<highlightRange.upperBound)
            } else {
                highlightRange
            }
        }()
        
        // make sure the string is immutable
        // -> The `string` of NSTextStorage is actually a mutable object,
        //    and it can lead to a crash when a mutable string is passed to
        //    an NSRegularExpression instance (2016-11, macOS 10.12.1).
        let string = self.textStorage.string.immutable
        
        // parse in background
        let highlights = try await self.highlightParser.parse(string: string, range: highlightRange)
        
        return (highlights, highlightRange)
    }
}
