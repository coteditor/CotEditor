//
//  FilterField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-02-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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

struct FilterField: NSViewRepresentable {
    
    typealias NSViewType = NSSearchField
    
    @Binding private var text: String
    
    private var autosaveName: String?
    
    
    init(text: Binding<String>) {
        
        self._text = text
    }
    
    
    func makeNSView(context: Context) -> NSSearchField {
        
        let searchField = InnerFilterField()
        searchField.delegate = context.coordinator
        searchField.placeholderString = String(localized: "Filter", table: "FilterField", comment: "placeholder for filter field")
        searchField.sendsSearchStringImmediately = true

        return searchField
    }
    
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        
        nsView.stringValue = self.text
        nsView.recentsAutosaveName = self.autosaveName
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(text: $text)
    }
    
    
    /// The name under which the search field automatically archives the list of recent search strings.
    ///
    /// - Parameter autosaveName: The unique name for saving recent search strings.
    func autosaveName(_ autosaveName: String?) -> some View {
        
        var view = self
        view.autosaveName = autosaveName
        return view
    }
    
    
    
    final class Coordinator: NSObject, NSSearchFieldDelegate {
        
        @Binding private var text: String
        
        
        init(text: Binding<String>) {
            
            self._text = text
        }
        
        
        func controlTextDidChange(_ obj: Notification) {
            
            guard let textField = obj.object as? NSTextField else { return }
            
            self.text = textField.stringValue
        }
    }
}


private final class InnerFilterField: NSSearchField {
    
    // MARK: Private Properties
    
    private let image: NSImage = .init(systemSymbolName: "line.3.horizontal.decrease.circle",
                                       accessibilityDescription: String(localized: "Filter", table: "FilterField"))!
        .tinted(with: .secondaryLabelColor)
    private let filteringImage: NSImage = .init(systemSymbolName: "line.3.horizontal.decrease.circle.fill",
                                                accessibilityDescription: String(localized: "Filter", table: "FilterField"))!
        .tinted(with: .controlAccentColor)
    
    
    
    // MARK: Lifecycle
    
    required init() {
        
        super.init(frame: .zero)
        
        self.validateImage()
        
        // workaround the cancel button color is .labelColor (2022-09, macOS 13)
        if let cancelButtonCell = (self.cell as? NSSearchFieldCell)?.cancelButtonCell {
            cancelButtonCell.image = cancelButtonCell.image?
                .tinted(with: .secondaryLabelColor)
        }
        
        self.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        
        let searchMenu = NSMenu(title: String(localized: "Recent Filters", table: "FilterField", comment: "menu label"))
        searchMenu.addItem(withTitle: String(localized: "Recent Filters", table: "FilterField"), action: nil, keyEquivalent: "")
            .tag = NSSearchField.recentsTitleMenuItemTag
        searchMenu.addItem(withTitle: "", action: nil, keyEquivalent: "")
            .tag = NSSearchField.recentsMenuItemTag
        searchMenu.addItem(.separator())
        searchMenu.addItem(withTitle: String(localized: "Clear Recent Filters", table: "FilterField", comment: "menu item label"),
                           action: nil, keyEquivalent: "")
            .tag = NSSearchField.clearRecentsMenuItemTag
        searchMenu.addItem(withTitle: String(localized: "No Recent Filter", table: "FilterField", comment: "menu item label"),
                           action: nil, keyEquivalent: "")
            .tag = NSSearchField.noRecentsMenuItemTag
        self.searchMenuTemplate = searchMenu
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Text Field Methods
    
    override func draw(_ dirtyRect: NSRect) {
        
        // workaround to update icon while typing
        super.draw(dirtyRect)
    }
    
    
    override func textDidChange(_ notification: Notification) {
        
        super.textDidChange(notification)
        
        self.validateImage()
    }
    
    
    override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
        
        // invoked when the search string was set by selecting recent history menu
        defer {
            self.validateImage()
        }
        
        return super.sendAction(action, to: target)
    }
    
    
    
    // MARK: Private Methods
    
    private func validateImage() {
        
        guard let buttonCell = (self.cell as? NSSearchFieldCell)?.searchButtonCell else { return assertionFailure() }
        
        buttonCell.image = self.stringValue.isEmpty ? self.image : self.filteringImage
    }
}



// MARK: - Preview

#Preview {
    @State var text = ""
    return FilterField(text: $text)
        .frame(width: 160)
        .padding()
}
