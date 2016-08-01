/*
 
 SyntaxStyle.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2004-12-22.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

protocol SyntaxStyleDelegate: class {
    
    func syntaxStyle(_ syntaxStyle: SyntaxStyle, didParseOutline outlineItems: [OutlineItem]?)
}



final class SyntaxStyle: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    
    var textStorage: NSTextStorage?
    weak var delegate: SyntaxStyleDelegate?
    
    let styleName: String
    let isNone: Bool
    
    let inlineCommentDelimiter: String?
    let blockCommentDelimiters: BlockDelimiters?
    
    let completionWords: [String]?  // completion words list
    let firstCompletionCharacterSet: CharacterSet?  // set of the first characters of the completion words
    
    private(set) var outlineItems: [OutlineItem]? {
        didSet {
            guard let items = self.outlineItems else { return }
            
            // inform delegate about outline items update
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                
                self.delegate?.syntaxStyle(self, didParseOutline: items)
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private let outlineParseOperationQueue: OperationQueue
    private let syntaxHighlightParseOperationQueue: OperationQueue
    
    private let hasSyntaxHighlighting: Bool
    private let highlightDictionary: [SyntaxType: [HighlightDefinition]]?
    private let simpleWordsCharacterSets: [SyntaxType: CharacterSet]?
    private let pairedQuoteTypes: [String: SyntaxType]?
    private let outlineDefinitions: [OutlineDefinition]?
    
    private var cachedHighlights: [SyntaxType: [NSRange]]?  // extracted results cache of the last whole string highlighs
    private var highlightCacheHash: String?  // MD5 hash
    private weak var outlineMenuTimer: Timer?
    
    private static let AllAlphabets = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    required init(dictionary: [String: AnyObject]?, name: String) {
        
        self.styleName = name
        
        self.outlineParseOperationQueue = OperationQueue()
        self.outlineParseOperationQueue.name = "com.coteditor.CotEditor.outlineParseOperationQueue"
        self.syntaxHighlightParseOperationQueue = OperationQueue()
        self.syntaxHighlightParseOperationQueue.name = "com.coteditor.CotEditor.syntaxHighlightParseOperationQueue"
        
        guard let dictionary = dictionary else {
            self.isNone = true
            self.inlineCommentDelimiter = nil
            self.blockCommentDelimiters = nil
            self.completionWords = nil
            
            self.hasSyntaxHighlighting = false
            self.highlightDictionary = nil
            self.simpleWordsCharacterSets = nil
            self.pairedQuoteTypes = nil
            self.outlineDefinitions = nil
            self.firstCompletionCharacterSet = nil
            
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
                !beginDelimiter.isEmpty && !endDelimiter.isEmpty
            {
                blockCommentDelimiters = BlockDelimiters(begin: beginDelimiter, end: endDelimiter)
            }
        }
        self.inlineCommentDelimiter = inlineCommentDelimiter
        self.blockCommentDelimiters = blockCommentDelimiters
        
        // pick quote definitions up to parse quoted text separately with comments in `extractCommentsWithQuotes`
        // also check if highlighting definition exists
        var highlightDictionary = [SyntaxType: [HighlightDefinition]]()
        var quoteTypes = [String: SyntaxType]()
        for type in SyntaxType.all {
            if let definitionDictionaries = dictionary[type.rawValue] as? [[String: AnyObject]] {
                
                var definitions = [HighlightDefinition]()
                definitionLoop: for wordDict in definitionDictionaries {
                    guard let definition = HighlightDefinition(definition: wordDict) else { continue }
                    
                    // check quote
                    for quote in ["\"\"\"", "'''", "\"", "'", "`"] {
                        if definition.beginString == quote && definition.endString == quote && !quoteTypes.keys.contains(quote) {
                            // remove from the normal highlight definition list
                            quoteTypes[quote] = type
                            continue definitionLoop
                        }
                    }
                    
                    definitions.append(definition)
                }
                highlightDictionary[type] = definitions
            }
        }
        self.highlightDictionary = highlightDictionary
        self.pairedQuoteTypes = quoteTypes
        self.hasSyntaxHighlighting = (!highlightDictionary.isEmpty || blockCommentDelimiters != nil || inlineCommentDelimiter != nil)
        
        // create word-completion data set
        var completionWords = [String]()
        var firstCharSet = CharacterSet()
        if let completionDicts = dictionary[SyntaxKey.completions.rawValue] as? [[String: AnyObject]], !completionDicts.isEmpty {
            for dict in completionDicts {
                guard
                    let word = dict[SyntaxDefinitionKey.keyString.rawValue] as? String,
                    let firstChar = word.unicodeScalars.first else { continue }
                
                completionWords.append(word)
                firstCharSet.update(with: firstChar)
            }
        } else {
            for definitions in highlightDictionary.values {
                for definition in definitions {
                    let word = definition.beginString.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard
                        let firstChar = word.unicodeScalars.first,
                        !word.isEmpty && definition.endString == nil && !definition.isRegularExpression else { continue }
                    
                    completionWords.append(word)
                    firstCharSet.update(with: firstChar)
                }
            }
        }
        // keep results
        if !completionWords.isEmpty {
            self.completionWords = completionWords.sorted()
        } else {
            self.completionWords = nil
        }
        if !firstCharSet.isEmpty {
            self.firstCompletionCharacterSet = firstCharSet
        } else {
            self.firstCompletionCharacterSet = nil
        }
        
        // create characerSet dict for simple word highlights
        self.simpleWordsCharacterSets = {
            var characterSets = [SyntaxType: CharacterSet]()
            for (type, definitions) in highlightDictionary {
                var charSet = CharacterSet(charactersIn: SyntaxStyle.AllAlphabets)
                
                for definition in definitions {
                    let word = definition.beginString.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !word.isEmpty && definition.endString == nil && !definition.isRegularExpression else { continue }
                    
                    if definition.ignoreCase {
                        charSet.insert(charactersIn: word.uppercased())
                        charSet.insert(charactersIn: word.lowercased())
                    } else {
                        charSet.insert(charactersIn: word)
                    }
                    charSet.remove(charactersIn: "\n\t ")   // ignore line breaks, tabs and spaces
                    
                    characterSets[type] = charSet
                }
            }
            guard !characterSets.isEmpty else { return nil }
            
            return characterSets
        }()
        
        // parse outline definitions
        self.outlineDefinitions = {
            guard let definitionDictionaries = dictionary[SyntaxKey.outlineMenu.rawValue] as? [[String: AnyObject]] else { return nil }
            
            var outlineDefinitions = [OutlineDefinition]()
            for definitionDictionary in definitionDictionaries {
                if let definition = OutlineDefinition(definition: definitionDictionary) {
                    outlineDefinitions.append(definition)
                }
            }
            guard !outlineDefinitions.isEmpty else { return nil }
            
            return outlineDefinitions
        }()
    }
    
    
    convenience init() {
        
        self.init(dictionary: nil, name: BundledStyleName.none)
    }
    
    
    deinit {
        self.outlineParseOperationQueue.cancelAllOperations()
        self.syntaxHighlightParseOperationQueue.cancelAllOperations()
        
        self.outlineMenuTimer?.invalidate()
    }
    
    
    var description: String {
        
        return "<SyntaxStyle -\(self.styleName)>"
    }
    
    
    var debugDescription: String {
        
        return "<SyntaxStyle -\(self.styleName): \(unsafeAddress(of: self))>"
    }
    
    
    
    // MARK: Public Methods
    
    /// whether enable parsing syntax
    var canParse: Bool {
        
        let isHighlightEnabled = UserDefaults.standard.bool(forKey:  DefaultKey.enableSyntaxHighlight)
        
        return isHighlightEnabled && !self.isNone
    }
    
    
    /// cancel all syntax parse
    func cancelAllParses() {
        self.outlineParseOperationQueue.cancelAllOperations()
        self.syntaxHighlightParseOperationQueue.cancelAllOperations()
    }
    
}


func ==(lhs: SyntaxStyle, rhs: SyntaxStyle) -> Bool {
    
    guard lhs.styleName == rhs.styleName &&
        lhs.inlineCommentDelimiter == rhs.inlineCommentDelimiter &&
        lhs.blockCommentDelimiters == rhs.blockCommentDelimiters else { return false }
    
    if let lProp = lhs.pairedQuoteTypes, let rProp = rhs.pairedQuoteTypes, lProp != rProp {
        return false
    } else if !(lhs.pairedQuoteTypes == nil && rhs.pairedQuoteTypes == nil) {
        return false
    }
    
    if let lProp = lhs.outlineDefinitions, let rProp = rhs.outlineDefinitions, lProp != rProp {
        return false
    } else if !(lhs.outlineDefinitions == nil && rhs.outlineDefinitions == nil) {
        return false
    }
    
    // compare highlightDictionary
    if !(lhs.highlightDictionary == nil && rhs.highlightDictionary == nil) {
        return false
    } else if let lProp = lhs.highlightDictionary, let rProp = rhs.highlightDictionary {
        guard lProp.count == rProp.count else { return false }
        for (key, lhsub) in rProp {
            guard let rhsub = lProp[key], lhsub == rhsub else { return false }
        }
    }
    
    return true
}



// MARK:
// MARK: Outline

extension SyntaxStyle {
    
    /// parse outline with delay
    func invalidateOutline() {
        
        guard self.canParse else {
            if self.outlineItems == nil {
                self.outlineItems = []
            }
            return
        }
        
        self.setupOutlineMenuUpdateTimer()
    }
    
    
    
    // MARK: Private Methods
    
    /// parse outline
    @objc func parseOutline() {
        
        self.outlineMenuTimer?.invalidate()
        
        guard
            let definitions = self.outlineDefinitions,
            let string = self.textStorage?.string,
            !string.isEmpty else
        {
            self.outlineItems = []
            return
        }
        
        let operation = OutlineParseOperation(definitions: definitions)
        operation.string = NSString(string: string) as String  // make sure being immutable
        operation.parseRange = string.nsRange
        
        operation.completionBlock = { [weak self, weak operation] in
            guard let operation = operation, !operation.isCancelled else { return }
            
            self?.outlineItems = operation.results
        }
        
        self.outlineParseOperationQueue.addOperation(operation)
    }
    
    
    /// let parse outline after a delay
    private func setupOutlineMenuUpdateTimer() {
        
        let interval: TimeInterval = UserDefaults.standard.double(forKey:  DefaultKey.outlineMenuInterval)
        
        if let timer = self.outlineMenuTimer, timer.isValid {
            timer.fireDate = Date(timeIntervalSinceNow: interval)
        } else {
            self.outlineMenuTimer = Timer.scheduledTimer(timeInterval: interval,
                                                         target: self,
                                                         selector: #selector(parseOutline),
                                                         userInfo: nil,
                                                         repeats: false)
        }
    }
    
}



// MARK:
// MARK: Syntax Highlight

extension SyntaxStyle {
    
    /// update whole document highlights
    func highlightAll(completionHandler: (() -> Void)? = nil) {
        
        guard UserDefaults.standard.bool(forKey: DefaultKey.enableSyntaxHighlight) else { return }
        guard let textStorage = self.textStorage, !textStorage.string.isEmpty else { return }
        
        let wholeRange = textStorage.string.nsRange
        
        // use cache if the content of the whole document is the same as the last
        if let hash = self.highlightCacheHash, let highlights = self.cachedHighlights, hash == textStorage.string.md5 {
            self.apply(highlights: highlights, range: wholeRange)
            completionHandler?()
            return
        }
        
        // make sure that string is immutable
        // [Caution] DO NOT use [string copy] here instead of `stringWithString:`.
        //           It still returns a mutable object, NSBigMutableString,
        //           and it can cause crash when the mutable string is given to RegularExpression instance.
        //           (2015-08, with OS X 10.10 SDK)
        let string = NSString(string: textStorage.string) as String
        
        self.highlight(string: string, range: wholeRange, completionHandler: completionHandler)
    }
    
    
    /// update highlights around passed-in range
    func highlight(around editedRange: NSRange) {
        
        guard UserDefaults.standard.bool(forKey: DefaultKey.enableSyntaxHighlight) else { return }
        guard let textStorage = self.textStorage, !textStorage.string.isEmpty else { return }
        
        // make sure that string is immutable (see `highlightAll()` for details)
        let string = NSString(string: textStorage.string) as String
        
        let wholeRange = string.nsRange
        let bufferLength = UserDefaults.standard.integer(forKey: DefaultKey.coloringRangeBufferLength)
        var highlightRange = editedRange
        
        // highlight whole if string is enough short
        if wholeRange.length <= bufferLength {
            highlightRange = wholeRange
            
        } else {
            // highlight whole visible area if edited point is visible
            for layoutManager in textStorage.layoutManagers {
                guard let visibleRange = layoutManager.firstTextView?.visibleRange else { continue }
                
                if NSIntersectionRange(editedRange, visibleRange).length > 0 {
                    highlightRange = NSUnionRange(highlightRange, visibleRange)
                }
            }
            highlightRange = (string as NSString).lineRange(for: highlightRange)
            
            // expand highlight area if the character just before/after the highlighting area is the same color
            if let layoutManager = textStorage.layoutManagers.first {
                var start = highlightRange.location
                var end = highlightRange.max - 1
                var effectiveRange = NotFoundRange
                
                if start <= bufferLength {
                    start = 0
                } else {
                    if layoutManager.temporaryAttribute(NSForegroundColorAttributeName,
                                                        atCharacterIndex: start,
                                                        longestEffectiveRange: &effectiveRange,
                                                        in: wholeRange) != nil {
                        start = effectiveRange.location
                    }
                }
                if layoutManager.temporaryAttribute(NSForegroundColorAttributeName,
                                                    atCharacterIndex: end,
                                                    longestEffectiveRange: &effectiveRange,
                                                    in: wholeRange) != nil {
                    end = effectiveRange.max - 1
                }
                
                highlightRange = NSRange(location: start, length: end - start)
            }
        }
        
        self.highlight(string: string, range: highlightRange, completionHandler: nil)
    }
    
    
    // MARK: Private Methods
    
    /// perform highlighting
    private func highlight(string: String, range highlightRange: NSRange, completionHandler: (() -> Void)?) {
        
        guard highlightRange.length > 0 else { return }
        
        // just clear current highlight and return if no coloring needs
        guard self.hasSyntaxHighlighting else {
            self.apply(highlights: [:], range: highlightRange)
            completionHandler?()
            return
        }
        
        let operation = SyntaxHighlightParseOperation(definitions: self.highlightDictionary ?? [:],
                                                      simpleWordsCharacterSets: self.simpleWordsCharacterSets,
                                                      pairedQuoteTypes: self.pairedQuoteTypes,
                                                      inlineCommentDelimiter: self.inlineCommentDelimiter,
                                                      blockCommentDelimiters: self.blockCommentDelimiters)
        operation.string = string
        operation.parseRange = highlightRange
        
        // show highlighting indicator for large string
        var indicator: ProgressViewController?
        if let storage = self.textStorage, self.shouldShowIndicator(for: highlightRange.length) {
            // wait for window becomes visible and sheet-attachable
            DispatchQueue.global(qos: .background).async {
                while !(storage.layoutManagers.first?.firstTextView?.window?.isVisible ?? false) {
                    RunLoop.current.limitDate(forMode: .defaultRunLoopMode)
                }
                
                // attach the indicator as a sheet
                DispatchQueue.main.sync {
                    // do nothing if highlighting is already finished
                    guard !operation.isFinished else { return }
                    
                    guard let contentViewController = storage.layoutManagers.first?.firstTextView?.window?.windowController?.contentViewController else { return }
                    indicator = ProgressViewController(progress: operation.progress, message: NSLocalizedString("Coloring text…", comment: ""))
                    contentViewController.presentViewControllerAsSheet(indicator!)
                }
            }
        }
        
        operation.completionBlock = { [weak self, weak operation] in
            guard let `self` = self, let operation = operation else { return }
            let highlights = operation.results
            
            DispatchQueue.main.async {
                if !operation.isCancelled {
                    // cache result if whole text was parsed
                    if highlightRange.length == string.utf16.count {
                        self.cachedHighlights = highlights
                        self.highlightCacheHash = string.md5
                    }
                    
                    // apply color (or give up if the editor's string is changed from the analized string)
                    if self.textStorage?.string == string {
                        // update indicator message
                        operation.progress.localizedDescription = NSLocalizedString("Applying colors to text", comment: "")
                        self.apply(highlights: highlights, range: highlightRange)
                    }
                }
                
                // clean up indicator sheet
                indicator?.dismiss(self)
                
                // do the rest things
                completionHandler?()
            }
        }
        
        self.syntaxHighlightParseOperationQueue.addOperation(operation)
    }
    
    
    /// whether need to display highlighting indicator
    private func shouldShowIndicator(for highlightLength: Int) -> Bool {
        
        let threshold = UserDefaults.standard.integer(forKey: DefaultKey.showColoringIndicatorTextLength)
        
        // do not show indicator if threshold is 0
        return threshold > 0 && highlightLength > threshold
    }
    
    
    /// apply highlights to the document
    private func apply(highlights: [SyntaxType: [NSRange]], range highlightRange: NSRange) {
        
        guard let storage = self.textStorage else { return }
        
        for layoutManager in storage.layoutManagers {
            layoutManager.removeTemporaryAttribute(NSForegroundColorAttributeName, forCharacterRange: highlightRange)
            
            guard let theme = (layoutManager.firstTextView as? Themable)?.theme else { continue }
            
            for (type, ranges) in highlights {
                let color = theme.syntaxColor(type: type) ?? theme.textColor
                
                for range in ranges {
                    layoutManager.addTemporaryAttribute(NSForegroundColorAttributeName, value: color, forCharacterRange: range)
                }
            }
        }
    }
    
}
