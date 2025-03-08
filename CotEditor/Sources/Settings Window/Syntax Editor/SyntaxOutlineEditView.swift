//
//  SyntaxOutlineEditView.swift
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

struct SyntaxOutlineEditView: View {
    
    typealias Item = SyntaxObject.Outline
    
    
    @Binding var items: [Item]
    
    @State private var selection: Set<Item.ID> = []
    @FocusState private var focusedField: Item.ID?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Outline extraction rules:", tableName: "SyntaxEditor", comment: "label")
            
            Table($items, selection: $selection) {
                TableColumn(String(localized: "IC", table: "SyntaxEditor", comment: "table column header (IC for Ignore Case)")) { item in
                    Toggle(isOn: item.ignoreCase, label: EmptyView.init)
                        .help(String(localized: "Ignore Case", table: "SyntaxEditor", comment: "tooltip for IC checkbox"))
                }
                .width(24)
                .alignment(.center)
                
                TableColumn(String(localized: "Regular Expression Pattern", table: "SyntaxEditor", comment: "table column header")) { item in
                    RegexTextField(text: item.pattern, showsError: true)
                        .style(.table)
                        .focused($focusedField, equals: item.id)
                }
                
                TableColumn(String(localized: "Description", table: "SyntaxEditor", comment: "table column header")) { item in
                    TextField(text: item.description ?? "", label: EmptyView.init)
                }
            }
            .tableStyle(.bordered)
            .border(Color(nsColor: .gridColor))
            
            AddRemoveButton($items, selection: $selection, focus: $focusedField, newItem: Item.init)
                .padding(.bottom, 8)
            
            if self.selection.count > 1 {
                PatternView(outline: .constant(.init()), error: .multipleSelection)
            } else if let outline = $items[id: self.selection.first] {
                PatternView(outline: outline)
            } else {
                PatternView(outline: .constant(.init()), error: .noSelection)
            }
            
            HStack {
                Spacer()
                HelpLink(anchor: "syntax_outline_settings")
            }
        }
    }
    
    
    private struct PatternView: View {
        
        @Binding var outline: Item
        var error: SelectionError?
        
        @Namespace private var accessibility
        
        
        var body: some View {
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Title pattern:", tableName: "SyntaxEditor", comment: "label")
                        .accessibilityLabeledPair(role: .label, id: "titlePattern", in: self.accessibility)
                    Text("(Blank matches the whole string.)", tableName: "SyntaxEditor", comment: "label")
                        .controlSize(.small)
                        .foregroundStyle(.secondary)
                }
                
                RegexTextField(text: $outline.template, mode: .replacement(unescapes: false), prompt: self.prompt)
                    .accessibilityLabeledPair(role: .content, id: "titlePattern", in: self.accessibility)
                
                HStack(alignment: .firstTextBaseline) {
                    Toggle(String(localized: "Bold", table: "SyntaxEditor", comment: "checkbox label"), isOn: $outline.bold)
                        .bold()
                    Toggle(String(localized: "Italic", table: "SyntaxEditor", comment: "checkbox label"), isOn: $outline.italic)
                        .italic()
                    Toggle(String(localized: "Underline", table: "SyntaxEditor", comment: "checkbox label"), isOn: $outline.underline)
                        .underline()
                }.controlSize(.small)
            }.disabled(self.error != nil)
        }
        
        
        private var prompt: String {
            
            switch self.error {
                case .noSelection:
                    String(localized: "No item selected", table: "SyntaxEditor",
                           comment: "message for uneditable condition")
                case .multipleSelection:
                    String(localized: "Multiple items selected", table: "SyntaxEditor",
                           comment: "message for uneditable condition")
                case .none:
                    String(localized: "Entire match", table: "SyntaxEditor",
                           comment: "placeholder for outline item table")
            }
        }
    }
}


enum SelectionError: Error {
    
    case noSelection
    case multipleSelection
}


// MARK: - Preview

#Preview {
    @Previewable @State var items: [SyntaxObject.Outline] = [
        .init(pattern: "abc"),
        .init(pattern: "def", ignoreCase: true, italic: true),
    ]
    
    return SyntaxOutlineEditView(items: $items)
        .padding()
}
