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
import AppKit
import OSLog
import Shortcut

struct ShortcutsSettingsView: View {
    
    enum Category: CaseIterable {
        
        case menu
        case text
    }
    
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @Namespace private var namespace
    
    @State private var model = KeyBindingModel()
    @State private var category: Category = .menu
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("To change a shortcut, click the key column, then type the new keys.", tableName: "ShortcutsSettings")
                .lineLimit(10)
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 0) {
                switch self.category {
                    case .menu:
                        ShortcutTreeView(model: self.model)
                    case .text:
                        TextShortcutTable(model: self.model)
                }
            }
            .alternatingRowBackgrounds(.disabled)
            .tableColumnHeaders(.hidden)
            .safeAreaBar(edge: .top, alignment: .leading) {
                HStack {
                    ForEach(Category.allCases, id: \.self) { category in
                        Button(category.label) {
                            self.category = category
                        }
                        .buttonStyle(TabPickerButtonStyle(isSelected: category == self.category, namespace: self.namespace))
                    }
                }
                .animation(self.reduceMotion ? nil : .snappy(duration: 0.2), value: self.category)
                .accessibilityRepresentation {
                    Picker(selection: $category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.label)
                        }
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            .scrollEdgeEffectStyle(.hard, for: .top)
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
        .onChange(of: self.category) {
            self.model.error = nil
        }
        .alert(error: $model.savingError)
        .frame(width: SettingsPane.width)
    }
}


@MainActor @Observable private final class KeyBindingModel {
    
    typealias Item = Node<KeyBindingItem>
    
    private(set) var tree: [Item] = []
    private(set) var isRestorable: Bool = false
    private(set) var textKeyBindings = TextKeyBindingMap()
    var error: Shortcut.CustomizationError?
    var savingError: (any Error)?
    
    private let manager: KeyBindingManager = .shared
    
    
    /// Loads data from the user defaults.
    func load() {
        
        self.tree = self.manager.menuTree
        self.textKeyBindings = self.manager.textKeyBindings
        self.isRestorable = self.manager.isCustomized
    }
    
    
    /// Restores shortcut settings to default.
    func restore() {
        
        do {
            try self.manager.restoreDefaults()
        } catch {
            Logger.app.error("\(error.localizedDescription)")
            self.savingError = error
            return
        }
        
        // reset the values in place to keep the expansion state of the table
        for item in self.tree.flatMap(\.flatValues) {
            item.shortcut = item.defaultShortcut
        }
        self.isRestorable = false
        self.textKeyBindings = self.manager.textKeyBindings
        self.error = nil
    }
    
    
    /// Restores the default shortcut of a menu command.
    ///
    /// - Parameter item: The menu command to restore.
    func restore(_ item: KeyBindingItem) {
        
        if let shortcut = item.defaultShortcut {
            do {
                try self.manager.checkCustomizationAvailability(for: shortcut)
            } catch {
                self.error = error
                return
            }
        }
        
        self.error = nil
        item.shortcut = item.defaultShortcut
        self.save()
    }
    
    
    /// Saves the current settings.
    func save() {
        
        do {
            try self.manager.save(tree: self.tree)
        } catch {
            Logger.app.error("\(error.localizedDescription)")
            self.savingError = error
        }
        
        self.isRestorable = self.manager.isCustomized
    }
    
    
    /// Validates a shortcut to assign to a menu command or a text editing command.
    ///
    /// - Parameters:
    ///   - shortcut: The shortcut to validate.
    ///   - command: The text editing command to add the shortcut to, or `nil` for a menu command.
    /// - Throws: If the shortcut is unavailable.
    func validate(_ shortcut: Shortcut, for command: TextKeyBindingCommand? = nil) throws(Shortcut.CustomizationError) {
        
        try self.manager.checkCustomizationAvailability(for: shortcut, command: command)
    }
    
    
    /// Saves the shortcuts of a text editing command, or restores its system bindings with `nil`.
    ///
    /// - Parameters:
    ///   - shortcuts: The new shortcuts, or `nil` to restore system bindings.
    ///   - command: The command to update.
    func save(shortcuts: [Shortcut]?, for command: TextKeyBindingCommand) {
        
        self.error = nil
        do {
            try self.manager.save(shortcuts: shortcuts, for: command)
        } catch let error as Shortcut.CustomizationError {
            self.error = error
            return
        } catch {
            Logger.app.error("\(error.localizedDescription)")
            self.savingError = error
            return
        }
        
        self.textKeyBindings = self.manager.textKeyBindings
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
                                  error: $model.error, placeholder: item.defaultShortcut?.symbol,
                                  validation: { shortcut throws(Shortcut.CustomizationError) in try self.model.validate(shortcut) })
                }
            }
            .width(160)
            
        } rows: {
            ForEach(self.model.tree) { menu in
                Section(menu.name) {
                    OutlineGroup(menu.children ?? [], children: \.children)
                }
            }
        }
        .contextMenu(forSelectionType: Item.ID.self) { ids in
            if let id = ids.first, let item = self.model.tree.lazy.compactMap({ $0.node(with: id)?.value }).first {
                Button(.init("Action.restoreDefaults.label", defaultValue: "Restore Defaults")) {
                    self.model.restore(item)
                }
                .disabled(item.shortcut == item.defaultShortcut)
            }
        }
    }
}


private struct TextShortcutTable: View {
    
    @Bindable var model: KeyBindingModel
    
    @State private var selection: TextKeyBindingCommand?
    
    
    var body: some View {
        
        Table(TextKeyBindingCommand.allCases, selection: $selection) {
            TableColumn(.init("Command", table: "ShortcutsSettings", comment: "table column header")) { command in
                Text(command.label)
            }
            
            TableColumn(.init("Key", table: "ShortcutsSettings", comment: "table column header; keyboard shortcut")) { command in
                TextShortcutFields(model: self.model, command: command)
            }
            .width(160)
        }
        .contextMenu(forSelectionType: TextKeyBindingCommand.self) { commands in
            if let command = commands.first {
                Button(.init("Action.restoreDefaults.label", defaultValue: "Restore Defaults")) {
                    self.model.save(shortcuts: nil, for: command)
                }
                .disabled(self.model.textKeyBindings.customizations[command] == nil)
            }
        }
    }
}


private struct TextShortcutFields: View {
    
    @Bindable var model: KeyBindingModel
    var command: TextKeyBindingCommand
    
    
    var body: some View {
        
        let slots = self.slots
        
        HStack(spacing: 0) {
            ForEach(slots.indices, id: \.self) { index in
                if index > 1 {
                    Text(verbatim: ", ")
                }
                ShortcutField(value: Binding(get: { slots[index] }, set: { self.update($0, at: index) }),
                              error: $model.error,
                              placeholder: (slots.count == 1) ? self.command.shortcuts.map(\.symbol).joined(separator: ", ") : nil,
                              validation: { shortcut throws(Shortcut.CustomizationError) in try self.model.validate(shortcut, for: self.command) })
                .accessibilityLabel(.init("Add Shortcut", table: "ShortcutsSettings", comment: "accessibility label for the blank field to add a shortcut"),
                                    isEnabled: index == 0)
                .frame(width: slots[index].map(Self.width(of:)))
            }
        }
    }
    
    
    /// The fields to display: a blank one to add a shortcut, followed by the current shortcuts.
    private var slots: [Shortcut?] {
        
        [nil] + self.model.textKeyBindings.shortcuts(for: self.command)
    }
    
    
    /// Replaces the shortcut in a field, removing the field with `nil`, and saves the command's shortcuts.
    ///
    /// - Parameters:
    ///   - shortcut: The new shortcut, or `nil` to remove it.
    ///   - index: The index of the field to update.
    private func update(_ shortcut: Shortcut?, at index: Int) {
        
        var slots = self.slots
        
        guard slots.indices.contains(index) else { return }
        
        slots[index] = shortcut
        self.model.save(shortcuts: slots.compactMap(\.self), for: self.command)
    }
    
    
    /// Returns the width to display a shortcut in a field.
    ///
    /// - Parameter shortcut: The shortcut to display.
    /// - Returns: The field width in points.
    private static func width(of shortcut: Shortcut) -> CGFloat {
        
        let width = (shortcut.symbol as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 0)]).width
        
        return width + 6
    }
}


private struct TabPickerButtonStyle: PrimitiveButtonStyle {
    
    var isSelected: Bool
    var namespace: Namespace.ID
    
    
    @Environment(\.colorSchemeContrast) private var contrast
    
    @State private var isHovered = false
    
    private let shape = RoundedRectangle(cornerRadius: 6)
    
    
    func makeBody(configuration: Configuration) -> some View {
        
        Button(configuration)
            .buttonStyle(.borderless)
            .fontWeight(.medium)
            .foregroundStyle((self.isSelected || self.isHovered) ? .primary : .secondary)
            .padding(.vertical, 2)
            .padding(.horizontal, 10)
            .background {
                if self.isSelected {
                    self.shape.fill(.fill)
                        .matchedGeometryEffect(id: "selection", in: self.namespace)
                }
            }
            .overlay(self.contrast == .increased ? self.shape.stroke(.tertiary) : nil)
            .onHover { self.isHovered = $0 }
    }
}


private extension ShortcutsSettingsView.Category {
    
    var label: LocalizedStringResource {
        
        switch self {
            case .menu:
                .init("Category.menu.label",
                      defaultValue: "Menu", table: "ShortcutsSettings")
            case .text:
                .init("Category.text.label",
                      defaultValue: "Text Editing", table: "ShortcutsSettings")
        }
    }
}


// MARK: - Preview

#Preview {
    ShortcutsSettingsView()
        .scenePadding()
}
