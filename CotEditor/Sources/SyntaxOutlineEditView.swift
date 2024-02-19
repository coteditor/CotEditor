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

struct SyntaxOutlineEditView: View {
    
    typealias Item = SyntaxDefinition.Outline
    
    
    @Binding var outlines: [Item]
    
    @State private var selection: Set<Item.ID> = []
    @FocusState private var focusedField: Item.ID?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Outline extraction rules", tableName: "SyntaxEdit", comment: "label")
            
            Table($outlines, selection: $selection) {
                TableColumn(String(localized: "IC", table: "SyntaxEdit", comment: "table column header (IC for Ignore Case)")) { item in
                    Toggle(isOn: item.ignoreCase, label: EmptyView.init)
                        .help(String(localized: "Ignore Case", table: "SyntaxEdit", comment: "tooltip for IC checkbox"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }.width(20)
                
                TableColumn(String(localized: "Regular Expression Pattern", table: "SyntaxEdit", comment: "table column header")) { item in
                    RegexTextField(text: item.pattern, showsError: true, showsInvisible: true)
                        .style(.table)
                        .focused($focusedField, equals: item.id)
                }
                
                TableColumn(String(localized: "Description", table: "SyntaxEdit", comment: "table column header")) { item in
                    TextField(text: item.description ?? "", label: EmptyView.init)
                }
            }
            .tableStyle(.bordered)
            .border(Color(nsColor: .gridColor))
            
            AddRemoveButton($outlines, selection: $selection, focus: $focusedField)
                .padding(.bottom, 8)
            
            if self.selection.count > 1 {
                PatternView(outline: .constant(.init()), error: .multipleSelection)
                    .disabled(true)
            } else if let selection = self.selection.first,
               let outline = $outlines.first(where: { $0.id == selection })
            {
                PatternView(outline: outline)
            } else {
                PatternView(outline: .constant(.init()), error: .noSelection)
                    .disabled(true)
            }
            
            HStack {
                Spacer()
                HelpButton(anchor: "syntax_outline_settings")
            }
        }
    }
    
    
    private struct PatternView: View {
        
        @Binding var outline: Item
        var error: SelectionError?
        
        
        var body: some View {
            
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Title pattern:", tableName: "SyntaxEdit", comment: "label")
                    Text("(Blank matches the whole string.)", tableName: "SyntaxEdit", comment: "label")
                        .controlSize(.small)
                        .foregroundColor(.secondary)
                }
                
                RegexTextField(text: $outline.template, mode: .replacement(unescapes: false), prompt: self.prompt)
                
                HStack {
                    Toggle(String(localized: "Bold", table: "SyntaxEdit", comment: "checkbox label"), isOn: $outline.bold)
                        .bold()
                    Toggle(String(localized: "Italic", table: "SyntaxEdit", comment: "checkbox label"), isOn: $outline.italic)
                        .italic()
                    Toggle(String(localized: "Underline", table: "SyntaxEdit", comment: "checkbox label"), isOn: $outline.underline)
                        .underline()
                }.controlSize(.small)
            }
        }
        
        
        private var prompt: String? {
            
            switch self.error {
                case .noSelection:
                    String(localized: "No item selected", table: "SyntaxEdit", comment: "placeholder")
                case .multipleSelection:
                    String(localized: "Multiple items selected", table: "SyntaxEdit", comment: "placeholder")
                case .none where self.outline.template.isEmpty:
                    String(localized: "Entire match", table: "SyntaxEdit", comment: "placeholder")
                case .none:
                    nil
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
    @State var outlines: [SyntaxDefinition.Outline] = [
        .init(pattern: "abc")
    ]
    
    return SyntaxOutlineEditView(outlines: $outlines)
        .padding()
}
