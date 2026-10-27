//
//  ShortcutsSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-08-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2026 1024jp
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

struct ShortcutsSettingsView: View {
    
    @State private var model = KeyBindingModel()
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("To change a shortcut, click the key column, then type the new keys.", tableName: "ShortcutsSettings")
                .lineLimit(10)
                .fixedSize(horizontal: false, vertical: true)
            
            ShortcutTreeView(model: self.model)
                .clipShape(.rect(cornerRadius: 7, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(.separator))
                .frame(height: 280)
            
            HStack(alignment: .firstTextBaseline) {
                Button(.init("Action.restoreDefaults.label", defaultValue: "Restore Defaults"), action: self.model.restore)
                    .disabled(!self.model.isRestorable)
                
                Spacer()
                
                if let error = self.model.error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                        .controlSize(.small)
                }
                HelpLink(anchor: "settings_shortcuts")
            }.frame(minHeight: 20)
        }
        .onAppear {
            self.model.load()
        }
        .frame(width: SettingsPane.width)
    }
}


@MainActor @Observable private final class KeyBindingModel {
    
    typealias Item = Node<KeyBindingItem>
    
    private(set) var tree: [Item] = []
    private(set) var isRestorable: Bool = false
    var error: Shortcut.CustomizationError?
    
    private let manager: KeyBindingManager = .shared
    
    
    /// Loads data from the user defaults.
    func load() {
        
        self.tree = self.manager.menuTree
        self.isRestorable = self.manager.isCustomized
    }
    
    
    /// Restores shortcut settings to default.
    func restore() {
        
        do {
            try self.manager.restoreDefaults()
        } catch {
            Logger.app.error("\(error.localizedDescription)")
            return
        }
        
        // reset the values in place to keep the expansion state of the table
        for item in self.tree.flatMap(\.flatValues) {
            item.shortcut = item.defaultShortcut
        }
        self.isRestorable = false
        self.error = nil
    }
    
    
    /// Saves the current settings.
    func save() {
        
        do {
            try self.manager.save(tree: self.tree)
        } catch {
            Logger.app.error("\(error.localizedDescription)")
        }
        
        self.isRestorable = self.manager.isCustomized
    }
}


private struct ShortcutTreeView: View {
    
    typealias Item = KeyBindingModel.Item
    
    @Bindable var model: KeyBindingModel
    
    @State private var selection: Item.ID?
    
    
    var body: some View {
        
        Table(of: Item.self, selection: $selection) {
            TableColumn(.init("Command", table: "ShortcutsSettings", comment: "table column header"), value: \.name)
            
            TableColumn(.init("Key", table: "ShortcutsSettings", comment: "table column header; keyboard shortcut")) { node in
                if let item = node.value {
                    ShortcutField(value: Binding(get: { item.shortcut },
                                                 set: { item.shortcut = $0; self.model.save() }),
                                  error: $model.error, placeholder: item.defaultShortcut?.symbol)
                }
            }
            .width(100)
            
        } rows: {
            ForEach(self.model.tree) { menu in
                Section(menu.name) {
                    OutlineGroup(menu.children ?? [], children: \.children)
                }
            }
        }
    }
}


// MARK: - Preview

#Preview {
    ShortcutsSettingsView()
        .scenePadding()
}
