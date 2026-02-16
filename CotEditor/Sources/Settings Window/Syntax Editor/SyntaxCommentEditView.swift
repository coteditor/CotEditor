//
//  SyntaxCommentEditView.swift
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

struct SyntaxCommentEditView: View {
    
    @Binding var inlineComments: [SyntaxObject.InlineComment]
    @Binding var blockComments: [SyntaxObject.BlockComment]
    
    var canCustomizeParser: Bool = true
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
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
            .frame(maxHeight: 180)
            .padding(.bottom, 10)
            
            if self.canCustomizeParser {
                Text("The comment delimiters defined here are used for syntax highlighting as well.", tableName: "SyntaxEditor")
                    .controlSize(.small)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                HelpLink(anchor: "syntax_comment_settings")
            }
        }
    }
}


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
        
        AddRemoveButton($items, selection: $selection, newItem: Item()) { item in
            self.focusedField = item.id
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var inlineComments: [SyntaxObject.InlineComment] = [.init(value: .init(begin: "//"))]
    @Previewable @State var blockComments: [SyntaxObject.BlockComment] = [.init(value: Pair("/*", "*/"))]
    
    SyntaxCommentEditView(inlineComments: $inlineComments, blockComments: $blockComments)
        .padding()
}
