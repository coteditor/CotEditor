//
//  SearchField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import RegexHighlighting

struct SearchField: NSViewRepresentable {
    
    typealias NSViewType = NSSearchField
    
    @Binding private var text: String
    private var placeholder: String?
    
    private var onSubmit: (String) -> Void = { _ in }
    private var onTextChange: (String) -> Void = { _ in }
    private var autosaveName: String?
    private var isRegex = false
    
    
    init(text: Binding<String>, placeholder: String? = nil) {
        
        self._text = text
        self.placeholder = placeholder
    }
    
    
    func makeNSView(context: Context) -> NSSearchField {
        
        let searchField = RegexSearchField()
        searchField.usesSingleLineMode = false
        searchField.sendsSearchStringImmediately = false
        searchField.sendsWholeSearchString = true
        searchField.target = context.coordinator
        searchField.action = #selector(Coordinator.submit)
        searchField.delegate = context.coordinator
        searchField.placeholderString = self.placeholder
        searchField.recentsAutosaveName = self.autosaveName
        if self.autosaveName != nil {
            searchField.searchMenuTemplate = NSSearchField.searchMenuTemplate()
        }

        return searchField
    }
    
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        
        if nsView.stringValue != self.text {
            nsView.stringValue = self.text
        }
        (nsView as! RegexSearchField).isRegexHighlighted = self.isRegex
        context.coordinator.onSubmit = self.onSubmit
        context.coordinator.onTextChange = self.onTextChange
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(text: $text, onSubmit: self.onSubmit, onTextChange: self.onTextChange)
    }
    
    
    /// Sets an action to perform when the user submits a value to this view.
    ///
    /// - Parameter action: The action to perform on submission of a value.
    func onSubmit(_ action: @escaping (String) -> Void) -> Self {
        
        var view = self
        view.onSubmit = action
        return view
    }
    
    
    /// Sets an action to perform when the user edits the text in this view.
    ///
    /// The action is performed only for user-initiated edits, not for programmatic text changes.
    ///
    /// - Parameter action: The action to perform on the edit of the text.
    func onTextChange(_ action: @escaping (String) -> Void) -> Self {
        
        var view = self
        view.onTextChange = action
        return view
    }
    
    
    /// The name under which the search field automatically archives the list of recent search strings.
    ///
    /// - Parameter autosaveName: The unique name for saving recent search strings.
    func autosaveName(_ autosaveName: String?) -> Self {
        
        var view = self
        view.autosaveName = autosaveName
        return view
    }
    
    
    /// Adds a condition that controls whether syntax highlighting is enabled.
    ///
    /// - Parameter isRegex: A Boolean value that determines whether syntax highlighting is enabled.
    func isRegex(_ isRegex: Bool) -> Self {
        
        var view = self
        view.isRegex = isRegex
        
        return view
    }
    
    
    @MainActor final class Coordinator: NSObject, NSSearchFieldDelegate {
        
        var onSubmit: (String) -> Void
        var onTextChange: (String) -> Void
        
        @Binding private var text: String
        
        
        init(text: Binding<String>, onSubmit: @escaping (String) -> Void, onTextChange: @escaping (String) -> Void) {
            
            self._text = text
            self.onSubmit = onSubmit
            self.onTextChange = onTextChange
        }
        
        
        func controlTextDidChange(_ obj: Notification) {
            
            guard
                let textField = obj.object as? NSTextField,
                self.text != textField.stringValue
            else { return }
            
            self.text = textField.stringValue
            self.onTextChange(textField.stringValue)
        }
        
        
        /// Submits the current search string.
        @objc func submit(_ sender: NSSearchField) {
            
            if self.text != sender.stringValue {
                self.text = sender.stringValue
            }
            
            self.onSubmit(sender.stringValue)
        }
    }
}


private final class RegexSearchField: NSSearchField {
    
    var isRegexHighlighted = true {
        
        didSet {
            if isRegexHighlighted != oldValue {
                self.regexFormatter.parsesRegularExpression = isRegexHighlighted
                self.invalidateFieldEditor()
                self.needsDisplay = true
            }
        }
    }
    
    
    // MARK: Private Properties
    
    private let regexFormatter = RegexFormatter(theme: .default)
    
    
    // MARK: Text Field Methods
    
    override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        
        self.formatter = self.regexFormatter
    }
    
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        self.formatter = self.regexFormatter
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        // workaround to disable the Liquid Glass style on macOS 27 (2026-06, macOS 27)
        
        super.draw(dirtyRect)
    }
    
    
    /// Invoked when the receiver was focused to edit the content.
    override func becomeFirstResponder() -> Bool {
        
        guard super.becomeFirstResponder() else { return false }
        
        self.invalidateFieldEditor()
        
        return true
    }
    
    
    /// Invoked when the text in the field editor was just changed.
    override func textDidChange(_ notification: Notification) {
        
        super.textDidChange(notification)
        
        guard
            let editor = notification.object as? NSTextView,
            let layoutManager = editor.textLayoutManager
        else { return assertionFailure() }
        
        layoutManager.updateRegularExpressionHighlight()
    }
    
    
    // MARK: Private Methods
    
    /// Updates the syntax highlight in the field editor.
    private func invalidateFieldEditor() {
        
        guard
            let editor = self.currentEditor() as? NSTextView,
            let layoutManager = editor.textLayoutManager
        else { return }
        
        layoutManager.invalidateRegularExpressionHighlight(mode: self.regexFormatter.mode, theme: self.regexFormatter.theme, enabled: self.isRegexHighlighted)
    }
}


private extension NSSearchField {
    
    /// Generates a generic search menu template.
    static func searchMenuTemplate() -> sending NSMenu {
        
        let menu = NSMenu(title: String(localized: "SearchField.recentMenu.label", defaultValue: "Recent Searches"))
        menu.addItem(withTitle: String(localized: "SearchField.recentMenu.label", defaultValue: "Recent Searches"), action: nil, keyEquivalent: "")
            .tag = NSSearchField.recentsTitleMenuItemTag
        menu.addItem(withTitle: "", action: nil, keyEquivalent: "")
            .tag = NSSearchField.recentsMenuItemTag
        menu.addItem(.separator())
        menu.addItem(withTitle: String(localized: "SearchField.recentMenu.clear.label", defaultValue: "Clear Recent Searches"), action: nil, keyEquivalent: "")
            .tag = NSSearchField.clearRecentsMenuItemTag
        menu.addItem(withTitle: String(localized: "SearchField.recentMenu.noItem.label", defaultValue: "No Recent Searches"), action: nil, keyEquivalent: "")
            .tag = NSSearchField.noRecentsMenuItemTag
        
        return menu
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var text = ""
    
    SearchField(text: $text)
        .autosaveName("SearchField Preview")
        .frame(width: 160)
        .scenePadding()
}
