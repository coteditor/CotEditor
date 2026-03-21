//
//  SyntaxDelimitersEditView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2026 1024jp
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
import Syntax

struct SyntaxDelimitersEditView: View {
    
    @Binding var inlineComments: [SyntaxObject.InlineComment]
    @Binding var blockComments: [SyntaxObject.BlockComment]
    @Binding var stringDelimiters: [SyntaxObject.PairDelimiter]
    @Binding var characterDelimiters: [SyntaxObject.PairDelimiter]
    @Binding var indentations: [SyntaxObject.BlockIndent]
    
    var canCustomizeHighlight: Bool = true
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading) {
                Text(SyntaxType.comments.label)
                    .fontWeight(.semibold)
                    .padding(.bottom, 2)
                
                HStack(alignment: .firstTextBaseline, spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Inline comment:", tableName: "SyntaxEditor", comment: "label")
                            .accessibilityAddTraits(.isHeader)
                        InlineCommentsEditView(items: $inlineComments)
                    }.accessibilityElement(children: .contain)
                    
                    VStack(alignment: .leading) {
                        Text("Block comment:", tableName: "SyntaxEditor", comment: "label")
                            .accessibilityAddTraits(.isHeader)
                        BlockCommentsEditView(items: $blockComments)
                    }.accessibilityElement(children: .contain)
                }
            }
            .padding(.bottom)
            
            VStack(alignment: .leading) {
                Text(SyntaxType.strings.label)
                    .fontWeight(.semibold)
                    .padding(.bottom, 2)
                
                Text("String delimiters:", tableName: "SyntaxEditor", comment: "label")
                    .accessibilityAddTraits(.isHeader)
                StringDelimitersEditView(items: $stringDelimiters)
            }
            .padding(.bottom)
            
            VStack(alignment: .leading) {
                Text(SyntaxType.characters.label)
                    .fontWeight(.semibold)
                    .padding(.bottom, 2)
                
                Text("Character delimiters:", tableName: "SyntaxEditor", comment: "label")
                    .accessibilityAddTraits(.isHeader)
                CharacterDelimitersEditView(items: $characterDelimiters)
            }
            .padding(.bottom)
            
            VStack(alignment: .leading) {
                Text("Indentation", tableName: "SyntaxEditor")
                    .fontWeight(.semibold)
                    .padding(.bottom, 2)
                
                Text("Block delimiters:", tableName: "SyntaxEditor", comment: "label")
                    .accessibilityAddTraits(.isHeader)
                BlockEditView(items: $indentations)
                Text("The block delimiters are used for automatic indentation while typing.", tableName: "SyntaxEditor")
                    .controlSize(.small)
                    .padding(.top, 2)
            }
            .padding(.bottom)
            
            if self.canCustomizeHighlight {
                Text("The delimiters defined here are used for syntax highlighting as well.", tableName: "SyntaxEditor")
                    .controlSize(.small)
                    .padding(.top)
            }
            
            Spacer(minLength: 0)
            
            HStack {
                Spacer()
                HelpLink(anchor: "syntax_delimiter_settings")
            }
        }
        .scenePadding()
    }
}


// MARK: - Comments

private struct InlineCommentsEditView: View {
    
    typealias Item = SyntaxObject.InlineComment
    
    @Binding var items: [Item]
    
    @State private var selection: Set<Item.ID> = []
    @FocusState private var focusedField: Item.ID?
    
    
    var body: some View {
        
        Table($items, selection: $selection) {
            TableColumn(String(localized: "Begin String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.begin, label: EmptyView.init)
                    .focused($focusedField, equals: item.id)
            }
            TableColumn(String(localized: "Line Start Only", table: "SyntaxEditor", comment: "table column header, keep short")) { $item in
                Toggle(isOn: $item.value.leadingOnly, label: EmptyView.init)
            }
            .alignment(.center)
        }
        .tableStyle(.bordered)
        .border(Color(nsColor: .gridColor))
        .frame(height: 100)
        
        HStack {
            AddRemoveButton($items, selection: $selection, newItem: Item()) { item in
                self.focusedField = item.id
            }
            ItemCountView(count: self.items.count)
        }
    }
}


private struct BlockCommentsEditView: View {
    
    typealias Item = SyntaxObject.BlockComment
    
    @Binding var items: [Item]
    
    @State private var selection: Set<Item.ID> = []
    @FocusState private var focusedField: Item.ID?
    
    
    var body: some View {
        
        Table($items, selection: $selection) {
            TableColumn(String(localized: "Begin String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.begin, label: EmptyView.init)
                    .focused($focusedField, equals: item.id)
            }
            TableColumn(String(localized: "End String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.end, label: EmptyView.init)
            }
            TableColumn(String(localized: "Nest", table: "SyntaxEditor", comment: "table column header, keep short")) { $item in
                Toggle(isOn: $item.value.isNestable, label: EmptyView.init)
                    .onChange(of: item.value.isNestable) { _, newValue in
                        guard self.selection.contains(item.id) else { return }
                        $items
                            .filter(with: self.selection)
                            .filter { $0.id != item.id }
                            .forEach { $0.value.isNestable.wrappedValue = newValue }
                    }
            }
            .alignment(.center)
        }
        .tableStyle(.bordered)
        .border(Color(nsColor: .gridColor))
        .frame(height: 100)
        
        HStack {
            AddRemoveButton($items, selection: $selection, newItem: Item()) { item in
                self.focusedField = item.id
            }
            ItemCountView(count: self.items.count)
        }
    }
}


// MARK: - String Delimiters

private struct StringDelimitersEditView: View {
    
    typealias Item = SyntaxObject.PairDelimiter
    
    @Binding var items: [Item]
    
    @State private var selection: Set<Item.ID> = []
    @FocusState private var focusedField: Item.ID?
    
    
    var body: some View {
        
        Table($items, selection: $selection) {
            TableColumn(String(localized: "Begin String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.begin, label: EmptyView.init)
                    .focused($focusedField, equals: item.id)
            }
            TableColumn(String(localized: "End String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.end, label: EmptyView.init)
            }
            TableColumn(String(localized: "Multiline", table: "SyntaxEditor", comment: "table column header, keep short")) { $item in
                Toggle(isOn: $item.value.isMultiline, label: EmptyView.init)
                    .onChange(of: item.value.isMultiline) { _, newValue in
                        guard self.selection.contains(item.id) else { return }
                        $items
                            .filter(with: self.selection)
                            .filter { $0.id != item.id }
                            .forEach { $0.value.isMultiline.wrappedValue = newValue }
                    }
            }
            .width(56)
            .alignment(.center)
            TableColumn(String(localized: "Escape Character", defaultValue: "Escape Character", table: "SyntaxEditor", comment: "table column header")) { $item in
                let binding = Binding<String>(
                    get: { item.value.escapeCharacter.map(String.init) ?? "" },
                    set: { item.value.escapeCharacter = $0.first }
                )
                TextField(text: binding, label: EmptyView.init)
            }
            TableColumn(String(localized: "Description", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.description ?? "", label: EmptyView.init)
            }
        }
        .tableStyle(.bordered)
        .border(Color(nsColor: .gridColor))
        .frame(height: 100)
        
        HStack {
            AddRemoveButton($items, selection: $selection, newItem: Item()) { item in
                self.focusedField = item.id
            }
            ItemCountView(count: self.items.count)
        }
    }
}


// MARK: - Character Delimiters

private struct CharacterDelimitersEditView: View {
    
    typealias Item = SyntaxObject.PairDelimiter
    
    @Binding var items: [Item]
    
    @State private var selection: Set<Item.ID> = []
    @FocusState private var focusedField: Item.ID?
    
    
    var body: some View {
        
        Table($items, selection: $selection) {
            TableColumn(String(localized: "Begin String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.begin, label: EmptyView.init)
                    .focused($focusedField, equals: item.id)
            }
            TableColumn(String(localized: "End String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.end, label: EmptyView.init)
            }
            TableColumn(String(localized: "Escape Character", defaultValue: "Escape Character", table: "SyntaxEditor", comment: "table column header")) { $item in
                let binding = Binding<String>(
                    get: { item.value.escapeCharacter.map(String.init) ?? "" },
                    set: { item.value.escapeCharacter = $0.first }
                )
                TextField(text: binding, label: EmptyView.init)
            }
            TableColumn(String(localized: "Description", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.description ?? "", label: EmptyView.init)
            }
        }
        .tableStyle(.bordered)
        .border(Color(nsColor: .gridColor))
        .frame(height: 100)
        
        HStack {
            AddRemoveButton($items, selection: $selection, newItem: Item()) { item in
                self.focusedField = item.id
            }
            ItemCountView(count: self.items.count)
        }
    }
}


// MARK: - Indentations

private struct BlockEditView: View {
    
    typealias Item = SyntaxObject.BlockIndent
    
    @Binding var items: [Item]
    
    @State private var selection: Set<Item.ID> = []
    @FocusState private var focusedField: Item.ID?
    
    
    var body: some View {
        
        Table($items, selection: $selection) {
            TableColumn(String(localized: "IC", table: "SyntaxEditor", comment: "table column header (IC for Ignore Case)")) { $item in
                Toggle(isOn: $item.value.ignoreCase, label: EmptyView.init)
                    .help(String(localized: "Ignore Case", table: "SyntaxEditor", comment: "tooltip for IC checkbox"))
                    .onChange(of: item.value.ignoreCase) { _, newValue in
                        guard self.selection.contains(item.id) else { return }
                        $items
                            .filter(with: self.selection)
                            .filter { $0.id != item.id }
                            .forEach { $0.value.ignoreCase.wrappedValue = newValue }
                    }
            }
            .width(34)
            .alignment(.center)
            TableColumn(String(localized: "Begin String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.begin, label: EmptyView.init)
                    .focused($focusedField, equals: item.id)
            }
            TableColumn(String(localized: "End String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.end ?? "", label: EmptyView.init)
            }
            TableColumn(String(localized: "Description", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.description ?? "", label: EmptyView.init)
            }
        }
        .tableStyle(.bordered)
        .border(Color(nsColor: .gridColor))
        .frame(height: 100)
        
        HStack {
            AddRemoveButton($items, selection: $selection, newItem: Item()) { item in
                self.focusedField = item.id
            }
            ItemCountView(count: self.items.count)
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var inlineComments: [SyntaxObject.InlineComment] = [.init(value: .init(begin: "//"))]
    @Previewable @State var blockComments: [SyntaxObject.BlockComment] = [.init(value: .init(begin: "/*", end: "*/"))]
    @Previewable @State var stringDelimiters: [SyntaxObject.PairDelimiter] = [.init(value: .init(begin: "\"", end: "\""))]
    @Previewable @State var characterDelimiters: [SyntaxObject.PairDelimiter] = [.init(value: .init(begin: "'", end: "'"))]
    @Previewable @State var indentations: [SyntaxObject.BlockIndent] = [.init(value: .init(begin: "{", end: "}"))]
    
    SyntaxDelimitersEditView(
        inlineComments: $inlineComments,
        blockComments: $blockComments,
        stringDelimiters: $stringDelimiters,
        characterDelimiters: $characterDelimiters,
        indentations: $indentations
    )
}
