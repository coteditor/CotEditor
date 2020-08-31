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
import Cocoa

final class FindPanelFieldViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    @objc private dynamic let textFinder = TextFinder.shared
    
    private var scrollerStyleObserver: AnyCancellable?
    private var defaultsObservers: Set<AnyCancellable> = []
    
    private var resultClosingTrigerObserver: AnyCancellable?
    
    @IBOutlet private weak var findTextView: RegexFindPanelTextView?
    @IBOutlet private weak var replacementTextView: RegexFindPanelTextView?
    @IBOutlet private weak var findHistoryMenu: NSMenu?
    @IBOutlet private weak var replaceHistoryMenu: NSMenu?
    @IBOutlet private weak var findResultField: NSTextField?
    @IBOutlet private weak var replacementResultField: NSTextField?
    @IBOutlet private weak var findClearButtonConstraint: NSLayoutConstraint?
    @IBOutlet private weak var replacementClearButtonConstraint: NSLayoutConstraint?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // adjust clear button position according to the visiblity of scroller area
        let scroller = self.findTextView?.enclosingScrollView?.verticalScroller
        self.scrollerStyleObserver = scroller?.publisher(for: \.scrollerStyle, options: .initial)
            .sink { [weak self, weak scroller] (scrollerStyle) in
                var inset: CGFloat = 5
                if scrollerStyle == .legacy, let scroller = scroller {
                    inset += NSScroller.scrollerWidth(for: scroller.controlSize, scrollerStyle: scroller.scrollerStyle)
                }
                
                self?.findClearButtonConstraint?.constant = -inset
                self?.replacementClearButtonConstraint?.constant = -inset
            }
        
        self.defaultsObservers = [
            // sync history menus with user default
            UserDefaults.standard.publisher(for: .findHistory, initial: true)
                .sink { [unowned self] _ in self.updateFindHistoryMenu() },
            UserDefaults.standard.publisher(for: .replaceHistory, initial: true)
                .sink { [unowned self] _ in self.updateReplaceHistoryMenu() },
            
            // sync text view states with user default
            UserDefaults.standard.publisher(for: .findUsesRegularExpression, initial: true)
                .sink { [unowned self] (value) in
                    self.findTextView?.isRegularExpressionMode = value
                    self.replacementTextView?.isRegularExpressionMode = value
                },
            UserDefaults.standard.publisher(for: .findRegexUnescapesReplacementString, initial: true)
                .sink { [unowned self] (value) in
                    self.replacementTextView?.parseMode = .replacement(unescapes: value)
                }
        ]
    }
    
    
    /// make find field initial first responder
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // make find text view the initial first responder to focus it on showWindow(_:)
        self.view.window?.initialFirstResponder = self.findTextView
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
        
        let message: String = {
            switch numberOfFound {
                case ..<0:
                    return "Not Found".localized
                default:
                    return String(format: "%@ found".localized, String.localizedStringWithFormat("%li", numberOfFound))
            }
        }()
        self.applyResult(message: message, textField: self.findResultField!, textView: self.findTextView!)
        
        self.resultClosingTrigerObserver = Publishers.Merge(
            NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: target.textStorage),
            NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: target.window))
            .sink { [weak self] _ in self?.clearNumberOfFound() }
    }
    
    
    /// receive number of replaced
    func updateReplacedCount(_ numberOfReplaced: Int, target: NSTextView) {
        
        self.clearNumberOfReplaced()
        
        let message: String = {
            switch numberOfReplaced {
                case ..<0:
                    return "Not Replaced".localized
                default:
                    return String(format: "%@ replaced".localized, String.localizedStringWithFormat("%li", numberOfReplaced))
            }
        }()
        self.applyResult(message: message, textField: self.replacementResultField!, textView: self.replacementTextView!)
        
        // feedback for VoiceOver
        if let window = NSApp.mainWindow {
            NSAccessibility.post(element: window, notification: .announcementRequested, userInfo: [.announcement: message])
        }
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
        
        assert(Thread.isMainThread)
        
        // clear current history items
        menu.items
            .filter { $0.action == action || $0.isSeparatorItem }
            .forEach { menu.removeItem($0) }
        
        let history = UserDefaults.standard[key]
        
        guard !history.isEmpty else { return }
        
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
    private func clearNumberOfFound() {
        
        self.applyResult(message: nil, textField: self.findResultField!, textView: self.findTextView!)
        
        self.resultClosingTrigerObserver = nil
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
