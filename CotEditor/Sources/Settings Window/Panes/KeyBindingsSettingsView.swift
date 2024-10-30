//
//  KeyBindingsSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-08-20.
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
import OSLog
import Shortcut

struct KeyBindingsSettingsView: View {
    
    private typealias Item = Node<KeyBindingItem>
    
    let manager: KeyBindingManager = .shared
    
    
    @State private var tree: [Item] = []
    
    @State private var isRestorable: Bool = false
    @State private var selection: Item.ID?
    @State private var error: (any Error)?
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("To change a shortcut, click the key column, and then type the new keys.", tableName: "KeyBindingsSettings")
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 0) {
                Table(self.tree, selection: $selection) {
                    TableColumn(String(localized: "Menu", table: "KeyBindingsSettings", comment: "table column header"), value: \.name)
                }
                .frame(width: 120)
                
                if let selection,
                   let item = Binding($tree[id: selection]),
                   let items = Binding(item.children)
                {
                    KeyBindingCommandTable(items: items, error: $error)
                        .padding(.leading, -1)
                }
            }
            .tableStyle(.bordered)
            .alternatingRowBackgrounds(.disabled)
            .border(Color(nsColor: .gridColor))
            .frame(height: 260)
            
            HStack(alignment: .firstTextBaseline) {
                Button(String(localized: "Action.restoreDefaults.label", defaultValue: "Restore Defaults"), action: self.restore)
                    .disabled(!self.isRestorable)
                    .fixedSize()
                
                Spacer()
                
                if let error = self.error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                        .controlSize(.small)
                }
                HelpLink(anchor: "settings_keybindings")
            }.frame(minHeight: 20)
        }
        .onAppear {
            self.tree = self.manager.menuTree
            self.isRestorable = self.manager.isCustomized
            self.selection = self.tree.first?.id
        }
        .onChange(of: self.tree) {
            self.save()
        }
        .scenePadding()
        .frame(width: 620)
    }
    
    
    /// Restores key binding setting to default.
    private func restore() {
        
        try? self.manager.restoreDefaults()
        
        self.tree = self.manager.menuTree
        self.isRestorable = false
        self.error = nil
    }
    
    
    /// Saves the current settings.
    private func save() {
        
        do {
            try self.manager.save(tree: self.tree)
        } catch {
            Logger.app.error("\(error.localizedDescription)")
        }
        
        self.isRestorable = self.manager.isCustomized
    }
}


private struct KeyBindingCommandTable: View {
    
    typealias Item = Node<KeyBindingItem>
    
    @Binding var items: [Item]
    @Binding var error: (any Error)?
    
    @State private var selection: Item.ID?
    
    
    var body: some View {
        
        Table(of: Binding<Item>.self, selection: $selection) {
            TableColumn(String(localized: "Command", table: "KeyBindingsSettings", comment: "table column header"), value: \.name.wrappedValue)
            
            TableColumn(String(localized: "Key", table: "KeyBindingsSettings", comment: "table column header")) {
                if let keyBindingItem = Binding($0.value) {
                    ShortcutField(value: keyBindingItem.shortcut, error: $error)
                }
            }
            .width(80)
            
        } rows: {
            RecursiveDisclosureTableRows($items)
        }
    }
}


private struct RecursiveDisclosureTableRows: TableRowContent {
    
    typealias Item = Node<KeyBindingItem>
    
    @Binding var items: [Item]
    
    
    init(_ items: Binding<[Item]>) {
        
        self._items = items
    }
    
    
    var tableRowBody: some TableRowContent<Binding<Item>> {
        
        ForEach($items) { item in
            if let children = Binding(item.children) {
                DisclosureTableRow(item) {
                    RecursiveDisclosureTableRows(children)
                }
            } else {
                TableRow(item)
            }
        }
    }
}


// MARK: - Preview

#Preview {
    KeyBindingsSettingsView()
}
