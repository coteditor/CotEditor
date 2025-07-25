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
//  © 2023-2025 1024jp
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

struct SyntaxCompletionEditView: View {
    
    typealias Item = SyntaxObject.KeyString
    
    
    @Binding var items: [Item]
    
    @State private var selection: Set<Item.ID> = []
    @State private var sortOrder: [KeyPathComparator<Item>] = []
    @FocusState private var focusedField: Item.ID?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("If not specified, syntax completion words are generated based on the highlighting settings.", tableName: "SyntaxEditor", comment: "message")
                .controlSize(.small)
            
            // create a table with wrapped values and then find the editable item again in each column to enable sorting (2025-07-19 macOS 26)
            Table(self.items, selection: $selection, sortOrder: $sortOrder) {
                TableColumn(String(localized: "Completion", table: "SyntaxEditor", comment: "table column header"), value: \.value) { wrappedItem in
                    if let item = $items[id: wrappedItem.id] {
                        TextField(text: item.value, label: EmptyView.init)
                            .focused($focusedField, equals: item.id)
                    }
                }
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
                Spacer()
                HelpLink(anchor: "syntax_highlight_settings")
            }
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var items: [SyntaxObject.KeyString] = [.init(value: "abc")]
    
    SyntaxCompletionEditView(items: $items)
        .padding()
}
