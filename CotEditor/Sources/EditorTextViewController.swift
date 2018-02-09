/*
 
 EditorTextViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-18.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2018 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class EditorTextViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Public Properties
    
    weak var syntaxStyle: SyntaxStyle? {
        
        didSet {
            guard let textView = self.textView else { return }
            
            textView.inlineCommentDelimiter = syntaxStyle?.inlineCommentDelimiter
            textView.blockCommentDelimiters = syntaxStyle?.blockCommentDelimiters
            
            textView.firstSyntaxCompletionCharacterSet = {
                guard let words = syntaxStyle?.completionWords, !words.isEmpty else { return nil }
                
                let firstLetters = words.flatMap { $0.unicodeScalars.first }
                
                return CharacterSet(firstLetters)
            }()
        }
    }
    
    
    var showsLineNumber: Bool {
        
        get {
            return self.scrollView?.rulersVisible ?? false
        }
        set {
            self.scrollView?.rulersVisible = newValue
        }
    }
    
    
    var textView: EditorTextView? {
        
        return self.scrollView?.documentView as? EditorTextView
    }
    
    
    
    // MARK: Private Properties
    
    private lazy var currentLineUpdateTask: Debouncer = Debouncer(delay: 0.01, tolerance: 0.5) { [weak self] in self?.updateCurrentLineRect() }
    
    private enum MenuItemTag: Int {
        case script = 800
    }

    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKeys.highlightCurrentLine.rawValue)
        
        // detach textStorage safely
        if let layoutManager = self.textView?.layoutManager {
            self.textView?.textStorage?.removeLayoutManager(layoutManager)
        }
    }
    
    
    
    // MARK: View Controller Methods
    
    /// initialize instance
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKeys.highlightCurrentLine.rawValue, options: .new, context: nil)
        
        // update current line highlight on changing frame size with a delay
        NotificationCenter.default.addObserver(self, selector: #selector(setupCurrentLineUpdateTimer), name: NSView.frameDidChangeNotification, object: self.textView)
    }
    
    
    
    // MARK: KVO
    
    /// apply change of user setting
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == DefaultKeys.highlightCurrentLine.rawValue {
            if (change?[NSKeyValueChangeKey.newKey] as? Bool) ?? false {
                self.setupCurrentLineUpdateTimer()
                
            } else {
                guard let textView = self.textView else { return }
                
                let rect = textView.lineHighlightRect
                textView.lineHighlightRect = .zero
                if let rect = rect {
                    textView.setNeedsDisplay(rect, avoidAdditionalLayout: true)
                }
            }
        }
    }
    
    
    
    // MARK: Text View Delegate
    
    /// text will be edited
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        
        // standardize line endings to LF (Key Typing, Script, Paste, Drop or Replace via Find Panel)
        // (Line endings replacemement by other text modifications are processed in the following methods.)
        //
        // # Methods Standardizing Line Endings on Text Editing
        //   - File Open:
        //       - Document > read(from:ofType:)
        //   - Key Typing, Script, Paste, Drop or Replace via Find Panel:
        //       - EditorTextViewController > textView(_:shouldChangeTextInRange:replacementString:)
        if let replacementString = replacementString,  // = only attributes changed
            !replacementString.isEmpty,  // = text deleted
            !(textView.undoManager?.isUndoing ?? false),  // = undo
            let lineEnding = replacementString.detectedLineEnding, lineEnding != .LF
        {
            return !textView.replace(with: replacementString.replacingLineEndings(with: .LF),
                                     range: affectedCharRange,
                                     selectedRange: nil)
        }
        
        return true
    }
    
    
    /// build completion list
    func textView(_ textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>?) -> [String] {
        
        // do nothing if completion is not suggested from the typed characters
        guard charRange.length > 0 else { return [] }
        
        let string = textView.string
        var candidateWords = OrderedSet<String>()
        let particalWord = (string as NSString).substring(with: charRange)
        
        // extract words in document and set to candidateWords
        if UserDefaults.standard[.completesDocumentWords] {
            let documentWords: [String] = {
                // do nothing if the particle word is a symbol
                guard charRange.length > 1 || CharacterSet.alphanumerics.contains(particalWord.unicodeScalars.first!) else { return [] }
                
                let pattern = "(?:^|\\b|(?<=\\W))" + NSRegularExpression.escapedPattern(for: particalWord) + "\\w+?(?:$|\\b)"
                let regex = try! NSRegularExpression(pattern: pattern)
                
                return regex.matches(in: string, range: string.nsRange).map { (string as NSString).substring(with: $0.range) }
            }()
            candidateWords.append(contentsOf: documentWords)
        }
        
        // copy words defined in syntax style
        if UserDefaults.standard[.completesSyntaxWords], let syntaxCandidateWords = self.syntaxStyle?.completionWords {
            let syntaxWords = syntaxCandidateWords.filter { $0.range(of: particalWord, options: [.caseInsensitive, .anchored]) != nil }
            candidateWords.append(contentsOf: syntaxWords)
        }
        
        // copy the standard words from default completion words
        if UserDefaults.standard[.completesStandartWords] {
            candidateWords.append(contentsOf: words)
        }
        
        // provide nothing if there is only a candidate which is same as input word
        if  let word = candidateWords.first,
            candidateWords.count == 1,
            word.caseInsensitiveCompare(particalWord) == .orderedSame
        {
            return []
        }
        
        return candidateWords.array
    }
    
    
    /// add script menu to context menu
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        
        // append Script menu
        if let scriptMenu = ScriptManager.shared.contexualMenu {
            let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            item.image = #imageLiteral(resourceName: "ScriptTemplate")
            item.toolTip = NSLocalizedString("Scripts", comment: "")
            item.tag = MenuItemTag.script.rawValue
            item.submenu = scriptMenu
            menu.addItem(item)
        }
        
        return menu
    }
    
    
    /// text was edited
    func textDidChange(_ notification: Notification) {
        
        guard let textView = notification.object as? EditorTextView else { return }
        
        // retry completion if needed
        //   -> Flag is set in EditorTextView > `insertCompletion:forPartialWordRange:movement:isFinal:`
        if textView.needsRecompletion {
            textView.needsRecompletion = false
            textView.completionTask.schedule(delay: 0.05)
        }
    }
    
    
    /// the selection of main textView was changed.
    func textViewDidChangeSelection(_ notification: Notification) {
        
        guard let textView = notification.object as? NSTextView else { return }
        
        // only on focused editor
        guard
            let layoutManager = textView.layoutManager,
            let window = textView.window,
            layoutManager.layoutManagerOwnsFirstResponder(in: window) else { return }
        
        // highlight the current line
        // -> For the selection change, call `updateCurrentLineRect` directly rather than setting currentLineUpdateTimer
        //    in order to provide a quick feedback of change to users.
        self.currentLineUpdateTask.run()
        
        // highlight matching brace
        self.highlightMatchingBrace(in: textView)
    }
    
    
    /// font is changed
    func textViewDidChangeTypingAttributes(_ notification: Notification) {
        
        self.setupCurrentLineUpdateTimer()
    }
    
    
    
    // MARK: Action Messages
    
    /// show Go To sheet
    @IBAction func gotoLocation(_ sender: Any?) {
        
        guard
            let textView = self.textView,
            let viewController = GoToLineViewController(textView: textView)
            else {
                NSSound.beep()
                return
        }
        
        self.presentViewControllerAsSheet(viewController)
    }
    
    
    
    // MARK: Private Methods
    
    /// cast view to NSScrollView
    private var scrollView: NSScrollView? {
        
        return self.view as? NSScrollView
    }
    
    
    /// find the matching brace and highlight it
    private func highlightMatchingBrace(in textView: NSTextView) {
        
        guard UserDefaults.standard[.highlightBraces] else { return }
        
        let string = textView.string
        let selectedRange = textView.selectedRange
        
        guard
            !string.isEmpty,
            selectedRange.length == 0,
            selectedRange.location != NSNotFound,
            selectedRange.location > 0,
            let cursorIndex = Range(selectedRange, in: string)?.lowerBound
            else { return }
        
        // check the character just before the cursor
        let lastIndex = string.index(before: cursorIndex)
        let lastCharacter = string[lastIndex]
        
        let bracePairs = BracePair.braces + (UserDefaults.standard[.highlightLtGt] ? [.ltgt] : [])
        
        guard
            let pair = bracePairs.first(where: { $0.begin == lastCharacter || $0.end == lastCharacter }),
            let index = (pair.begin == lastCharacter)
                ? string.indexOfEndBrace(for: pair, at: lastIndex)
                : string.indexOfBeginBrace(for: pair, at: lastIndex)
            else { return }
        
        let range = NSRange(index...index, in: string)
        
        textView.showFindIndicator(for: range)
    }
    
    
    /// set update timer for current line highlight calculation
    @objc private func setupCurrentLineUpdateTimer() {
        
        guard UserDefaults.standard[.highlightCurrentLine] else { return }
        
        self.currentLineUpdateTask.schedule()
    }
    
    
    /// update current line highlight area
    private func updateCurrentLineRect() {
        
        // [note] Don't invoke this method too often but with a currentLineUpdateTimer because this is a heavy task.
        
        guard
            UserDefaults.standard[.highlightCurrentLine],
            let textView = self.textView,
            let textContainer = textView.textContainer
             else { return }
        
        // calculate current line rect
        let lineRange = (textView.string as NSString).lineRange(for: textView.selectedRange, excludingLastLineEnding: true)
        
        textView.layoutManager?.ensureLayout(for: textContainer)  // avoid blinking on textView's dynamic bounds change
        
        guard var rect = textView.boundingRect(for: lineRange) else { return }
        
        rect.origin.x = textContainer.lineFragmentPadding
        rect.size.width = textContainer.size.width - 2 * textContainer.lineFragmentPadding
        
        guard textView.lineHighlightRect != rect else { return }
        
        // clear previous highlihght
        if let lineHighlightRect = textView.lineHighlightRect {
            textView.setNeedsDisplay(lineHighlightRect, avoidAdditionalLayout: true)
        }
        
        // draw highlight
        textView.lineHighlightRect = rect
        textView.setNeedsDisplay(rect, avoidAdditionalLayout: true)
    }
    
}
