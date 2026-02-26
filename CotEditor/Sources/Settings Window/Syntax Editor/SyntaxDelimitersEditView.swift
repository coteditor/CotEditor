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
import StringUtils
import Syntax

struct SyntaxDelimitersEditView: View {
    
    @Binding var inlineComments: [SyntaxObject.InlineComment]
    @Binding var blockComments: [SyntaxObject.BlockComment]
    @Binding var indentations: [SyntaxObject.BlockIndent]
    @Binding var lexicalRules: Syntax.LexicalRules
    
    var canCustomizeHighlight: Bool = true
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading) {
                Text("Comments", tableName: "SyntaxEditor")
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
                
                if self.canCustomizeHighlight {
                    Text("The comment delimiters defined here are used for syntax highlighting as well.", tableName: "SyntaxEditor")
                        .controlSize(.small)
                        .padding(.top, 2)
                }
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
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Escaping", tableName: "SyntaxEditor")
                    .fontWeight(.semibold)
                    .padding(.top, 2)
                
                Form {
                    Picker(String(localized: "Delimiter escape style:", table: "SyntaxEditor"), selection: $lexicalRules.delimiterEscapeRule) {
                        ForEach(DelimiterEscapeRule.allCases, id: \.self) { rule in
                            Text(rule.label)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .horizontalRadioGroupLayout()
                    .fixedSize()
                }
            }
            
            Spacer(minLength: 0)
            
            HStack {
                Spacer()
                HelpLink(anchor: "syntax_delimiter_settings")
            }
        }
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
            }
            TableColumn(String(localized: "Line Start Only", table: "SyntaxEditor", comment: "table column header, keep short")) { $item in
                Toggle(isOn: $item.value.leadingOnly, label: EmptyView.init)
            }
            .alignment(.center)
        }
        .tableStyle(.bordered)
        .border(Color(nsColor: .gridColor))
        .frame(minHeight: 80, maxHeight: 120)
        
        AddRemoveButton($items, selection: $selection, newItem: Item()) { item in
            self.focusedField = item.id
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
            }
            TableColumn(String(localized: "End String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.end, label: EmptyView.init)
            }
        }
        .tableStyle(.bordered)
        .border(Color(nsColor: .gridColor))
        .frame(minHeight: 80, maxHeight: 120)
        
        AddRemoveButton($items, selection: $selection, newItem: Item()) { item in
            self.focusedField = item.id
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
            }
            TableColumn(String(localized: "End String", table: "SyntaxEditor", comment: "table column header")) { $item in
                TextField(text: $item.value.end ?? "", label: EmptyView.init)
            }
        }
        .tableStyle(.bordered)
        .border(Color(nsColor: .gridColor))
        .frame(minHeight: 80, maxHeight: 120)
        
        AddRemoveButton($items, selection: $selection, newItem: Item()) { item in
            self.focusedField = item.id
        }
    }
}


// MARK: - Localizations

private extension DelimiterEscapeRule {
    
    var label: String {
        
        switch self {
            case .backslash:
                String(localized: "DelimiterEscapeRule.backslash.label",
                       defaultValue: "Backslash",
                       table: "SyntaxEditor")
            case .none:
                String(localized: "DelimiterEscapeRule.none.label",
                       defaultValue: "None",
                       table: "SyntaxEditor")
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var inlineComments: [SyntaxObject.InlineComment] = [.init(value: .init(begin: "//"))]
    @Previewable @State var blockComments: [SyntaxObject.BlockComment] = [.init(value: .init(begin: "/*", end: "*/"))]
    @Previewable @State var indentations: [SyntaxObject.BlockIndent] = [.init(value: .init(begin: "{", end: "}"))]
    @Previewable @State var rules: Syntax.LexicalRules = .default
    
    SyntaxDelimitersEditView(inlineComments: $inlineComments, blockComments: $blockComments, indentations: $indentations, lexicalRules: $rules)
        .padding()
}
