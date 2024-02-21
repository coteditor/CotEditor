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

struct SyntaxCompletionEditView: View {
    
    typealias Item = SyntaxDefinition.KeyString
    
    
    @Binding var completions: [Item]
    
    @State private var selection: Set<Item.ID> = []
    @FocusState private var focusedField: Item.ID?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("If not specified, the completion list is generated based on the highlighting settings.", tableName: "SyntaxEdit", comment: "message")
                .controlSize(.small)
            
            Table($completions, selection: $selection) {
                TableColumn(String(localized: "Completion", table: "SyntaxEdit", comment: "table column header")) { item in
                    TextField(text: item.string, label: EmptyView.init)
                        .focused($focusedField, equals: item.id)
                }
            }
            .tableStyle(.bordered)
            .border(Color(nsColor: .gridColor))
            
            HStack {
                AddRemoveButton($completions, selection: $selection, focus: $focusedField)
                Spacer()
                HelpButton(anchor: "syntax_highlight_settings")
            }
        }
    }
}



// MARK: - Preview

#Preview {
    @State var items: [SyntaxDefinition.KeyString] = [.init(string: "abc")]
    
    return SyntaxCompletionEditView(completions: $items)
        .padding()
}
