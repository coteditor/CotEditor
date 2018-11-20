//
//  FindPanelFieldViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-26.
//
//  ---------------------------------------------------------------------------
//
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

final class FindPanelFieldViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    @objc private dynamic let textFinder = TextFinder.shared
    
    private weak var currentResultMessageTarget: NSLayoutManager?  // grab layoutManager instead of NSTextView to use weak reference
    
    @IBOutlet private var findTextView: RegexFindPanelTextView?  // NSTextView cannot be weak
    @IBOutlet private var replacementTextView: RegexFindPanelTextView?  // NSTextView cannot be weak
    @IBOutlet private weak var findHistoryMenu: NSMenu?
    @IBOutlet private weak var replaceHistoryMenu: NSMenu?
    @IBOutlet private weak var findResultField: NSTextField?
    @IBOutlet private weak var replacementResultField: NSTextField?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKeys.findHistory.rawValue)
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKeys.replaceHistory.rawValue)
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // sync history menus with user default
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKeys.findHistory.rawValue, options: .initial, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKeys.replaceHistory.rawValue, options: .initial, context: nil)
        
        // sync text view states with user default
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKeys.findUsesRegularExpression.rawValue, options: .initial, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKeys.findRegexUnescapesReplacementString.rawValue, options: .initial, context: nil)
    }
    
    
    /// make find field initial first responder
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // make find text view the initial first responder to focus it on showWindow(_:)
        self.view.window?.initialFirstResponder = self.findTextView
    }
    
    
    /// observed user defaults are changed
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        switch keyPath {
        case DefaultKeys.findHistory.rawValue?:
            self.updateFindHistoryMenu()
            
        case DefaultKeys.replaceHistory.rawValue?:
            self.updateReplaceHistoryMenu()
            
        case DefaultKeys.findUsesRegularExpression.rawValue?:
            self.findTextView?.isRegularExpressionMode = UserDefaults.standard[.findUsesRegularExpression]
            self.replacementTextView?.isRegularExpressionMode = UserDefaults.standard[.findUsesRegularExpression]
            
        case DefaultKeys.findRegexUnescapesReplacementString.rawValue?:
            self.replacementTextView?.mode = .replacement(unescapes: UserDefaults.standard[.findRegexUnescapesReplacementString])
            
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    
    
    // MARK: Text View Delegate
    
    /// find string did change
    func textDidChange(_ notification: Notification) {
        
        guard let textView = notification.object as? NSTextView else { return assertionFailure() }
        
        switch textView {
        case self.findTextView!:
            self.clearNumberOfReplaced()
            self.clearNumberOfFound()
        case self.replacementTextView!:
            self.clearNumberOfReplaced()
        default:
            break
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// set selected history string to find field
    @IBAction func selectFindHistory(_ sender: NSMenuItem?) {
        
        guard
            let string = sender?.representedObject as? String,
            let textView = self.findTextView,
            textView.shouldChangeText(in: textView.string.nsRange, replacementString: string)
            else { return }
        
        textView.string = string
        textView.didChangeText()
    }
    
    
    /// set selected history string to replacement field
    @IBAction func selectReplaceHistory(_ sender: NSMenuItem?) {
        
        guard
            let string = sender?.representedObject as? String,
            let textView = self.replacementTextView,
            textView.shouldChangeText(in: textView.string.nsRange, replacementString: string)
            else { return }
        
        textView.string = string
        textView.didChangeText()
    }
    
    
    /// restore find history via UI
    @IBAction func clearFindHistory(_ sender: Any?) {
        
        self.view.window?.makeKeyAndOrderFront(self)
        
        UserDefaults.standard.removeObject(forKey: DefaultKeys.findHistory.rawValue)
        self.updateFindHistoryMenu()
    }
    
    
    /// restore replace history via UI
    @IBAction func clearReplaceHistory(_ sender: Any?) {
        
        self.view.window?.makeKeyAndOrderFront(self)
        
        UserDefaults.standard.removeObject(forKey: DefaultKeys.replaceHistory.rawValue)
        self.updateReplaceHistoryMenu()
    }
    
    
    // MARK: Public Methods
    
    /// receive number of found
    func updateResultCount(_ numberOfFound: Int, target: NSTextView) {
        
        self.clearNumberOfFound()
        
        let message: String? = {
            switch numberOfFound {
            case -1:
                return nil
            case 0:
                return "Not Found".localized
            default:
                return String(format: "%@ found".localized, String.localizedStringWithFormat("%li", numberOfFound))
            }
        }()
        self.applyResult(message: message, textField: self.findResultField!, textView: self.findTextView!)
        
        // dismiss result either client text or find string did change
        self.currentResultMessageTarget = target.layoutManager
        NotificationCenter.default.addObserver(self, selector: #selector(clearNumberOfFound), name: NSTextStorage.didProcessEditingNotification, object: target.textStorage)
        NotificationCenter.default.addObserver(self, selector: #selector(clearNumberOfFound), name: NSWindow.willCloseNotification, object: target.window)
    }
    
    
    /// receive number of replaced
    func updateReplacedCount(_ numberOfReplaced: Int, target: NSTextView) {
        
        self.clearNumberOfReplaced()
        
        let message: String? = {
            switch numberOfReplaced {
            case -1:
                return nil
            case 0:
                return "Not Replaced".localized
            default:
                return String(format: "%@ replaced".localized, String.localizedStringWithFormat("%li", numberOfReplaced))
            }
        }()
        self.applyResult(message: message, textField: self.replacementResultField!, textView: self.replacementTextView!)
    }

    
    
    // MARK: Private Methods
    
    /// update find history menu
    private func updateFindHistoryMenu() {
        
        self.buildHistoryMenu(self.findHistoryMenu!, defaultsKey: .findHistory, action: #selector(selectFindHistory))
    }
    
    
    /// update replace history menu
    private func updateReplaceHistoryMenu() {
        
        self.buildHistoryMenu(self.replaceHistoryMenu!, defaultsKey: .replaceHistory, action: #selector(selectReplaceHistory))
    }
    
    
    /// apply history to UI
    private func buildHistoryMenu(_ menu: NSMenu, defaultsKey key: DefaultKey<[String]>, action: Selector) {
        
        // clear current history items
        menu.items
            .filter { $0.action == action || $0.isSeparatorItem }
            .forEach { menu.removeItem($0) }
        
        guard let history = UserDefaults.standard[key], !history.isEmpty else { return }
        
        menu.insertItem(NSMenuItem.separator(), at: 2)  // the first item is invisible dummy
        
        for string in history {
            let title = (string.count <= 64) ? string : (String(string.prefix(64)) + "…")
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.representedObject = string
            item.toolTip = string
            item.target = self
            menu.insertItem(item, at: 2)
        }
    }
    
    
    /// number of found in find string field becomes no more valid
    @objc private func clearNumberOfFound(_ notification: Notification? = nil) {
        
        self.applyResult(message: nil, textField: self.findResultField!, textView: self.findTextView!)
        
        // -> specify the object to remove osberver to avoid removing the windowWillClose notification (via delegate) from find panel itself.
        if let target = self.currentResultMessageTarget?.firstTextView {
            NotificationCenter.default.removeObserver(self, name: NSTextStorage.didProcessEditingNotification, object: target.textStorage)
            NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: target.window)
        }
    }
    
    
    /// number of replaced in replacement string field becomes no more valid
    @objc private func clearNumberOfReplaced(_ notification: Notification? = nil) {
        
        self.applyResult(message: nil, textField: self.replacementResultField!, textView: self.replacementTextView!)
    }
    
    
    /// apply message to UI
    private func applyResult(message: String?, textField: NSTextField, textView: NSTextView) {
        
        textField.isHidden = (message == nil)
        textField.stringValue = message ?? ""
        textField.sizeToFit()
        
        // add extra scroll margin to the right side of the textView, so that entire input can be read
        textView.enclosingScrollView?.contentView.contentInsets.right = textField.frame.width
    }
    
}
