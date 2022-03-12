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
//  © 2014-2022 1024jp
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

private extension NSAttributedString.Key {
    
    static let syntaxType = NSAttributedString.Key("CotEditor.SyntaxType")
}



// MARK: -

final class SyntaxParser {
    
    private struct Cache {
        
        var styleName: String
        var string: String
        var highlights: [SyntaxType: [NSRange]]
    }
    
    
    // MARK: Public Properties
    
    let textStorage: NSTextStorage
    
    var style: SyntaxStyle
    
    @Published private(set) var outlineItems: [OutlineItem]?
    
    
    // MARK: Private Properties
    
    private var outlineParseTask: Task<Void, Error>?
    private var highlightParseTask: Task<Void, Error>?
    
    private var highlightCache: Cache?  // results cache of the last whole string highlights
    
    private var textEditingObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(textStorage: NSTextStorage, style: SyntaxStyle = SyntaxStyle()) {
        
        self.textStorage = textStorage
        self.style = style
        
        // give up if the string is changed while parsing
        self.textEditingObserver = NotificationCenter.default.publisher(for: NSTextStorage.willProcessEditingNotification, object: textStorage)
            .map { $0.object as! NSTextStorage }
            .filter { $0.editedMask.contains(.editedCharacters) }
            .sink { [weak self] _ in self?.highlightParseTask?.cancel() }
    }
    
    
    deinit {
        self.invalidateCurrentParse()
    }
    
    
    
    // MARK: Public Methods
    
    /// Whether syntax should be parsed.
    var canParse: Bool {
        
        return UserDefaults.standard[.enableSyntaxHighlight] && !self.style.isNone
    }
    
    
    /// Cancel all syntax parse including ones in the queues.
    func invalidateCurrentParse() {
        
        self.highlightCache = nil
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
            self.canParse,
            !self.style.outlineExtractors.isEmpty,
            !self.textStorage.range.isEmpty
        else {
            self.outlineItems = []
            return
        }
        
        self.outlineItems = nil
        
        let extractors = self.style.outlineExtractors
        let string = self.textStorage.string.immutable
        let range = self.textStorage.range
        self.outlineParseTask = Task.detached(priority: .utility) { [weak self] in
            self?.outlineItems = try await withThrowingTaskGroup(of: [OutlineItem].self) { group in
                for extractor in extractors {
                    group.addTask { try await extractor.items(in: string, range: range) }
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
    ///   - editedRange: The character range that was edited, or highlight whole range if `nil` is passed in.
    /// - Returns: The progress of the async highlight task if performed.
    @MainActor func highlight(around editedRange: NSRange? = nil) -> Progress? {
        
        assert(Thread.isMainThread)
        
        guard UserDefaults.standard[.enableSyntaxHighlight] else { return nil }
        guard !self.textStorage.string.isEmpty else { return nil }
        
        // in case that wholeRange length is changed from editedRange
        guard editedRange.flatMap({ $0.upperBound > self.textStorage.length }) != true else {
            assertionFailure("Invalid range \(editedRange?.description ?? "nil") is passed in to \(#function)")
            return nil
        }
        
        let wholeRange = self.textStorage.range
        let highlightRange: NSRange = {
            guard let editedRange = editedRange, editedRange != wholeRange else { return wholeRange }
            
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
                    highlightRange = NSRange(location: effectiveRange.lowerBound,
                                             length: highlightRange.upperBound - effectiveRange.lowerBound)
                }
                
                if highlightRange.upperBound < wholeRange.upperBound,
                    let effectiveRange = layoutManager.effectiveRange(of: .syntaxType, at: highlightRange.upperBound)
                {
                    highlightRange.length = effectiveRange.upperBound - highlightRange.location
                }
            }
            
            if highlightRange.upperBound < bufferLength {
                return NSRange(location: 0, length: highlightRange.upperBound)
            }
            
            return highlightRange
        }()
        
        guard !highlightRange.isEmpty else { return nil }
        
        // just clear current highlight and return if no coloring needs
        guard self.style.hasHighlightDefinition else {
            self.textStorage.apply(highlights: [:], range: highlightRange)
            return nil
        }
        
        // use cache if the content of the whole document is the same as the last
        if
            highlightRange == wholeRange,
            let cache = self.highlightCache,
            cache.styleName == self.style.name,
            cache.string == self.textStorage.string
        {
            self.textStorage.apply(highlights: cache.highlights, range: highlightRange)
            return nil
        }
        
        // make sure that string is immutable
        // -> `string` of NSTextStorage is actually a mutable object
        //    and it can cause crash when a mutable string is given to NSRegularExpression instance.
        //    (2016-11, macOS 10.12.1 SDK)
        let string = self.textStorage.string.immutable
        
        return self.highlight(string: string, range: highlightRange)
    }
    
    
    
    // MARK: Private Methods
    
    /// perform highlighting
    private func highlight(string: String, range highlightRange: NSRange) -> Progress {
        
        assert(Thread.isMainThread)
        assert(!(string as NSString).className.contains("MutableString"))
        assert(!highlightRange.isEmpty)
        assert(!self.style.isNone)
        
        let definition = HighlightParser.Definition(extractors: self.style.highlightExtractors,
                                                    nestablePaires: self.style.nestablePaires,
                                                    inlineCommentDelimiter: self.style.inlineCommentDelimiter,
                                                    blockCommentDelimiters: self.style.blockCommentDelimiters)
        let parser = HighlightParser(definition: definition, string: string, range: highlightRange)
        
        let task = Task.detached(priority: .userInitiated) { [weak self, styleName = self.style.name] in
            let highlights = try await parser.parse()
            
            try Task.checkCancellation()
            
            parser.progress.localizedDescription = "Applying colors to text…".localized
            try await Task.sleep(nanoseconds: 10_000_000)  // wait 0.01 seconds for GUI update
            
            await self?.textStorage.apply(highlights: highlights, range: highlightRange)
            
            if highlightRange == string.nsRange {
                self?.highlightCache = Cache(styleName: styleName, string: string, highlights: highlights)
            }
            parser.progress.completedUnitCount += 1
        }
        parser.progress.totalUnitCount += 1  // +1 for highlighting
        parser.progress.cancellationHandler = { task.cancel() }
        
        self.highlightParseTask?.cancel()
        self.highlightParseTask = task
        
        return parser.progress
    }
    
}



private extension NSTextStorage {
    
    /// apply highlights to the document
    @MainActor func apply(highlights: [SyntaxType: [NSRange]], range highlightRange: NSRange) {
        
        assert(Thread.isMainThread)
        
        guard self.length > 0 else { return }
        
        let hasHighlight = highlights.values.contains { !$0.isEmpty }
        
        for layoutManager in self.layoutManagers {
            // skip if never colorlized yet to avoid heavy `layoutManager.invalidateDisplay(forCharacterRange:)`
            guard hasHighlight || layoutManager.hasTemporaryAttribute(.syntaxType, in: highlightRange) else { continue }
            
            let theme = (layoutManager.firstTextView as? Themable)?.theme
            
            layoutManager.groupTemporaryAttributesUpdate(in: highlightRange) {
                layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: highlightRange)
                layoutManager.removeTemporaryAttribute(.syntaxType, forCharacterRange: highlightRange)
                
                for type in SyntaxType.allCases {
                    guard
                        let ranges = highlights[type]?.compactMap({ $0.intersection(highlightRange) }),
                        !ranges.isEmpty else { continue }
                    
                    for range in ranges {
                        layoutManager.addTemporaryAttribute(.syntaxType, value: type, forCharacterRange: range)
                    }
                    
                    if let color = theme?.style(for: type)?.color {
                        for range in ranges {
                            layoutManager.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: range)
                        }
                    } else {
                        for range in ranges {
                            layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: range)
                        }
                    }
                }
            }
        }
    }
    
}



extension NSLayoutManager {
    
    /// Apply the theme based on the current `syntaxType` attributes.
    ///
    /// - Parameter theme: The theme to apply.
    /// - Parameter range: The range to invalidate. If `nil`, whole string will be invalidated.
    @MainActor func invalidateHighlight(theme: Theme, range: NSRange? = nil) {
        
        assert(Thread.isMainThread)
        
        let wholeRange = range ?? self.attributedString().range
        
        self.groupTemporaryAttributesUpdate(in: wholeRange) {
            self.enumerateTemporaryAttribute(.syntaxType, in: wholeRange) { (type, range, _) in
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
