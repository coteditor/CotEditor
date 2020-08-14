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
//  © 2014-2020 1024jp
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
    
    private let outlineParseOperationQueue = OperationQueue(name: "com.coteditor.CotEditor.outlineParseOperationQueue", qos: .utility)
    private let syntaxHighlightParseOperationQueue = OperationQueue(name: "com.coteditor.CotEditor.syntaxHighlightParseOperationQueue", qos: .userInitiated)
    
    private var highlightCache: Cache?  // results cache of the last whole string highlights
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(textStorage: NSTextStorage, style: SyntaxStyle = SyntaxStyle()) {
        
        self.textStorage = textStorage
        self.style = style
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
        self.outlineParseOperationQueue.cancelAllOperations()
        self.syntaxHighlightParseOperationQueue.cancelAllOperations()
    }
    
}



// MARK: - Outline

extension SyntaxParser {
    
    /// Parse outline.
    func invalidateOutline() {
        
        guard
            self.canParse,
            !self.style.outlineExtractors.isEmpty,
            !self.textStorage.range.isEmpty
        else {
            self.outlineItems = []
            return
        }
        
        self.outlineItems = nil
        
        let operation = OutlineParseOperation(extractors: self.style.outlineExtractors,
                                              string: self.textStorage.string.immutable,
                                              range: self.textStorage.range)
        operation.completionBlock = { [weak self, unowned operation] in
            self?.outlineItems = !operation.isCancelled ? operation.results : []
        }
        
        // -> Regarding the outline extraction, just cancel previous operations before parsing the latest string,
        //    since user cannot cancel it manually.
        self.outlineParseOperationQueue.cancelAllOperations()
        self.outlineParseOperationQueue.addOperation(operation)
    }
    
}



// MARK: - Syntax Highlight

extension SyntaxParser {
    
    /// Update highlights around passed-in range.
    ///
    /// - Parameters:
    ///   - editedRange: The character range that was edited, or highlight whole range if `nil` is passed in.
    /// - Returns: The progress of the async highlight task if performed.
    func highlight(around editedRange: NSRange? = nil) -> Progress? {
        
        assert(Thread.isMainThread)
        
        guard UserDefaults.standard[.enableSyntaxHighlight] else { return nil }
        guard !self.textStorage.string.isEmpty else { return nil }
        
        // in case that wholeRange length is changed from editedRange
        guard editedRange.flatMap({ $0.upperBound > self.textStorage.length }) != true else {
            assertionFailure("Invalid range is passed in to \(#function)")
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
        
        let definition = SyntaxHighlightParseOperation.ParseDefinition(extractors: self.style.highlightExtractors,
                                                                       pairedQuoteTypes: self.style.pairedQuoteTypes,
                                                                       inlineCommentDelimiter: self.style.inlineCommentDelimiter,
                                                                       blockCommentDelimiters: self.style.blockCommentDelimiters)
        
        let operation = SyntaxHighlightParseOperation(definition: definition, string: string, range: highlightRange)
        
        // give up if the editor's string is changed from the parsed string
        let isModified = Atomic(false)
        weak var modificationObserver: NSObjectProtocol?
        modificationObserver = NotificationCenter.default.addObserver(forName: NSTextStorage.didProcessEditingNotification, object: self.textStorage, queue: nil) { [weak operation] (note) in
            guard (note.object as! NSTextStorage).editedMask.contains(.editedCharacters) else { return }
            
            isModified.mutate { $0 = true }
            operation?.cancel()
            
            if let observer = modificationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        operation.completionBlock = { [weak self, weak operation, styleName = self.style.name] in
            guard
                let highlights = operation?.highlights,
                let progress = operation?.progress,
                !progress.isCancelled
                else {
                    if let observer = modificationObserver {
                        NotificationCenter.default.removeObserver(observer)
                    }
                    return
                }
            
            DispatchQueue.main.async {
                defer {
                    if let observer = modificationObserver {
                        NotificationCenter.default.removeObserver(observer)
                    }
                }
                
                guard !isModified.value else {
                    progress.cancel()
                    return
                }
                
                // cache result if whole text was parsed
                if highlightRange == string.nsRange {
                    self?.highlightCache = Cache(styleName: styleName, string: string, highlights: highlights)
                }
                
                self?.textStorage.apply(highlights: highlights, range: highlightRange)
                
                progress.completedUnitCount += 1
            }
        }
        
        self.syntaxHighlightParseOperationQueue.addOperation(operation)
        
        return operation.progress
    }
    
}



private extension NSTextStorage {
    
    /// apply highlights to the document
    func apply(highlights: [SyntaxType: [NSRange]], range highlightRange: NSRange) {
        
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
    func invalidateHighlight(theme: Theme, range: NSRange? = nil) {
        
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
