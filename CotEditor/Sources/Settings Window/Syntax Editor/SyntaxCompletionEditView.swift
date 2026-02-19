//
//  SyntaxCompletionEditView.swift
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

struct SyntaxCompletionEditView: View {
    
    typealias Item = SyntaxObject.CompletionWord
    
    
    @Binding var items: [Item]
    
    var canCustomizeHighlight: Bool = true
    
    @State private var selection: Set<Item.ID> = []
    @State private var sortOrder: [KeyPathComparator<Item>] = []
    @FocusState private var focusedField: Item.ID?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            // create a table with wrapped values and then find the editable item again in each column to enable sorting (2025-07, macOS 26)
            Table(self.items, selection: $selection, sortOrder: $sortOrder) {
                TableColumn(String(localized: "Completion", table: "SyntaxEditor", comment: "table column header"), value: \.value.text) { wrappedItem in
                    if let item = $items[id: wrappedItem.id] {
                        TextField(text: item.value.text, label: EmptyView.init)
                            .focused($focusedField, equals: item.id)
                    }
                }
                
                TableColumn(String(localized: "Type", table: "SyntaxEditor", comment: "table column header"), value: \.value.type.sortValue) { wrappedItem in
                    if let item = $items[id: wrappedItem.id] {
                        Picker(selection: item.value.type) {
                            Text("None", tableName: "SyntaxEditor")
                                .tag(Optional<SyntaxType>.none)
                            Divider()
                            ForEach(SyntaxType.allCases, id: \.self) { type in
                                Text(type.label)
                                    .tag(Optional(type))
                            }
                        } label: {
                            Text("Type", tableName: "SyntaxEditor")
                        } currentValueLabel: {
                            if let type = wrappedItem.value.type {
                                Text(type.label)
                            } else {
                                Text("None", tableName: "SyntaxEditor")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        .labelsHidden()
                    }
                }
                .width(100)
            }
            .onChange(of: self.sortOrder) { _, newValue in
                self.items.sort(using: newValue)
            }
            .tableStyle(.bordered)
            .border(Color(nsColor: .gridColor))
            
            HStack {
                AddRemoveButton($items, selection: $selection, newItem: Item()) { item in
                    self.focusedField = item.id
                }
                Text("\(self.items.count) items", tableName: "SyntaxEditor")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .controlSize(.small)
            }
            
            if self.canCustomizeHighlight {
                Text("If not specified, syntax completion words are generated based on the highlighting settings.", tableName: "SyntaxEditor", comment: "message")
                    .controlSize(.small)
                    .padding(.top, 4)
            }
            
            HStack {
                Spacer()
                HelpLink(anchor: "syntax_highlight_settings")
            }
        }
    }
}


private extension SyntaxType? {
    
    // The value for column sorting.
    var sortValue: Int {
        
        switch self {
            case .none:
                99
            case .some(let type):
                SyntaxType.allCases.firstIndex(of: type) ?? 99
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var items: [SyntaxObject.CompletionWord] = [.init(value: .init(text: "abc"))]
    
    SyntaxCompletionEditView(items: $items)
        .padding()
}
