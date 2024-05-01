//
//  FindPanelFormView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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

import SwiftUI
import AppKit
import Defaults
import RegexHighlighting
import TextFind

struct FindPanelFormView: View {
    
    // -> Not used in code but need to reset focus
    @Environment(\.appearsActive) private var appearsActive
    
    @AppStorage(.findUsesRegularExpression) private var usesRegularExpression: Bool
    @AppStorage(.findInSelection) private var inSelection: Bool
    @AppStorage(.findRegexUnescapesReplacementString) private var unescapesReplacementString: Bool
    @AppStorage(.findSearchesIncrementally) private var searchesIncrementally: Bool
    
    @State private var settings: TextFinderSettings = .shared
    @State private var result: FindResult?
    @State private var isFindStringValid = true
    @State private var isPressingShift = false
    
    @State private var scrollerThickness: Double = 0
    @State private var findMessageWidth: Double = 0
    @State private var replaceMessageWidth: Double = 0
    
    
    var body: some View {
        
        VStack {
            FindTextField(String(localized: "Find", table: "TextFind", comment: "placeholder"),
                          text: $settings.findString,
                          mode: .search,
                          isRegularExpression: self.usesRegularExpression,
                          trailingInset: self.findMessageWidth)
            {
                let action = self.isPressingShift
                    ? #selector((any TextFinderClient).matchPrevious)
                    : #selector((any TextFinderClient).matchNext)
                NSApp.sendAction(action, to: nil, from: nil)
            }
            .onModifierKeysChanged(mask: .shift) { _, new in self.isPressingShift = new.contains(.shift) }
            .overlay(alignment: .top) {
                HStack(alignment: .firstTextBaseline) {
                    HistoryMenu(String(localized: "Recent Searches", table: "TextFind", comment: "menu item header"),
                                defaultKey: .findHistory, systemImage: "magnifyingglass",
                                clearLabel: String(localized: "Clear Recent Searches", table: "TextFind", comment: "menu item label"),
                                value: $settings.findString)
                    Spacer()
                    FindPanelFieldAccessoryView(result: (self.result?.action == .find) ? self.result?.message : nil,
                                                text: $settings.findString)
                        .onGeometryChange(for: CGFloat.self, of: \.size.width) { self.findMessageWidth = $0 }
                }
                .padding(.trailing, self.scrollerThickness)
            }
            .help(String(localized: "Type the text to search for.", table: "TextFind", comment: "tooltip"))
            .frame(minHeight: 44)
            
            FindTextField(String(localized: "Replace with", table: "TextFind", comment: "placeholder"),
                          text: $settings.replacementString,
                          mode: .replacement(unescapes: self.unescapesReplacementString),
                          isRegularExpression: self.usesRegularExpression,
                          trailingInset: self.replaceMessageWidth)
            .overlay(alignment: .top) {
                HStack(alignment: .firstTextBaseline) {
                    HistoryMenu(String(localized: "Recent Replacements", table: "TextFind", comment: "menu item header"),
                                defaultKey: .replaceHistory, systemImage: "pencil",
                                clearLabel: String(localized: "Clear Recent Replacements", table: "TextFind", comment: "menu item label"),
                                value: $settings.replacementString)
                    Spacer()
                    FindPanelFieldAccessoryView(result: (self.result?.action == .replace) ? self.result?.message : nil,
                                                text: $settings.replacementString)
                        .onGeometryChange(for: CGFloat.self, of: \.size.width) { self.replaceMessageWidth = $0 }
                }
                .padding(.trailing, self.scrollerThickness)
            }
            .help(String(localized: "Type the text to replace the found text.", table: "TextFind", comment: "tooltip"))
            .frame(minHeight: 44)
            
            FindPanelOptionView()
        }
        .onAppear {
            self.invalidateScrollerThickness()
        }
        .onChange(of: self.settings.findString) { _, newValue in
            self.result = nil
            
            // perform incremental search
            if self.searchesIncrementally,
               !self.inSelection,
               !newValue.isEmpty,
               !self.usesRegularExpression || (try? NSRegularExpression(pattern: newValue)) != nil
            {
                NSApp.sendAction(#selector((any TextFinderClient).incrementalSearch), to: nil, from: nil)
            }
        }
        .onChange(of: self.settings.replacementString) {
            self.result = nil
        }
        .task {
            for await notification in NotificationCenter.default.notifications(named: TextFinder.DidFindMessage.name) {
                self.result = notification.userInfo?["result"] as? FindResult
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: NSWindow.didResignMainNotification) {
                self.result = nil
            }
        }
        .task {
            for await _ in NotificationCenter.default.notifications(named: NSScroller.preferredScrollerStyleDidChangeNotification) {
                self.invalidateScrollerThickness()
            }
        }
        .scenePadding([.top, .horizontal])
        .padding(.bottom, 8)
    }
    
    
    /// Updates the scroller thickness preserving for the Clear button padding.
    private func invalidateScrollerThickness() {
        
        self.scrollerThickness = NSScroller.preferredScrollerStyle == .legacy ? NSScroller.scrollerWidth(for: .small, scrollerStyle: NSScroller.preferredScrollerStyle) : 0
    }
}


private struct FindPanelFieldAccessoryView: View {
    
    var result: String?
    @Binding var text: String
    
    
    var body: some View {
        
        if !self.text.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let result {
                    Text(result)
                        .monospacedDigit()
                        .padding(.horizontal, 2)
                        .foregroundStyle(.tertiary)
                        .background(.background)
                        .clipShape(.rect(cornerRadius: 2))
                }
                
                Button(String(localized: "Clear", table: "TextFind", comment: "button label"), systemImage: "xmark") {
                    self.text = ""
                }
                .symbolVariant(.circle.fill)
                .buttonStyle(.borderless)
                .labelStyle(.iconOnly)
            }
            .controlSize(.small)
            .padding(5)
        }
    }
}


private struct HistoryMenu: View {
    
    var defaultKey: DefaultKey<[String]>
    
    var label: String
    var systemImage: String
    var clearLabel: String
    
    @Binding var value: String
    
    
    init(_ label: String, defaultKey: DefaultKey<[String]>, systemImage: String, clearLabel: String, value: Binding<String>) {
        
        self.defaultKey = defaultKey
        self.label = label
        self.systemImage = systemImage
        self.clearLabel = clearLabel
        self._value = value
    }
    
    
    var body: some View {
        
        Menu {
            let histories = UserDefaults.standard[self.defaultKey]
            
            if !histories.isEmpty {
                Section(self.label) {
                    ForEach(histories, id: \.self) { string in
                        let title = (string.count <= 64) ? string : (String(string.prefix(64)) + "…")
                        
                        Button(title) {
                            self.value = string
                        }.help(string)
                    }
                }
            }
            Button(self.clearLabel, systemImage: "trash") {
                UserDefaults.standard.removeObject(forKey: self.defaultKey.rawValue)
            }.disabled(histories.isEmpty)
        } label: {
            Label(self.label, systemImage: self.systemImage)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.borderless)
        .frame(minWidth: 34)
        .padding(.vertical, 5)
        .padding(.horizontal, 3)
    }
}


private struct FindTextField: NSViewRepresentable {
    
    typealias NSViewType = NSScrollView
    typealias TextView = RegexTextView
    
    
    var prompt: String
    @Binding var text: String
    @MainActor var action: (() -> Void)?
    
    var mode: RegexParseMode = .search
    var isRegularExpression: Bool = false
    var trailingInset: Double = 0
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    
    init(_ prompt: String, text: Binding<String>, mode: RegexParseMode, isRegularExpression: Bool, trailingInset: Double, action: (@MainActor () -> Void)? = nil) {
        
        self.prompt = prompt
        self._text = text
        self.mode = mode
        self.isRegularExpression = isRegularExpression
        self.trailingInset = trailingInset
        self.action = action
    }
    
    
    func makeNSView(context: Context) -> NSScrollView {
        
        let textView = FindPanelTextView()
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.setValue(self.prompt, forKey: "placeholderString")  // private property in NSTextView
        textView.action = self.action
        
        let scrollView = SynchronizedScrollView()
        scrollView.contentView = FindPanelTextClipView()
        scrollView.documentView = textView
        scrollView.allowsMagnification = true
        scrollView.borderType = .lineBorder
        scrollView.focusRingType = .exterior
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.verticalScroller?.controlSize = .small
        scrollView.horizontalScroller?.controlSize = .small
        scrollView.contentView.automaticallyAdjustsContentInsets = false
        
        return scrollView
    }
    
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        
        let textView = nsView.documentView as! TextView
        textView.string = self.text
        textView.parseMode = self.mode
        textView.isRegularExpressionMode = self.isRegularExpression
        
        // add extra scroll margin to the trailing side of the textView, so that the entire input can be read
        let leadingKeyPath = (self.layoutDirection == .rightToLeft) ? \NSEdgeInsets.left : \.right
        nsView.contentView.contentInsets[keyPath: leadingKeyPath] = self.trailingInset
        
        if case .search = self.mode {
            // make find text view the initial first responder to focus it on showWindow(_:)
            textView.window?.initialFirstResponder = textView
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(text: $text)
    }
    
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        
        @Binding private var text: String
        
        
        init(text: Binding<String>) {
            
            self._text = text
        }
        
        
        func textDidChange(_ notification: Notification) {
            
            guard
                let textView = notification.object as? TextView,
                !textView.hasMarkedText()
            else { return }
            
            self.text = textView.string
        }
    }
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 400, height: 200)) {
    FindPanelFormView()
}


// MARK: -

final class FindPanelFieldViewController: NSViewController, NSTextViewDelegate {
    
    // MARK: Private Properties
    
    private let settings = TextFinderSettings.shared
    
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
            NotificationCenter.default.publisher(for: TextFinder.DidFindMessage.name)
                .compactMap { $0.userInfo?["result"] as? FindResult }
                .sink { [weak self] in self?.updateMessages(for: $0) },
            NotificationCenter.default.publisher(for: NSWindow.didResignMainNotification)
                .sink { [weak self] _ in self?.clearMessages() },
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
                self.clearMessages()
                
                // perform incremental search
                guard
                    UserDefaults.standard[.findSearchesIncrementally],
                    !UserDefaults.standard[.findInSelection],
                    !textView.hasMarkedText(),
                    !textView.string.isEmpty
//                    textView.isValid
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
    
    /// Clears result messages.
    private func clearMessages() {
        
        self.updateFoundMessage(nil)
        self.updateReplacedMessage(nil)
    }
    
    
    /// Updates the result count in the input fields.
    /// 
    /// - Parameters:
    ///   - result: The find action result.
    private func updateMessages(for result: FindResult) {
        
        switch result.action {
            case .find:
                self.updateFoundMessage(result.message)
                self.updateReplacedMessage(nil)
            case .replace:
                self.updateFoundMessage(nil)
                self.updateReplacedMessage(result.message)
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
