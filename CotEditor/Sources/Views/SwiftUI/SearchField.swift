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

struct SearchField: NSViewRepresentable {
    
    typealias NSViewType = NSSearchField
    
    @Binding private var text: String
    private var placeholder: String?
    
    private var onSubmit: (String) -> Void = { _ in }
    private var autosaveName: String?
    
    
    init(text: Binding<String>, placeholder: String? = nil) {
        
        self._text = text
        self.placeholder = placeholder
    }
    
    
    func makeNSView(context: Context) -> NSSearchField {
        
        let searchField = NSSearchField()
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
        context.coordinator.onSubmit = self.onSubmit
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(text: $text, action: self.onSubmit)
    }
    
    
    /// Sets an action to perform when the user submits a value to this view.
    ///
    /// - Parameter action: The action to perform on submission of a value.
    func onSubmit(_ action: @escaping (String) -> Void) -> Self {
        
        var view = self
        view.onSubmit = action
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
    
    
    @MainActor final class Coordinator: NSObject, NSSearchFieldDelegate {
        
        var onSubmit: (String) -> Void
        
        @Binding private var text: String
        
        
        init(text: Binding<String>, action: @escaping (String) -> Void) {
            
            self._text = text
            self.onSubmit = action
        }
        
        
        func controlTextDidChange(_ obj: Notification) {
            
            guard
                let textField = obj.object as? NSTextField,
                self.text != textField.stringValue
            else { return }
            
            self.text = textField.stringValue
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
        .padding()
}
