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
//  © 2014-2018 1024jp
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

import Cocoa

protocol SyntaxParserDelegate: class {
    
    func syntaxParser(_ syntaxParser: SyntaxParser, didParseOutline outlineItems: [OutlineItem])
    func syntaxParser(_ syntaxParser: SyntaxParser, didStartParsingOutline progress: Progress)
}



final class SyntaxParser {
    
    static let didUpdateOutlineNotification = Notification.Name("SyntaxStyleDidUpdateOutline")
    
    
    // MARK: Public Properties
    
    let textStorage: NSTextStorage
    
    var style: SyntaxStyle {
        
        willSet {
            self.cancelAllParses()
            self.outlineItems = []
        }
    }
    
    weak var delegate: SyntaxParserDelegate?
    
    private(set) var outlineItems: [OutlineItem] = [] {
        
        didSet {
            // inform about outline items update
            DispatchQueue.main.async { [weak self, items = self.outlineItems] in
                guard let strongSelf = self else { return }
                
                strongSelf.delegate?.syntaxParser(strongSelf, didParseOutline: items)
                NotificationCenter.default.post(name: SyntaxParser.didUpdateOutlineNotification, object: strongSelf)
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private let outlineParseOperationQueue = OperationQueue(name: "com.coteditor.CotEditor.outlineParseOperationQueue")
    private let syntaxHighlightParseOperationQueue = OperationQueue(name: "com.coteditor.CotEditor.syntaxHighlightParseOperationQueue")
    
    private var highlightCache: (highlights: [SyntaxType: [NSRange]], hash: String)?  // results cache of the last whole string highlights
    
    private lazy var outlineUpdateTask: Debouncer = Debouncer(delay: 0.4) { [weak self] in self?.parseOutline() }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(textStorage: NSTextStorage, style: SyntaxStyle = SyntaxStyle()) {
        
        self.textStorage = textStorage
        self.style = style
    }
    
    
    deinit {
        self.cancelAllParses()
    }
    
    
    
    // MARK: Public Methods
    
    /// whether enable parsing syntax
    var canParse: Bool {
        
        return UserDefaults.standard[.enableSyntaxHighlight] && !self.style.isNone
    }
    
    
    /// cancel all syntax parse
    func cancelAllParses() {
        
        self.outlineUpdateTask.cancel()
        self.outlineParseOperationQueue.cancelAllOperations()
        self.syntaxHighlightParseOperationQueue.cancelAllOperations()
    }
    
}



// MARK: - Outline

extension SyntaxParser {
    
    /// parse outline with delay
    func invalidateOutline() {
        
        guard
            self.canParse,
            !self.style.outlineExtractors.isEmpty
            else {
                self.outlineItems = []
                return
        }
        
        self.outlineUpdateTask.schedule()
    }
    
    
    
    // MARK: Private Methods
    
    /// parse outline
    private func parseOutline() {
        
        let string = self.textStorage.string
        guard !string.isEmpty else {
            self.outlineItems = []
            return
        }
        
        let operation = OutlineParseOperation(extractors: self.style.outlineExtractors)
        operation.string = string.immutable  // make sure being immutable
        operation.parseRange = string.nsRange
        
        operation.completionBlock = { [weak self, weak operation] in
            guard let operation = operation, !operation.isCancelled else { return }
            
            self?.outlineItems = operation.results
        }
        
        self.outlineParseOperationQueue.addOperation(operation)
        
        self.delegate?.syntaxParser(self, didStartParsingOutline: operation.progress)
    }
    
}



// MARK: - Syntax Highlight

extension SyntaxParser {
    
    /// update whole document highlights
    func highlightAll(completionHandler: (() -> Void)? = nil) -> Progress? {  // @escaping
        
        assert(Thread.isMainThread)
        
        guard UserDefaults.standard[.enableSyntaxHighlight] else { return nil }
        guard !self.textStorage.string.isEmpty else { return nil }
        
        let wholeRange = self.textStorage.string.nsRange
        
        // use cache if the content of the whole document is the same as the last
        if let cache = self.highlightCache, cache.hash == self.textStorage.string.md5 {
            self.apply(highlights: cache.highlights, range: wholeRange)
            completionHandler?()
            return nil
        }
        
        // make sure that string is immutable
        //   -> `string` of NSTextStorage is actually a mutable object
        //      and it can cause crash when the mutable string is given to NSRegularExpression instance.
        //      (2016-11, macOS 10.12.1 SDK)
        let string = self.textStorage.string.immutable
        
        // avoid parsing twice for the same string
        guard (self.syntaxHighlightParseOperationQueue.operations.last as? SyntaxHighlightParseOperation)?.string != string else { return nil }
        
        return self.highlight(string: string, range: wholeRange, completionHandler: completionHandler)
    }
    
    
    /// update highlights around passed-in range
    func highlight(around editedRange: NSRange) -> Progress? {
        
        assert(Thread.isMainThread)
        
        guard UserDefaults.standard[.enableSyntaxHighlight] else { return nil }
        guard !self.textStorage.string.isEmpty else { return nil }
        
        // make sure that string is immutable (see `highlightAll()` for details)
        let string = self.textStorage.string.immutable
        
        let wholeRange = string.nsRange
        let bufferLength = UserDefaults.standard[.coloringRangeBufferLength]
        
        // in case that wholeRange length is changed from editedRange
        guard var highlightRange = editedRange.intersection(wholeRange) else { return nil }
        
        // highlight whole if string is enough short
        if wholeRange.length <= bufferLength {
            highlightRange = wholeRange
            
        } else {
            // highlight whole visible area if edited point is visible
            for layoutManager in self.textStorage.layoutManagers {
                guard let visibleRange = layoutManager.firstTextView?.visibleRange else { continue }
                
                if editedRange.intersection(visibleRange) != nil {
                    highlightRange.formUnion(visibleRange)
                }
            }
            
            highlightRange = highlightRange.intersection(wholeRange)!
            highlightRange = (string as NSString).lineRange(for: highlightRange)
            
            // expand highlight area if the character just before/after the highlighting area is the same color
            if let layoutManager = self.textStorage.layoutManagers.first {
                var start = highlightRange.lowerBound
                var end = highlightRange.upperBound
                var effectiveRange = NSRange.notFound
                
                if start <= bufferLength {
                    start = 0
                } else {
                    if layoutManager.temporaryAttribute(.foregroundColor,
                                                        atCharacterIndex: start,
                                                        longestEffectiveRange: &effectiveRange,
                                                        in: wholeRange) != nil {
                        start = effectiveRange.lowerBound
                    }
                }
                if layoutManager.temporaryAttribute(.foregroundColor,
                                                    atCharacterIndex: end,
                                                    longestEffectiveRange: &effectiveRange,
                                                    in: wholeRange) != nil {
                    end = effectiveRange.upperBound
                }
                
                highlightRange = NSRange(start..<end)
            }
        }
        
        return self.highlight(string: string, range: highlightRange)
    }
    
    
    
    // MARK: Private Methods
    
    /// perform highlighting
    private func highlight(string: String, range highlightRange: NSRange, completionHandler: (() -> Void)? = nil) -> Progress? {  // @escaping
        
        guard highlightRange.length > 0 else { return nil }
        
        // just clear current highlight and return if no coloring needs
        guard self.style.hasHighlightDefinition else {
            self.apply(highlights: [:], range: highlightRange)
            completionHandler?()
            return nil
        }
        
        let operation = SyntaxHighlightParseOperation(extractors: self.style.highlightExtractors,
                                                      pairedQuoteTypes: self.style.pairedQuoteTypes,
                                                      inlineCommentDelimiter: self.style.inlineCommentDelimiter,
                                                      blockCommentDelimiters: self.style.blockCommentDelimiters)
        operation.string = string
        operation.parseRange = highlightRange
        
        operation.highlightBlock = { [weak self] (highlights) in
            // cache result if whole text was parsed
            if highlightRange.length == string.utf16.count {
                self?.highlightCache = (highlights: highlights, hash: string.md5)
            }
            
            DispatchQueue.main.async {
                // give up if the editor's string is changed from the analized string
                guard self?.textStorage.string == string else { return }
                
                self?.apply(highlights: highlights, range: highlightRange)
            }
        }
        
        operation.completionBlock = completionHandler
        
        self.syntaxHighlightParseOperationQueue.addOperation(operation)
        
        return operation.progress
    }
    
    
    /// whether need to display highlighting indicator
    private func shouldShowIndicator(for highlightLength: Int) -> Bool {
        
        let threshold = UserDefaults.standard[.showColoringIndicatorTextLength]
        
        // do not show indicator if threshold is 0
        return threshold > 0 && highlightLength > threshold
    }
    
    
    /// apply highlights to the document
    private func apply(highlights: [SyntaxType: [NSRange]], range highlightRange: NSRange) {
        
        assert(Thread.isMainThread)
        
        for layoutManager in self.textStorage.layoutManagers {
            layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: highlightRange)
            
            guard let theme = (layoutManager.firstTextView as? Themable)?.theme else { continue }
            
            for type in SyntaxType.all {
                guard let ranges = highlights[type], !ranges.isEmpty else { continue }
                
                let color = theme.style(for: type)?.color ?? theme.text.color
                
                for range in ranges {
                    layoutManager.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: range)
                }
            }
        }
    }
    
}
