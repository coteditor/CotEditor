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
//  © 2014-2023 1024jp
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

import Combine
import Foundation
import AppKit.NSTextStorage

extension NSAttributedString.Key {
    
    static let syntaxType = NSAttributedString.Key("CotEditor.SyntaxType")
}



// MARK: -

final class SyntaxParser {
    
    // MARK: Public Properties
    
    var syntax: Syntax {
        
        willSet {
            self.outlineParseTask?.cancel()
            self.highlightParseTask?.cancel()
        }
        didSet {
            self.outlineExtractors = syntax.outlineExtractors
            self.highlightParser = syntax.highlightParser
        }
    }
    
    @Published private(set) var outlineItems: [OutlineItem]?
    
    
    // MARK: Private Properties
    
    private let textStorage: NSTextStorage
    
    private lazy var outlineExtractors: [OutlineExtractor] = self.syntax.outlineExtractors
    private lazy var highlightParser: HighlightParser = self.syntax.highlightParser
    
    private var outlineParseTask: Task<Void, any Error>?
    private var highlightParseTask: Task<Void, any Error>?
    private var isHighlighting = false
    
    private var textEditingObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(textStorage: NSTextStorage, syntax: Syntax) {
        
        self.textStorage = textStorage
        self.syntax = syntax
        
        // give up if the string is changed while parsing
        self.textEditingObserver = NotificationCenter.default.publisher(for: NSTextStorage.willProcessEditingNotification, object: textStorage)
            .map { $0.object as! NSTextStorage }
            .filter { $0.editedMask.contains(.editedCharacters) }
            .sink { [weak self] _ in self?.highlightParseTask?.cancel() }
    }
    
    
    deinit {
        self.outlineParseTask?.cancel()
        self.highlightParseTask?.cancel()
    }
}



// MARK: - Outline

extension SyntaxParser {
    
    /// Parse outline.
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
        self.outlineParseTask = Task.detached(priority: .utility) { [weak self] in
            self?.outlineItems = try await withThrowingTaskGroup(of: [OutlineItem].self) { group in
                for extractor in extractors {
                    group.addTask { try extractor.items(in: string, range: string.range) }
                }
                
                return try await group.reduce(into: []) { $0 += $1 }
                    .sorted(\.range.location)
            }
        }
    }
}



// MARK: - Syntax Highlight

extension SyntaxParser {
    
    /// Update highlights around passed-in range.
    ///
    /// - Parameters:
    ///   - editedRange: The character range that was edited, or `nil` to highlight the entire range.
    @MainActor func highlight(around editedRange: NSRange? = nil) {
        
        // retry entire parsing if the last one has not finished yet
        var editedRange = editedRange
        if self.isHighlighting {
            self.highlightParseTask?.cancel()
            editedRange = nil
        }
        
        guard !self.textStorage.string.isEmpty else { return }
        
        // in case that wholeRange length is changed from editedRange
        guard editedRange.flatMap({ $0.upperBound > self.textStorage.length }) != true else {
            return debugPrint("⚠️ Invalid range \(editedRange?.description ?? "nil") for \(self.textStorage.length) length textStorage is passed in to \(#function)")
        }
        
        let wholeRange = self.textStorage.range
        
        // just clear current highlight and return if no coloring required
        guard !self.highlightParser.isEmpty else {
            return self.apply(highlights: [], range: wholeRange)
        }
        
        let highlightRange: NSRange = {
            guard let editedRange, editedRange != wholeRange else { return wholeRange }
            
            // highlight whole if string is enough short
            let bufferLength = UserDefaults.standard[.coloringRangeBufferLength]
            if wholeRange.length <= bufferLength {
                return wholeRange
            }
            
            // highlight whole visible area if edited point is visible
            var highlightRange = self.textStorage.layoutManagers
                .compactMap(\.textViewForBeginningOfSelection?.visibleRange)
                .filter { $0.intersects(editedRange) }
                .reduce(into: editedRange) { $0.formUnion($1) }
            
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
            
            if highlightRange.upperBound < bufferLength {
                return NSRange(location: 0, length: highlightRange.upperBound)
            }
            
            return highlightRange
        }()
        guard !highlightRange.isEmpty else { return }
        
        // make sure the string is immutable
        // -> `string` of NSTextStorage is actually a mutable object
        //    and it can cause crash when a mutable string is given to NSRegularExpression instance.
        //    (2016-11, macOS 10.12.1 SDK)
        let string = self.textStorage.string.immutable
        
        self.parse(string: string, range: highlightRange)
    }
    
    
    
    // MARK: Private Methods
    
    /// perform highlighting
    private func parse(string: String, range: NSRange) {
        
        assert(!(string as NSString).className.contains("Mutable"))
        assert(!range.isEmpty)
        assert(!self.highlightParser.isEmpty)
        
        let parser = self.highlightParser
        
        self.highlightParseTask?.cancel()
        self.highlightParseTask = Task.detached(priority: .userInitiated) { [weak self] in
            defer {
                self?.isHighlighting = false
            }
            let highlights = try await parser.parse(string: string, range: range)
            
            try Task.checkCancellation()
            
            await self?.apply(highlights: highlights, range: range)
        }
        
        // make large parse cancellable
        if range.length > 10_000 {
            self.isHighlighting = true
        }
    }
    
    
    /// apply highlights to all the layoutManagers.
    @MainActor private func apply(highlights: [Highlight], range: NSRange) {
        
        for layoutManager in self.textStorage.layoutManagers {
            layoutManager.apply(highlights: highlights, range: range)
        }
    }
}



extension NSLayoutManager {
    
    /// Extract all syntax highlights in the given range.
    ///
    /// - Returns: An array of Highlights in order.
    @MainActor final func syntaxHighlights() -> [Highlight] {
        
        let targetRange = self.attributedString().range
        
        var highlights: [Highlight] = []
        self.enumerateTemporaryAttribute(.syntaxType, in: targetRange) { (type, range, _) in
            guard let type = type as? SyntaxType else { return }
            
            highlights.append(Highlight(value: type, range: range))
        }
        
        return highlights
    }
    
    
    /// Apply highlights as temporary attributes.
    ///
    /// - Note: Sanitize the `highlights` before so that the ranges do not overlap each other.
    ///
    /// - Parameters:
    ///   - highlights: The highlight definitions to apply.
    ///   - range: The range to update syntax highlight.
    @MainActor final func apply(highlights: [Highlight], range: NSRange) {
        
        assert(highlights.sorted(\.range.location) == highlights)
        
        // skip if never colorized yet to avoid heavy `self.invalidateDisplay(forCharacterRange:)`
        guard !highlights.isEmpty || self.hasTemporaryAttribute(.syntaxType, in: range) else { return }
        
        let theme = (self.firstTextView as? any Themable)?.theme
        
        self.groupTemporaryAttributesUpdate(in: range) {
            self.removeTemporaryAttribute(.foregroundColor, forCharacterRange: range)
            self.removeTemporaryAttribute(.syntaxType, forCharacterRange: range)
            
            for highlight in highlights {
                self.addTemporaryAttribute(.syntaxType, value: highlight.value, forCharacterRange: highlight.range)
                
                if let color = theme?.style(for: highlight.value)?.color {
                    self.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: highlight.range)
                }
            }
        }
    }
    
    
    /// Apply the theme based on the current `syntaxType` attributes.
    ///
    /// - Parameters:
    ///   - theme: The theme to apply.
    @MainActor final func invalidateHighlight(theme: Theme) {
        
        let targetRange = self.attributedString().range
        
        guard self.hasTemporaryAttribute(.syntaxType, in: targetRange) else { return }
        
        self.groupTemporaryAttributesUpdate(in: targetRange) {
            self.enumerateTemporaryAttribute(.syntaxType, in: targetRange) { (type, range, _) in
                guard let type = type as? SyntaxType else { return }
                
                if let color = theme.style(for: type)?.color {
                    self.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: range)
                } else {
                    self.removeTemporaryAttribute(.foregroundColor, forCharacterRange: range)
                }
            }
        }
    }
}
