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
//  © 2014-2023 1024jp
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

final class FindPanelFieldViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    @objc private dynamic let settings = TextFinderSettings.shared
    
    private var scrollerStyleObserver: AnyCancellable?
    private var defaultsObservers: Set<AnyCancellable> = []
    private var resultObservers: Set<AnyCancellable> = []
    
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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // observe find result notifications from TextFinder and its expiration
        NotificationCenter.default.publisher(for: TextFinder.didFindNotification)
            .map { $0.object as? TextFinder }
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.update(result: $0?.findResult) }
            .store(in: &self.resultObservers)
        NotificationCenter.default.publisher(for: NSWindow.didResignMainNotification)
            .sink { [weak self] _ in self?.update(result: nil) }
            .store(in: &self.resultObservers)
        
        self.findTextView?.action = #selector(performFind)
        self.findTextView?.target = self
        
        // adjust clear button position according to the visiblity of scroller area
        let scroller = self.findTextView?.enclosingScrollView?.verticalScroller
        self.scrollerStyleObserver = scroller?.publisher(for: \.scrollerStyle, options: .initial)
            .sink { [weak self, weak scroller] (scrollerStyle) in
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
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        // make find text view the initial first responder to focus it on showWindow(_:)
        self.view.window?.initialFirstResponder = self.findTextView
    }
    
    
    
    // MARK: Text View Delegate
    
    /// find/replacement string did change
    func textDidChange(_ notification: Notification) {
        
        guard let textView = notification.object as? RegexFindPanelTextView else { return assertionFailure() }
        
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
    
    /// perform find action (designed to be used by the find string field)
    @IBAction func performFind(_ sender: Any?) {
        
        // find backwards if the Shift key pressed
        let action = NSEvent.modifierFlags.contains(.shift)
            ? #selector((any TextFinderClient).matchPrevious)
            : #selector((any TextFinderClient).matchNext)
        
        NSApp.sendAction(action, to: nil, from: self)
    }
    
    
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
    }
    
    
    /// restore replace history via UI
    @IBAction func clearReplaceHistory(_ sender: Any?) {
        
        self.view.window?.makeKeyAndOrderFront(self)
        
        UserDefaults.standard.removeObject(forKey: DefaultKeys.replaceHistory.rawValue)
    }
    
    
    /// show the regular expression refecence view as popover
    @IBAction func showRegularExpressionReference(_ sender: NSButton) {
        
        if let viewController = self.presentedViewControllers?.first(where: { $0.view is NSHostingView<RegularExpressionReferenceView> }) {
            return self.dismiss(viewController)
        }
        
        let viewController = DetachablePopoverViewController()
        viewController.view = NSHostingView(rootView: RegularExpressionReferenceView())
        
        self.present(viewController, asPopoverRelativeTo: sender.bounds, of: sender, preferredEdge: .maxY, behavior: .transient)
    }
    
    
    /// show the advanced find options view as popover
    @IBAction func showFindSettings(_ sender: NSButton) {
        
        if let viewController = self.presentedViewControllers?.first(where: { $0 is NSHostingController<FindSettingsView> }) {
            return self.dismiss(viewController)
        }
        
        let viewController = NSHostingController(rootView: FindSettingsView())
        viewController.ensureFrameSize()
        
        self.present(viewController, asPopoverRelativeTo: sender.bounds, of: sender, preferredEdge: .maxX, behavior: .transient)
    }
    
    
    
    // MARK: Private Methods
    
    /// Update result count in the input fields.
    ///
    /// - Parameter result: The find/replace result or `nil` to clear.
    @MainActor private func update(result: TextFindResult?) {
        
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
    
    
    /// Update find history menu.
    @MainActor private func updateFindHistoryMenu() {
        
        self.buildHistoryMenu(self.findHistoryMenu!, defaultsKey: .findHistory, action: #selector(selectFindHistory))
    }
    
    
    /// Update replace history menu.
    @MainActor private func updateReplaceHistoryMenu() {
        
        self.buildHistoryMenu(self.replaceHistoryMenu!, defaultsKey: .replaceHistory, action: #selector(selectReplaceHistory))
    }
    
    
    /// apply history to UI
    @MainActor private func buildHistoryMenu(_ menu: NSMenu, defaultsKey key: DefaultKey<[String]>, action: Selector) {
        
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
    
    
    /// Update the find result message on the input field.
    ///
    /// - Parameter message: The message to display in the input field, or `nil` to clear.
    @MainActor private func updateFoundMessage(_ message: String?) {
        
        self.applyResult(message: message, textField: self.findResultField!, textView: self.findTextView!)
    }
    
    
    /// Update the replacement result message on the input field.
    ///
    /// - Parameter message: The message to display in the input field, or `nil` to clear.
    @MainActor private func updateReplacedMessage(_ message: String?) {
        
        self.applyResult(message: message, textField: self.replacementResultField!, textView: self.replacementTextView!)
    }
    
    
    /// Apply result message on the input field.
    ///
    /// - Parameters:
    ///   - message: The localized message to display.
    ///   - textField: The text field displaying the message.
    ///   - textView: The input text view where shows the message.
    @MainActor private func applyResult(message: String?, textField: NSTextField, textView: NSTextView) {
        
        textField.isHidden = (message == nil)
        textField.stringValue = message ?? ""
        textField.sizeToFit()
        
        // add extra scroll margin to the right side of the textView, so that the entire input can be read
        textView.enclosingScrollView?.contentView.contentInsets.right = textField.frame.width
    }
}
