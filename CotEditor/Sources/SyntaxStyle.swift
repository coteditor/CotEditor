//
//  SyntaxStyle.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-22.
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

protocol SyntaxStyleDelegate: class {
    
    func syntaxStyle(_ syntaxStyle: SyntaxStyle, didParseOutline outlineItems: [OutlineItem])
}



final class SyntaxStyle: Equatable, CustomStringConvertible {
    
    static let didUpdateOutlineNotification = Notification.Name("SyntaxStyleDidUpdateOutline")
    
    
    // MARK: Public Properties
    
    var textStorage: NSTextStorage?
    weak var delegate: SyntaxStyleDelegate?
    
    let styleName: String
    let isNone: Bool
    
    let inlineCommentDelimiter: String?
    let blockCommentDelimiters: BlockDelimiters?
    
    let completionWords: [String]?
    
    private(set) var outlineItems: [OutlineItem] = [] {
        
        didSet {
            // inform about outline items update
            DispatchQueue.main.async { [weak self, items = self.outlineItems] in
                guard let strongSelf = self else { return }
                
                strongSelf.delegate?.syntaxStyle(strongSelf, didParseOutline: items)
                NotificationCenter.default.post(name: SyntaxStyle.didUpdateOutlineNotification, object: strongSelf)
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private let outlineParseOperationQueue = OperationQueue(name: "com.coteditor.CotEditor.outlineParseOperationQueue")
    private let syntaxHighlightParseOperationQueue = OperationQueue(name: "com.coteditor.CotEditor.syntaxHighlightParseOperationQueue")
    
    private let highlightDictionary: [SyntaxType: [HighlightDefinition]]
    private let pairedQuoteTypes: [String: SyntaxType]
    private let outlineDefinitions: [OutlineDefinition]
    
    private var highlightCache: (highlights: [SyntaxType: [NSRange]], hash: String)?  // results cache of the last whole string highlights
    
    private lazy var outlineUpdateTask: Debouncer = Debouncer(delay: 0.4) { [weak self] in self?.parseOutline() }
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(dictionary: [String: Any]?, name: String) {
        
        self.styleName = name
        
        guard let dictionary = dictionary else {
            self.isNone = true
            self.inlineCommentDelimiter = nil
            self.blockCommentDelimiters = nil
            self.completionWords = nil
            
            self.highlightDictionary = [:]
            self.pairedQuoteTypes = [:]
            self.outlineDefinitions = []
            
            return
        }
        
        self.isNone = false
        
        // set comment delimiters
        var inlineCommentDelimiter: String?
        var blockCommentDelimiters: BlockDelimiters?
        if let delimiters = dictionary[SyntaxKey.commentDelimiters.rawValue] as? [String: String] {
            if let delimiter = delimiters[DelimiterKey.inlineDelimiter.rawValue], !delimiter.isEmpty {
                inlineCommentDelimiter = delimiter
            }
            if let beginDelimiter = delimiters[DelimiterKey.beginDelimiter.rawValue],
                let endDelimiter = delimiters[DelimiterKey.endDelimiter.rawValue],
                !beginDelimiter.isEmpty, !endDelimiter.isEmpty
            {
                blockCommentDelimiters = BlockDelimiters(begin: beginDelimiter, end: endDelimiter)
            }
        }
        self.inlineCommentDelimiter = inlineCommentDelimiter
        self.blockCommentDelimiters = blockCommentDelimiters
        
        let definitionDictionary: [SyntaxType: [HighlightDefinition]] = SyntaxType.all.reduce(into: [:]) { (dict, type) in
            guard let wordDicts = dictionary[type.rawValue] as? [[String: Any]] else { return }
            
            let definitions = wordDicts.compactMap { HighlightDefinition(definition: $0) }
            
            guard !definitions.isEmpty else { return }
            
            dict[type] = definitions
        }
        
        // pick quote definitions up to parse quoted text separately with comments in `extractCommentsWithQuotes`
        // also combine simple word definitions into single regex definition
        var quoteTypes = [String: SyntaxType]()
        self.highlightDictionary = definitionDictionary.reduce(into: [:]) { (dict, item) in
            
            var highlightDefinitions = [HighlightDefinition]()
            var words = [String]()
            var caseInsensitiveWords = [String]()
            
            for definition in item.value {
                // extract quotes
                if !definition.isRegularExpression, definition.beginString == definition.endString,
                    definition.beginString.rangeOfCharacter(from: .alphanumerics) == nil,  // symbol
                    Set(definition.beginString).count == 1,  // consists of the same characters
                    !quoteTypes.keys.contains(definition.beginString)  // not registered yet
                {
                    quoteTypes[definition.beginString] = item.key
                    
                    // remove from the normal highlight definition list
                    continue
                }
                
                // extract simple words
                if !definition.isRegularExpression, definition.endString == nil {
                    if definition.ignoreCase {
                        caseInsensitiveWords.append(definition.beginString)
                    } else {
                        words.append(definition.beginString)
                    }
                    continue
                }
                
                highlightDefinitions.append(definition)
            }
            
            // transform simple word highlights to single regex for performance reasons
            if !words.isEmpty {
                highlightDefinitions.append(HighlightDefinition(words: words, ignoreCase: false))
            }
            if !caseInsensitiveWords.isEmpty {
                highlightDefinitions.append(HighlightDefinition(words: caseInsensitiveWords, ignoreCase: true))
            }
            
            guard !highlightDefinitions.isEmpty else { return }
            
            dict[item.key] = highlightDefinitions
        }
        self.pairedQuoteTypes = quoteTypes
        
        // create word-completion data set
        self.completionWords = {
            let words: [String]
            if let completionDicts = dictionary[SyntaxKey.completions.rawValue] as? [[String: Any]], !completionDicts.isEmpty {
                // create from completion definition
                words = completionDicts
                    .compactMap { $0[SyntaxDefinitionKey.keyString.rawValue] as? String }
                    .filter { !$0.isEmpty }
            } else {
                // create from normal highlighting words
                words = definitionDictionary.values.flatMap { $0 }
                    .filter { $0.endString == nil && !$0.isRegularExpression }
                    .map { $0.beginString.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
            
            return words.isEmpty ? nil : words.sorted()
        }()
        
        // parse outline definitions
        self.outlineDefinitions = {
            guard let definitionDictionaries = dictionary[SyntaxKey.outlineMenu.rawValue] as? [[String: Any]] else { return [] }
            
            return definitionDictionaries.compactMap { OutlineDefinition(definition: $0) }
        }()
    }
    
    
    convenience init() {
        
        self.init(dictionary: nil, name: BundledStyleName.none)
    }
    
    
    deinit {
        self.outlineParseOperationQueue.cancelAllOperations()
        self.syntaxHighlightParseOperationQueue.cancelAllOperations()
    }
    
    
    var description: String {
        
        return "<SyntaxStyle -\(self.styleName)>"
    }
    
    
    static func == (lhs: SyntaxStyle, rhs: SyntaxStyle) -> Bool {
        
        return lhs.styleName == rhs.styleName &&
            lhs.inlineCommentDelimiter == rhs.inlineCommentDelimiter &&
            lhs.blockCommentDelimiters == rhs.blockCommentDelimiters &&
            lhs.pairedQuoteTypes == rhs.pairedQuoteTypes &&
            lhs.outlineDefinitions == rhs.outlineDefinitions &&
            lhs.highlightDictionary == rhs.highlightDictionary
    }
    
    
    
    
    // MARK: Public Methods
    
    /// whether enable parsing syntax
    var canParse: Bool {
        
        let isHighlightEnabled = UserDefaults.standard[.enableSyntaxHighlight]
        
        return isHighlightEnabled && !self.isNone
    }
    
    
    /// cancel all syntax parse
    func cancelAllParses() {
        
        self.outlineParseOperationQueue.cancelAllOperations()
        self.syntaxHighlightParseOperationQueue.cancelAllOperations()
    }
    
}



// MARK: - Outline

extension SyntaxStyle {
    
    /// parse outline with delay
    func invalidateOutline() {
        
        guard
            self.canParse,
            !self.outlineDefinitions.isEmpty
            else {
                self.outlineItems = []
                return
            }
        
        self.outlineUpdateTask.schedule()
    }
    
    
    
    // MARK: Private Methods
    
    /// parse outline
    private func parseOutline() {
        
        guard let string = self.textStorage?.string, !string.isEmpty else {
            self.outlineItems = []
            return
        }
        
        let operation = OutlineParseOperation(definitions: self.outlineDefinitions)
        operation.string = string.immutable  // make sure being immutable
        operation.parseRange = string.nsRange
        
        operation.completionBlock = { [weak self, weak operation] in
            guard let operation = operation, !operation.isCancelled else { return }
            
            self?.outlineItems = operation.results
        }
        
        self.outlineParseOperationQueue.addOperation(operation)
    }
    
}



// MARK: - Syntax Highlight

extension SyntaxStyle {
    
    /// update whole document highlights
    func highlightAll(completionHandler: (() -> Void)? = nil) -> Progress? {  // @escaping
        
        assert(Thread.isMainThread)
        
        guard UserDefaults.standard[.enableSyntaxHighlight] else { return nil }
        guard let textStorage = self.textStorage, !textStorage.string.isEmpty else { return nil }
        
        let wholeRange = textStorage.string.nsRange
        
        // use cache if the content of the whole document is the same as the last
        if let cache = self.highlightCache, cache.hash == textStorage.string.md5 {
            self.apply(highlights: cache.highlights, range: wholeRange)
            completionHandler?()
            return nil
        }
        
        // make sure that string is immutable
        //   -> `string` of NSTextStorage is actually a mutable object
        //      and it can cause crash when the mutable string is given to NSRegularExpression instance.
        //      (2016-11, macOS 10.12.1 SDK)
        let string = textStorage.string.immutable
        
        // avoid parsing twice for the same string
        guard (self.syntaxHighlightParseOperationQueue.operations.last as? SyntaxHighlightParseOperation)?.string != string else { return nil }
        
        return self.highlight(string: string, range: wholeRange, completionHandler: completionHandler)
    }
    
    
    /// update highlights around passed-in range
    func highlight(around editedRange: NSRange) -> Progress? {
        
        assert(Thread.isMainThread)
        
        guard UserDefaults.standard[.enableSyntaxHighlight] else { return nil }
        guard let textStorage = self.textStorage, !textStorage.string.isEmpty else { return nil }
        
        // make sure that string is immutable (see `highlightAll()` for details)
        let string = textStorage.string.immutable
        
        let wholeRange = string.nsRange
        let bufferLength = UserDefaults.standard[.coloringRangeBufferLength]
        
        // in case that wholeRange length is changed from editedRange
        guard var highlightRange = editedRange.intersection(wholeRange) else { return nil }
        
        // highlight whole if string is enough short
        if wholeRange.length <= bufferLength {
            highlightRange = wholeRange
            
        } else {
            // highlight whole visible area if edited point is visible
            for layoutManager in textStorage.layoutManagers {
                guard let visibleRange = layoutManager.firstTextView?.visibleRange else { continue }
                
                if editedRange.intersection(visibleRange) != nil {
                    highlightRange.formUnion(visibleRange)
                }
            }
            
            highlightRange = highlightRange.intersection(wholeRange)!
            highlightRange = (string as NSString).lineRange(for: highlightRange)
            
            // expand highlight area if the character just before/after the highlighting area is the same color
            if let layoutManager = textStorage.layoutManagers.first {
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
                
                highlightRange = NSRange(location: start, length: end - start)
            }
        }
        
        return self.highlight(string: string, range: highlightRange)
    }
    
    
    
    // MARK: Private Methods
    
    /// whether receiver has some syntax highlight defintion
    private var hasSyntaxHighlighting: Bool {
        
        return (!self.highlightDictionary.isEmpty || self.blockCommentDelimiters != nil || self.inlineCommentDelimiter != nil)
    }
    
    
    /// perform highlighting
    private func highlight(string: String, range highlightRange: NSRange, completionHandler: (() -> Void)? = nil) -> Progress? {  // @escaping
        
        guard highlightRange.length > 0 else { return nil }
        
        // just clear current highlight and return if no coloring needs
        guard self.hasSyntaxHighlighting else {
            self.apply(highlights: [:], range: highlightRange)
            completionHandler?()
            return nil
        }
        
        let operation = SyntaxHighlightParseOperation(definitions: self.highlightDictionary,
                                                      pairedQuoteTypes: self.pairedQuoteTypes,
                                                      inlineCommentDelimiter: self.inlineCommentDelimiter,
                                                      blockCommentDelimiters: self.blockCommentDelimiters)
        operation.string = string
        operation.parseRange = highlightRange
        
        operation.highlightBlock = { [weak self] (highlights) in
            // cache result if whole text was parsed
            if highlightRange.length == string.utf16.count {
                self?.highlightCache = (highlights: highlights, hash: string.md5)
            }
            
            DispatchQueue.main.async {
                // give up if the editor's string is changed from the analized string
                guard self?.textStorage?.string == string else { return }
                
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
        
        guard let storage = self.textStorage else { return }
        
        assert(Thread.isMainThread)
        
        for layoutManager in storage.layoutManagers {
            layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: highlightRange)
            
            guard let theme = (layoutManager.firstTextView as? Themable)?.theme else { continue }
            
            for type in SyntaxType.all {
                guard let ranges = highlights[type], !ranges.isEmpty else { continue }
                
                let color = theme.syntaxColor(type: type) ?? theme.textColor
                
                for range in ranges {
                    layoutManager.addTemporaryAttribute(.foregroundColor, value: color, forCharacterRange: range)
                }
            }
        }
    }
    
}
