/*
 
 EditorTextViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-18.
 
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

final class EditorTextViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Public Properties
    @IBOutlet private(set) var textView: EditorTextView?
    
    weak var syntaxStyle: SyntaxStyle? {
        didSet {
            guard let textView = self.textView else { return }
            
            textView.inlineCommentDelimiter = syntaxStyle?.inlineCommentDelimiter
            textView.blockCommentDelimiters = syntaxStyle?.blockCommentDelimiters
            textView.firstSyntaxCompletionCharacterSet = syntaxStyle?.firstCompletionCharacterSet
        }
    }
    
    var showsLineNumber = false {
        didSet {
            self.scrollView?.rulersVisible = self.showsLineNumber
        }
    }
    
    
    
    // MARK: Private Properties
    
    private static let CurrentLineUpdateInterval = 0.01
    private var currentLineUpdateTimer: Timer?
    private var lastCursorLocation = 0
    
    private enum MenuItemTag: Int {
        case script = 800
    }

    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        self.currentLineUpdateTimer?.invalidate()
        
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKeys.highlightCurrentLine.rawValue)
        NotificationCenter.default.removeObserver(self)
        
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
        NotificationCenter.default.addObserver(self, selector: #selector(setupCurrentLineUpdateTimer), name: .NSViewFrameDidChange, object: self.textView)
    }
    
    
    
    // MARK: KVO
    
    /// apply change of user setting
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == DefaultKeys.highlightCurrentLine.rawValue {
            if (change?[NSKeyValueChangeKey.newKey] as? Bool) ?? false {
                self.setupCurrentLineUpdateTimer()
                
            } else {
                guard let textView = self.textView else { return }
                
                let rect = textView.lineHighlightRect
                textView.lineHighlightRect = NSRect.zero
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
        //       - Document > readFromURL:ofType:error:
        //   - Key Typing, Script, Paste, Drop or Replace via Find Panel:
        //       - EditorTextViewController > textView:shouldChangeTextInRange:replacementString:
        
        guard let replacementString = replacementString else {  // = only attributes changed
            return true
        }
        if replacementString.isEmpty ||  // = text deleted
            textView.undoManager?.isUndoing ?? false ||  // = undo
            replacementString == "\n" {
            return true
        }
        
        // replace all line endings with LF
        if let lineEnding = replacementString.detectedLineEnding, lineEnding != .LF {
            let newString = replacementString.replacingLineEndings(with: .LF)
            
            textView.replace(with: newString,
                             range: affectedCharRange,
                             selectedRange: NSRange(location: affectedCharRange.location + newString.utf16.count, length: 0),
                             actionName: nil)  // Action name will be set automatically.
            
            return false
        }
        
        return true
    }
    
    
    /// build completion list
    func textView(_ textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>?) -> [String] {
        
        // do nothing if completion is not suggested from the typed characters
        guard let string = textView.string, charRange.length > 0 else { return [] }
        
        let candidateWords = NSMutableOrderedSet()  // [String]
        let particalWord = (string as NSString).substring(with: charRange)
        
        // extract words in document and set to candidateWords
        if Defaults[.completesDocumentWords] {
            if charRange.length == 1 && !CharacterSet.alphanumerics.contains(particalWord.unicodeScalars.first!) {
                // do nothing if the particle word is an symbol
                
            } else {
                let pattern = "(?:^|\\b|(?<=\\W))" + NSRegularExpression.escapedPattern(for: particalWord) + "\\w+?(?:$|\\b)"
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    regex.enumerateMatches(in: string, range: string.nsRange, using: { (result: NSTextCheckingResult?, flags, stop) in
                        guard let result = result else { return }
                        candidateWords.add((string as NSString).substring(with: result.range))
                    })
                }
            }
        }
        
        // copy words defined in syntax style
        if let syntaxWords = self.syntaxStyle?.completionWords, Defaults[.completesSyntaxWords] {
            for word in syntaxWords {
                if word.range(of: particalWord, options: [.caseInsensitive, .anchored]) != nil {
                    candidateWords.add(word)
                }
            }
        }
        
        // copy the standard words from default completion words
        if Defaults[.completesStandartWords] {
            candidateWords.addObjects(from: words)
        }
        
        // provide nothing if there is only a candidate which is same as input word
        if  let word = candidateWords.firstObject as? String, candidateWords.count == 1 && word.caseInsensitiveCompare(particalWord) == .orderedSame {
            return []
        }
        
        return candidateWords.array as! [String]
    }
    
    
    /// add script menu to context menu
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        
        // append Script menu
        if let scriptMenu = ScriptManager.shared.contexualMenu {
            if Defaults[.inlineContextualScriptMenu] {
                menu.addItem(NSMenuItem.separator())
                menu.items.last?.tag = MenuItemTag.script.rawValue
                
                for item in scriptMenu.items {
                    let addItem = item.copy() as! NSMenuItem
                    addItem.tag = MenuItemTag.script.rawValue
                    menu.addItem(addItem)
                }
                menu.addItem(NSMenuItem.separator())
                
            } else {
                let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
                item.image = #imageLiteral(resourceName: "ScriptTemplate")
                item.tag = MenuItemTag.script.rawValue
                item.submenu = scriptMenu
                menu.addItem(item)
            }
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
            textView.complete(after: 0.05)
        }
    }
    
    
    /// the selection of main textView was changed.
    func textViewDidChangeSelection(_ notification: Notification) {
        
        guard let textView = notification.object as? NSTextView else { return }
        
        // highlight the current line
        // -> For the selection change, call `updateCurrentLineRect` directly rather than setting currentLineUpdateTimer
        //    in order to provide a quick feedback of change to users.
        self.updateCurrentLineRect()
        
        // highlight matching brace
        self.highlightMatchingBrace(in: textView)
    }
    
    
    /// font is changed
    func textViewDidChangeTypingAttributes(_ notification: Notification) {
        
        self.setupCurrentLineUpdateTimer()
    }
    
    
    
    // MARK: Action Messages
    
    /// show Go To sheet
    @IBAction func gotoLocation(_ sender: AnyObject?) {
        
        let viewController = GoToLineViewController(textView: self.textView!)
        
        self.presentViewControllerAsSheet(viewController!)
    }
    
    
    
    // MARK: Private Methods
    
    /// cast view to NSScrollView
    private var scrollView: NSScrollView? {
        
        return self.view as? NSScrollView
    }
    
    
    /// find the matching open brace and highlight it
    private func highlightMatchingBrace(in textView: NSTextView) {
        
        guard Defaults[.highlightBraces] else { return }
        
        // The following part is based on Smultron's SMLTextView.m by Peter Borg. (2006-09-09)
        // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
        // Copyright (c) 2004-2006 Peter Borg
        
        guard let string = textView.string, !string.isEmpty else { return }
        
        let location = textView.selectedRange.location
        let difference = location - self.lastCursorLocation
        self.lastCursorLocation = location
        
        // The brace will be highlighted only when the cursor moves forward, just like on Xcode. (2006-09-10)
        // If the difference is more than one, they've moved the cursor with the mouse or it has been moved by resetSelectedRange below and we shouldn't check for matching braces then.
        guard difference == 1 else { return }
        
        var index = string.utf16.startIndex.advanced(by: location).samePosition(in: string)!
        
        // check the caracter just before the cursor
        index = string.index(before: index)
        
        let braces: (begin: Character, end: Character)
        switch string.characters[index] {
        case ")":
            braces = (begin: "(", end: ")")
        case "}":
            braces = (begin: "{", end: "}")
        case "]":
            braces = (begin: "[", end: "]")
        case ">":
            guard Defaults[.highlightLtGt] else { return }
            braces = (begin: "<", end: ">")
        default: return
        }
        
        var skippedBraceCount = 0
        
        for character in string.characters[string.startIndex..<index].reversed() {
            index = string.index(before: index)
            switch character {
            case braces.begin:
                if skippedBraceCount == 0 {
                    let location = index.samePosition(in: string.utf16).distance(to: string.utf16.startIndex)
                    textView.showFindIndicator(for: NSRange(location: location, length: 1))
                    return
                }
                skippedBraceCount -= 1
                
            case braces.end:
                skippedBraceCount += 1
                
            default: break
            }
        }
        
        // do not beep when the typed brace is `>`
        //  -> Since `>` (and `<`) can often be used alone unlike other braces.
        if braces.end != ">" {
            NSBeep()
        }
    }
    
    
    /// set update timer for current line highlight calculation
    func setupCurrentLineUpdateTimer() {
        
        guard Defaults[.highlightCurrentLine] else { return }
        
        let interval = type(of: self).CurrentLineUpdateInterval
        
        if let timer = self.currentLineUpdateTimer, timer.isValid {
            timer.fireDate = Date(timeIntervalSinceNow: interval)
        } else {
            self.currentLineUpdateTimer = Timer.scheduledTimer(timeInterval: interval,
                                                               target: self,
                                                               selector: #selector(updateCurrentLineRect),
                                                               userInfo: nil,
                                                               repeats: false)
        }
    }
    
    
    /// update current line highlight area
    func updateCurrentLineRect() {
        
        // [note] Don't invoke this method too often but with a currentLineUpdateTimer because this is a heavy task.
        
        self.currentLineUpdateTimer?.invalidate()
        
        guard Defaults[.highlightCurrentLine] else { return }
        
        guard
            let textView = self.textView,
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer,
            let string = textView.string else { return }
        
        // calcurate current line rect
        let lineRange = (string as NSString).lineRange(for: textView.selectedRange)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
        var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        rect.origin.x = textContainer.lineFragmentPadding
        rect.size.width = textContainer.containerSize.width - 2 * rect.minX
        rect = rect.offsetBy(dx: textView.textContainerOrigin.x, dy: textView.textContainerOrigin.y)
        
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
