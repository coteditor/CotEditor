//
//  FindPanelFieldView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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

import AppKit
import Combine
import SwiftUI
import Defaults

struct FindPanelMainView: View {
    
    var body: some View {
        
        VStack {
            FindPanelFieldView()
            FindPanelOptionView()
        }
        .scenePadding([.top, .horizontal])
        .padding(.bottom, 8)
    }
}


private struct FindPanelFieldView: NSViewControllerRepresentable {
    
    func makeNSViewController(context: Context) -> some NSViewController {
        
        NSStoryboard(name: "FindPanelFieldView", bundle: nil).instantiateInitialController()!
    }
    
    
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {
        
    }
}


final class FindPanelFieldViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    @objc private dynamic let settings = TextFinderSettings.shared
    
    private var scrollerStyleObserver: AnyCancellable?
    private var defaultsObservers: Set<AnyCancellable> = []
    private var resultObservers: Set<AnyCancellable> = []
    
    @IBOutlet private weak var findTextView: FindPanelTextView?
    @IBOutlet private weak var findHistoryMenu: NSMenu?
    @IBOutlet private weak var findResultField: NSTextField?
    @IBOutlet private weak var findClearButtonConstraint: NSLayoutConstraint?
    
    @IBOutlet private weak var replacementTextView: FindPanelTextView?
    @IBOutlet private weak var replaceHistoryMenu: NSMenu?
    @IBOutlet private weak var replacementResultField: NSTextField?
    @IBOutlet private weak var replacementClearButtonConstraint: NSLayoutConstraint?
    
    
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // observe find result notifications from TextFinder and its expiration
        self.resultObservers = [
            NotificationCenter.default.publisher(for: TextFinder.didFindNotification)
                .map { $0.object as! TextFinder }
                .receive(on: RunLoop.main)
                .sink { [weak self] in self?.update(result: $0.findResult) },
            NotificationCenter.default.publisher(for: NSWindow.didResignMainNotification)
                .sink { [weak self] _ in self?.update(result: nil) },
        ]
        
        self.findTextView?.action = #selector(performFind)
        self.findTextView?.target = self
        
        // adjust clear button position according to the visibility of scroller area
        let scroller = self.findTextView?.enclosingScrollView?.verticalScroller
        self.scrollerStyleObserver = scroller?.publisher(for: \.scrollerStyle, options: .initial)
            .sink { [weak self, weak scroller] scrollerStyle in
                var inset = 5.0
                if scrollerStyle == .legacy, let scroller {
                    inset += scroller.thickness
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
                .sink { [unowned self] value in
                    self.findTextView?.isRegularExpressionMode = value
                    self.replacementTextView?.isRegularExpressionMode = value
                },
            UserDefaults.standard.publisher(for: .findRegexUnescapesReplacementString, initial: true)
                .sink { [unowned self] value in
                    self.replacementTextView?.parseMode = .replacement(unescapes: value)
                },
        ]
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // make find text view the initial first responder to focus it on showWindow(_:)
        self.view.window?.initialFirstResponder = self.findTextView
    }
    
    
    // MARK: Text View Delegate
    
    /// Invoked when a find/replacement string did change.
    func textDidChange(_ notification: Notification) {
        
        guard let textView = notification.object as? FindPanelTextView else { return assertionFailure() }
        
        switch textView {
            case self.findTextView!:
                self.updateFoundMessage(nil)
                self.updateReplacedMessage(nil)
                
                // perform incremental search
                guard
                    UserDefaults.standard[.findSearchesIncrementally],
                    !UserDefaults.standard[.findInSelection],
                    !textView.hasMarkedText(),
                    !textView.string.isEmpty,
                    textView.isValid
                else { return }
                
                NSApp.sendAction(#selector((any TextFinderClient).incrementalSearch), to: nil, from: self)
                
            case self.replacementTextView!:
                self.updateReplacedMessage(nil)
                
            default:
                break
        }
    }
    
    
    // MARK: Action Messages
    
    /// Performs the find action (designed to be used by the find string field).
    @IBAction func performFind(_ sender: Any?) {
        
        // find backwards if the Shift key pressed
        let action = NSEvent.modifierFlags.contains(.shift)
            ? #selector((any TextFinderClient).matchPrevious)
            : #selector((any TextFinderClient).matchNext)
        
        NSApp.sendAction(action, to: nil, from: self)
    }
    
    
    /// Sets the selected history string to the find field.
    @IBAction func selectFindHistory(_ sender: NSMenuItem?) {
        
        guard
            let string = sender?.representedObject as? String,
            let textView = self.findTextView,
            textView.shouldChangeText(in: textView.string.range, replacementString: string)
        else { return }
        
        textView.string = string
        textView.didChangeText()
    }
    
    
    /// Sets the selected history string to the replacement field.
    @IBAction func selectReplaceHistory(_ sender: NSMenuItem?) {
        
        guard
            let string = sender?.representedObject as? String,
            let textView = self.replacementTextView,
            textView.shouldChangeText(in: textView.string.range, replacementString: string)
        else { return }
        
        textView.string = string
        textView.didChangeText()
    }
    
    
    /// Restores the find history via UI.
    @IBAction func clearFindHistory(_ sender: Any?) {
        
        self.view.window?.makeKeyAndOrderFront(self)
        
        UserDefaults.standard.restore(key: .findHistory)
    }
    
    
    /// Restores the replace history via UI.
    @IBAction func clearReplaceHistory(_ sender: Any?) {
        
        self.view.window?.makeKeyAndOrderFront(self)
        
        UserDefaults.standard.restore(key: .replaceHistory)
    }
    
    
    // MARK: Private Methods
    
    /// Updates the result count in the input fields.
    ///
    /// - Parameter result: The find/replace result or `nil` to clear.
    private func update(result: TextFindResult?) {
        
        switch result {
            case .found:
                self.updateFoundMessage(result?.message)
                self.updateReplacedMessage(nil)
            case .replaced:
                self.updateFoundMessage(nil)
                self.updateReplacedMessage(result?.message)
            case nil:
                self.updateFoundMessage(nil)
                self.updateReplacedMessage(nil)
        }
    }
    
    
    /// Updates the find history menu.
    private func updateFindHistoryMenu() {
        
        self.buildHistoryMenu(self.findHistoryMenu!, defaultsKey: .findHistory, action: #selector(selectFindHistory))
    }
    
    
    /// Updates the replace history menu.
    private func updateReplaceHistoryMenu() {
        
        self.buildHistoryMenu(self.replaceHistoryMenu!, defaultsKey: .replaceHistory, action: #selector(selectReplaceHistory))
    }
    
    
    /// Applies the given type of history to the menu.
    ///
    /// - Parameters:
    ///   - menu: The menu to update the content.
    ///   - key: The default key for the history.
    ///   - action: The action selector for menu items.
    private func buildHistoryMenu(_ menu: NSMenu, defaultsKey key: DefaultKey<[String]>, action: Selector) {
        
        assert(Thread.isMainThread)
        
        // clear current history items
        menu.items
            .filter { $0.action == action }
            .forEach { menu.removeItem($0) }
        
        for string in UserDefaults.standard[key] {
            let title = (string.count <= 64) ? string : (String(string.prefix(64)) + "…")
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.representedObject = string
            item.toolTip = string
            item.target = self
            menu.insertItem(item, at: 2)
        }
    }
    
    
    /// Updates the find result message on the input field.
    ///
    /// - Parameter message: The message to display in the input field, or `nil` to clear.
    private func updateFoundMessage(_ message: String?) {
        
        self.applyResult(message: message, textField: self.findResultField!, textView: self.findTextView!)
    }
    
    
    /// Updates the replacement result message on the input field.
    ///
    /// - Parameter message: The message to display in the input field, or `nil` to clear.
    private func updateReplacedMessage(_ message: String?) {
        
        self.applyResult(message: message, textField: self.replacementResultField!, textView: self.replacementTextView!)
    }
    
    
    /// Applies the given result message to the input field.
    ///
    /// - Parameters:
    ///   - message: The localized message to display.
    ///   - textField: The text field displaying the message.
    ///   - textView: The input text view where shows the message.
    private func applyResult(message: String?, textField: NSTextField, textView: NSTextView) {
        
        textField.isHidden = (message == nil)
        textField.stringValue = message ?? ""
        textField.sizeToFit()
        
        // add extra scroll margin to the right side of the textView, so that the entire input can be read
        let leadingKeyPath = (textView.userInterfaceLayoutDirection == .rightToLeft) ? \NSEdgeInsets.left : \.right
        textView.enclosingScrollView?.contentView.contentInsets[keyPath: leadingKeyPath] = textField.frame.width
    }
}


private extension NSScroller {
    
    final var thickness: CGFloat {
        
        Self.scrollerWidth(for: self.controlSize, scrollerStyle: self.scrollerStyle)
    }
}
