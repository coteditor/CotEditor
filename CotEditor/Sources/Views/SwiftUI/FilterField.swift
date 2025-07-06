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
//  © 2022-2025 1024jp
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
        searchField.usesSingleLineMode = true
        searchField.target = context.coordinator
        searchField.action = #selector(Coordinator.didChangeSearchString)
        searchField.recentsAutosaveName = self.autosaveName

        return searchField
    }
    
    
    func updateNSView(_ nsView: NSSearchField, context: Context) {
        
        nsView.stringValue = self.text
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
    
    
    final class Coordinator: NSObject {
        
        @Binding private var text: String
        
        
        init(text: Binding<String>) {
            
            self._text = text
        }
        
        
        @MainActor @objc func didChangeSearchString(_ sender: NSSearchField) {
            
            self.text = sender.stringValue
        }
    }
}


private final class InnerFilterField: NSSearchField {
    
    // MARK: Lifecycle
    
    required init() {
        
        super.init(frame: .zero)
        
        if let searchButtonCell {
            searchButtonCell.image = NSImage(systemSymbolName: "line.3.horizontal.decrease.circle", accessibilityDescription: nil)
            searchButtonCell.alternateImage = NSImage(systemSymbolName: "line.3.horizontal.decrease.circle.fill", accessibilityDescription: nil)?
                .tinted(with: .controlAccentColor)
            searchButtonCell.setAccessibilityLabel(String(localized: "FilterField.recentMenu.label", defaultValue: "Recent Filters", table: "Control"))
        }
        
        // workaround the button color is .labelColor (2022-09, macOS 13-15, fixed in macOS 26)
        if #unavailable(macOS 26) {
            self.searchButtonCell?.image = self.searchButtonCell?.image?
                .tinted(with: .secondaryLabelColor)
            self.cancelButtonCell?.image = self.cancelButtonCell?.image?
                .tinted(with: .secondaryLabelColor)
        }
        
        self.sendsSearchStringImmediately = true
        
        self.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        self.alignment = .natural
        self.placeholderString = String(localized: "FilterField.placeholder", defaultValue: "Filter", table: "Control")
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: Text Field Methods
    
    override var stringValue: String  {
        
        didSet {
            self.searchButtonCell?.isHighlighted = !stringValue.isEmpty
        }
    }
    
    
    override var recentsAutosaveName: NSSearchField.RecentsAutosaveName? {
        
        didSet {
            self.invalidateSearchMenu()
        }
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        // workaround to update icon while typing
        super.draw(dirtyRect)
    }
    
    
    // MARK: Private Methods
    
    /// Sets up the search menu.
    private func invalidateSearchMenu() {
        
        let searchMenu = NSMenu(title: String(localized: "FilterField.recentMenu.label", defaultValue: "Recent Filters", table: "Control"))
        searchMenu.addItem(withTitle: String(localized: "FilterField.recentMenu.label", defaultValue: "Recent Filters", table: "Control"), action: nil, keyEquivalent: "")
            .tag = NSSearchField.recentsTitleMenuItemTag
        searchMenu.addItem(withTitle: "", action: nil, keyEquivalent: "")
            .tag = NSSearchField.recentsMenuItemTag
        searchMenu.addItem(.separator())
        searchMenu.addItem(withTitle: String(localized: "FilterField.recentMenu.clear.label", defaultValue: "Clear Recent Filters", table: "Control"),
                           action: nil, keyEquivalent: "")
            .tag = NSSearchField.clearRecentsMenuItemTag
        searchMenu.addItem(withTitle: String(localized: "FilterField.recentMenu.noItem.label", defaultValue: "No Recent Filter", table: "Control"),
                           action: nil, keyEquivalent: "")
            .tag = NSSearchField.noRecentsMenuItemTag
        
        self.searchMenuTemplate = searchMenu
    }
}


private extension NSSearchField {
    
    /// The button cell used to display the search button image.
    var searchButtonCell: NSButtonCell? {
        
        (self.cell as? NSSearchFieldCell)?.searchButtonCell
    }
    
    
    /// The button cell used to display the cancel button image.
    @available(macOS, deprecated: 26.0, message: "The cancelButtonCell will no longer be used in the code.")
    var cancelButtonCell: NSButtonCell? {
        
        (self.cell as? NSSearchFieldCell)?.cancelButtonCell
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var text = ""
    
    FilterField(text: $text)
        .autosaveName("FilterField Preview")
        .frame(width: 160)
        .padding()
}
