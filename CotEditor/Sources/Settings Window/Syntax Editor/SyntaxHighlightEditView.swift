//
//  SyntaxHighlightEditView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-01-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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

struct SyntaxHighlightEditView: View {
    
    typealias Item = SyntaxObject.Highlight
    
    
    @Binding var items: [Item]
    var helpAnchor: String = "syntax_highlight_settings"
    
    @State private var selection: Set<Item.ID> = []
    @State private var sortOrder: [KeyPathComparator<Item>] = []
    @FocusState private var focusedField: Item.ID?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            // create a table with wrapped values and then find the editable item again in each column
            // to avoid taking time when leaving a pane with a large number of items. (2024-02-25 macOS 14)
            Table(self.items, selection: $selection, sortOrder: $sortOrder) {
                TableColumn(String(localized: "RE", table: "SyntaxEditor", comment: "table column header (RE for Regular Expression)"), value: \.isRegularExpression) { wrappedItem in
                    if let item = $items[id: wrappedItem.id] {
                        Toggle(isOn: item.isRegularExpression, label: EmptyView.init)
                            .help(String(localized: "Regular Expression", table: "SyntaxEditor", comment: "tooltip for RE checkbox"))
                            .onChange(of: item.isRegularExpression.wrappedValue) { (_, newValue) in
                                guard self.selection.contains(item.id) else { return }
                                $items
                                    .filter(with: self.selection)
                                    .filter { $0.id != item.id }
                                    .forEach { $0.isRegularExpression.wrappedValue = newValue }
                            }
                    }
                }
                .width(24)
                .alignment(.center)
                
                TableColumn(String(localized: "IC", table: "SyntaxEditor", comment: "table column header (IC for Ignore Case)"), value: \.ignoreCase) { wrappedItem in
                    if let item = $items[id: wrappedItem.id] {
                        Toggle(isOn: item.ignoreCase, label: EmptyView.init)
                            .help(String(localized: "Ignore Case", table: "SyntaxEditor", comment: "tooltip for IC checkbox"))
                            .onChange(of: item.ignoreCase.wrappedValue) { (_, newValue) in
                                guard self.selection.contains(item.id) else { return }
                                $items
                                    .filter(with: self.selection)
                                    .filter { $0.id != item.id }
                                    .forEach { $0.ignoreCase.wrappedValue = newValue }
                            }
                    }
                }
                .width(24)
                .alignment(.center)
                
                TableColumn(String(localized: "Begin String", table: "SyntaxEditor", comment: "table column header"), value: \.begin) { wrappedItem in
                    if let item = $items[id: wrappedItem.id] {
                        RegexTextField(text: item.begin, showsError: true)
                            .regexHighlighted(item.isRegularExpression.wrappedValue)
                            .style(.table)
                            .focused($focusedField, equals: item.id)
                    }
                }
                
                TableColumn(String(localized: "End String", table: "SyntaxEditor", comment: "table column header"), sortUsing: KeyPathComparator(\.end)) { wrappedItem in
                    if let item = $items[id: wrappedItem.id] {
                        RegexTextField(text: item.end ?? "", showsError: true)
                            .regexHighlighted(item.isRegularExpression.wrappedValue)
                            .style(.table)
                    }
                }
                
                TableColumn(String(localized: "Description", table: "SyntaxEditor", comment: "table column header"), sortUsing: KeyPathComparator(\.description)) { wrappedItem in
                    if let item = $items[id: wrappedItem.id] {
                        TextField(text: item.description ?? "", label: EmptyView.init)
                    }
                }
            }
            .onChange(of: self.sortOrder) { (_, newValue) in
                self.items.sort(using: newValue)
            }
            .tableStyle(.bordered)
            .border(Color(nsColor: .gridColor))
            
            HStack {
                AddRemoveButton($items, selection: $selection, focus: $focusedField, newItem: Item.init)
                Spacer()
                HelpLink(anchor: self.helpAnchor)
            }
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var items: [SyntaxObject.Highlight] = [
        .init(begin: "(inu)", end: "(dog)"),
        .init(begin: "[Cc]at", end: "$0", isRegularExpression: true, description: "note"),
        .init(begin: "[]", isRegularExpression: true, ignoreCase: true),
    ]
    
    return SyntaxHighlightEditView(items: $items)
        .padding()
}
