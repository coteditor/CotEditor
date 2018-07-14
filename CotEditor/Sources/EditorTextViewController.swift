//
//  EditorTextViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-18.
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

final class EditorTextViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Public Properties
    
    var syntaxStyle: SyntaxStyle? {
        
        didSet {
            guard let textView = self.textView, let syntaxStyle = syntaxStyle else { return }
            
            textView.inlineCommentDelimiter = syntaxStyle.inlineCommentDelimiter
            textView.blockCommentDelimiters = syntaxStyle.blockCommentDelimiters
            textView.syntaxCompletionWords = syntaxStyle.completionWords
        }
    }
    
    
    var showsLineNumber: Bool {
        
        get {
            return self.scrollView?.rulersVisible ?? false
        }
        
        set {
            self.scrollView?.rulersVisible = newValue
            
            // -> Workaround issue on Mojave where line number view covers text view.
            if #available(macOS 10.14, *) {
                self.scrollView?.layoutSubtreeIfNeeded()
            }
        }
    }
    
    
    var textView: EditorTextView? {
        
        return self.scrollView?.documentView as? EditorTextView
    }
    
    
    // MARK: Private Properties
    
    private lazy var currentLineUpdateTask = Debouncer(delay: .milliseconds(10)) { [weak self] in self?.updateCurrentLineRect() }

    
    
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
        
        // standardize line endings to LF
        // -> Line endings replacemement on file read is processed in `Document.read(from:ofType:)`
        if let replacementString = replacementString,  // = only attributes changed
            !replacementString.isEmpty,  // = text deleted
            !(textView.undoManager?.isUndoing ?? false),  // = undo
            let lineEnding = replacementString.detectedLineEnding, lineEnding != .lf
        {
            return !textView.replace(with: replacementString.replacingLineEndings(with: .lf),
                                     range: affectedCharRange,
                                     selectedRange: nil)
        }
        
        return true
    }
    
    
    /// add script menu to context menu
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        
        // append Script menu
        if let scriptMenu = ScriptManager.shared.contexualMenu {
            let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            item.image = #imageLiteral(resourceName: "ScriptTemplate")
            item.toolTip = "Scripts".localized
            item.submenu = scriptMenu
            menu.addItem(item)
        }
        
        return menu
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
        self.currentLineUpdateTask.perform()
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
