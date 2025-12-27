//
//  SnippetsSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2025 1024jp
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
import Defaults

struct SnippetsSettingsView: View {
    
    private var insets = EdgeInsets(top: 4, leading: 10, bottom: 10, trailing: 10)
    
    
    var body: some View {
        
        VStack {
            TabView {
                Tab {
                    CommandSnippetsView()
                        .padding(self.insets)
                } label: {
                    Text("Command", tableName: "SnippetsSettings", comment: "tab label")
                }
                
                Tab {
                    FileDropView()
                        .padding(self.insets)
                } label: {
                    Text("File Drop", tableName: "SnippetsSettings", comment: "tab label")
                }
            }
            .tabViewStyle(.tabBarOnly)
            .frame(height: 380)
            
            HStack {
                Spacer()
                HelpLink(anchor: "settings_snippets")
            }
        }
        .scenePadding()
        .frame(width: 620)
    }
}


private struct CommandSnippetsView: View {
    
    private typealias Item = Snippet
    
    
    private var manager: SnippetManager = .shared
    
    @State private var items: [Item] = []
    @State private var selection: Set<Item.ID> = []
    @State private var syntaxes: [String] = []
    
    @State private var error: (any Error)?
    @State private var format: String?
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Text to be inserted by a command in the menu or by keyboard shortcut:", tableName: "SnippetsSettings")
            
            Table(of: Binding<Item>.self, selection: $selection) {
                TableColumn(String(localized: "Syntax", table: "SnippetsSettings", comment: "table column header")) { item in
                    SyntaxPicker(syntaxes: self.syntaxes, selection: item.scope)
                        .buttonStyle(.borderless)
                        .help(String(localized: "Syntax in which this file drop setting is used.", table: "SnippetsSettings", comment: "tooltip"))
                }.width(160)
                
                TableColumn(String(localized: "Name", table: "SnippetsSettings", comment: "table column header")) { item in
                    TextField(text: item.name, label: EmptyView.init)
                }
                
                TableColumn(String(localized: "Key", table: "SnippetsSettings", comment: "table column header")) { item in
                    ShortcutField(value: item.shortcut, error: $error)
                }
                .width(80)
                
            } rows: {
                ForEach($items) { item in
                    TableRow(item)
                        .draggable(item.id)
                }
                .dropDestination(for: UUID.self) { index, ids in
                    // `dropDestination(for:)` shows a plus badge which should be avoided
                    // on just moving items in the identical table,
                    // but `onMove()` is not provided yet for DynamicTableRowContent.
                    // (2025-06, macOS 26)
                    let indexes = ids.compactMap { uuid in self.items.firstIndex(where: { $0.id == uuid }) }
                    
                    withAnimation {
                        self.items.move(fromOffsets: IndexSet(indexes), toOffset: index)
                    }
                }
            }
            .onChange(of: self.selection, initial: true) { _, newValue in
                self.format = if newValue.count == 1, let id = newValue.first {
                    self.items[id: id]?.format
                } else {
                    nil
                }
            }
            .onChange(of: self.format) { _, newValue in
                guard
                    let format = newValue,
                    let id = self.selection.first
                else { return }
                
                self.items[id: id]?.format = format
            }
            .tableStyle(.bordered)
            .border(Color(nsColor: .gridColor))
            
            HStack(alignment: .firstTextBaseline) {
                AddRemoveButton($items, selection: $selection, newItem: self.manager.createUntitledSetting())
                Spacer()
                if let error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                        .controlSize(.small)
                }
            }
            .padding(.bottom)
            
            InsertionFormatView<Snippet.Variable>(text: $format, count: self.selection.count)
        }
        .onAppear {
            self.items = self.manager.snippets
            if let item = self.items.first {
                self.selection = [item.id]
            }
            self.syntaxes = SyntaxManager.shared.settingNames
        }
        .onChange(of: self.items) { _, newValue in
            self.manager.save(newValue)
        }
    }
}


private struct FileDropView: View {
    
    private typealias Item = FileDropItem
    
    @State private var items: [Item] = []
    @State private var selection: Set<Item.ID> = []
    @State private var syntaxes: [String] = []
    
    @State private var format: String?
    @State private var canRestore: Bool = false
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Text to be inserted by dropping files to the editor:", tableName: "SnippetsSettings")
            
            Table(of: Binding<Item>.self, selection: $selection) {
                TableColumn(String(localized: "Syntax", table: "SnippetsSettings", comment: "table column header")) { item in
                    SyntaxPicker(syntaxes: self.syntaxes, selection: item.scope)
                        .buttonStyle(.borderless)
                        .help(String(localized: "Syntax in which this file drop setting is used.", table: "SnippetsSettings", comment: "tooltip"))
                }.width(160)
                
                TableColumn(String(localized: "Extensions", table: "SnippetsSettings", comment: "table column header")) { item in
                    TextField(value: item.extensions, format: .csv(omittingEmptyItems: true), prompt: Text("All", tableName: "SnippetsSettings"), label: EmptyView.init)
                        .help(String(localized: "File extensions of dropped file (comma separated).", table: "SnippetsSettings", comment: "tooltip"))
                }
                
                TableColumn(String(localized: "Description", table: "SnippetsSettings", comment: "table column header")) { item in
                    TextField(text: item.description ?? "", label: EmptyView.init)
                }
            } rows: {
                ForEach($items) { item in
                    TableRow(item)
                        .draggable(item.id)
                }
                .dropDestination(for: UUID.self) { index, ids in
                    let indexes = ids.compactMap { uuid in self.items.firstIndex(where: { $0.id == uuid }) }
                    
                    withAnimation {
                        self.items.move(fromOffsets: IndexSet(indexes), toOffset: index)
                    }
                }
            }
            .onChange(of: self.selection, initial: true) { _, newValue in
                self.format = if newValue.count == 1, let id = newValue.first {
                    self.items[id: id]?.format
                } else {
                    nil
                }
            }
            .onChange(of: self.format) { _, newValue in
                guard
                    let format = newValue,
                    let id = self.selection.first
                else { return }
                
                self.items[id: id]?.format = format
            }
            .tableStyle(.bordered)
            .border(Color(nsColor: .gridColor))
            
            HStack(alignment: .firstTextBaseline) {
                AddRemoveButton($items, selection: $selection, newItem: Item())
                Spacer()
                Button(String(localized: "Action.restoreDefaults.label", defaultValue: "Restore Defaults"), action: self.restore)
                    .disabled(!self.canRestore)
            }
            .padding(.bottom)
            
            InsertionFormatView<FileDropItem.Variable>(text: $format, count: self.selection.count)
        }
        .onAppear {
            self.load()
            self.syntaxes = SyntaxManager.shared.settingNames
        }
        .onChange(of: self.items) { _, newValue in
            self.save(items: newValue)
        }
    }
    
    
    /// Loads settings from UserDefaults.
    private func load() {
        
        let array = UserDefaults.standard[.fileDropArray]
        
        self.items = array.compactMap(FileDropItem.init(dictionary:))
        self.canRestore = array == UserDefaults.standard[initial: .fileDropArray]
        if let item = self.items.first {
            self.selection = [item.id]
        }
    }
    
    
    /// Restores the settings to the default.
    private func restore() {
        
        UserDefaults.standard.restore(key: .fileDropArray)
        
        self.load()
    }
    
    
    /// Writes back the settings to UserDefaults.
    ///
    /// - Parameter items: The items to save.
    private func save(items: [Item]) {
        
        // sanitize
        let sanitized = items
            .filter { !$0.format.isEmpty }
            .map(\.dictionary)
        
        // check if the new setting is different from the default
        self.canRestore = sanitized != UserDefaults.standard[initial: .fileDropArray]
        if self.canRestore {
            UserDefaults.standard[.fileDropArray] = sanitized
        } else {
            UserDefaults.standard.restore(key: .fileDropArray)
        }
    }
}


private struct SyntaxPicker: View {
    
    var syntaxes: [String]
    
    @Binding var selection: String?
    
    
    var body: some View {
        
        Picker(selection: $selection) {
            Text("All", tableName: "SnippetsSettings")
                .foregroundStyle(.tertiary)
                .tag(String?.none)
            Divider()
            ForEach(self.syntaxes, id: \.self) {
                Text($0).tag(String?.some($0))
            }
        } label: {
            EmptyView()
        }
    }
}


private struct InsertionFormatView<Variable: TokenRepresentable>: View {
    
    @Binding var text: String?
    var count: Int
    
    @Namespace private var accessibility
    
    
    var body: some View {
        
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Text("Insertion format:", tableName: "SnippetsSettings")
                    .accessibilityLabeledPair(role: .label, id: "insertionFormat", in: self.accessibility)
                Spacer()
                Menu(String(localized: "Insert Variable", table: "SnippetsSettings", comment: "button label")) {
                    ForEach(Array(Variable.listCases.enumerated()), id: \.offset) { _, variable in
                        if let variable {
                            Button {
                                let menuItem = NSMenuItem()
                                menuItem.representedObject = variable.token
                                NSApp.sendAction(#selector(NSTextView.insertVariable), to: nil, from: menuItem)
                            } label: {
                                Text(variable.token)
                                Text(variable.localizedDescription)
                            }
                        } else {
                            Divider()
                        }
                    }
                }
                .fixedSize()
            }
            
            TokenTextEditor(text: $text, tokenizer: Variable.tokenizer)
                .accessibilityLabeledPair(role: .content, id: "insertionFormat", in: self.accessibility)
                .frame(height: 100)
                .overlay {
                    if let prompt {
                        Text(prompt).foregroundStyle(.placeholder)
                    }
                }
        }
        .disabled(self.count != 1)
    }
    
    
    private var prompt: String? {
        
        switch self.count {
            case 0: String(localized: "ItemSelection.zero.message", defaultValue: "No item selected")
            case 1: nil
            default: String(localized: "ItemSelection.multiple.message", defaultValue: "Multiple items selected")
        }
    }
}


// MARK: - Preview

#Preview {
    SnippetsSettingsView()
}
