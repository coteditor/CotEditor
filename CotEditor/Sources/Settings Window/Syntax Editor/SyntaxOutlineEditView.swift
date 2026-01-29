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
import RegexHighlighting
import Syntax

struct SyntaxOutlineEditView: View {
    
    typealias Item = SyntaxObject.Outline
    
    
    @Binding var items: [Item]
    
    @State private var selection: Set<Item.ID> = []
    @FocusState private var focusedField: Item.ID?
    
    
    // MARK: View
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Table($items, selection: $selection) {
                TableColumn(String(localized: "IC", table: "SyntaxEditor", comment: "table column header (IC for Ignore Case)")) { $item in
                    Toggle(isOn: $item.value.ignoreCase, label: EmptyView.init)
                        .help(String(localized: "Ignore Case", table: "SyntaxEditor", comment: "tooltip for IC checkbox"))
                }
                .width(24)
                .alignment(.center)
                
                TableColumn(String(localized: "Kind", table: "SyntaxEditor", comment: "table column header")) { $item in
                    Picker(String(localized: "Kind", table: "SyntaxEditor"), selection: $item.value.kind) {
                        Label {
                            Text("None", tableName: "SyntaxEditor")
                        } icon: {
                            Image(systemName: "square")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tertiary)
                        }
                        .tag(Optional<Syntax.Outline.Kind>.none)
                        
                        Divider()
                        
                        ForEach(Syntax.Outline.Kind.allCases, id: \.self) { kind in
                            Label {
                                Text(kind.label)
                            } icon: {
                                kind.icon(mode: .palette)  // workaround
                            }
                            .tag(Optional(kind))
                        }
                    } currentValueLabel: {
                        if let selection = item.value.kind {
                            selection.icon(mode: .palette)  // workaround
                        } else {
                            Image(systemName: "square")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .labelsHidden()
                    .buttonStyle(.borderless)
                }
                .width(40)
                
                TableColumn(String(localized: "Regular Expression Pattern", table: "SyntaxEditor", comment: "table column header")) { $item in
                    HStack {
                        RegexTextField(text: $item.value.pattern)
                            .style(.table)
                            .focused($focusedField, equals: item.id)
                        if (try? NSRegularExpression(pattern: item.value.pattern)) == nil {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .symbolRenderingMode(.multicolor)
                                .help(Syntax.Error.Code.regularExpression.localizedDescription)
                        }
                    }
                }
                .width(min: 180, ideal: 240)
                
                TableColumn(String(localized: "Display Pattern", table: "SyntaxEditor", comment: "table column header")) { $item in
                    RegexTextField(text: $item.value.template,
                                   mode: .replacement(unescapes: false),
                                   prompt: (item.value.kind == .separator) ? "–" : String(localized: "Entire match", table: "SyntaxEditor", comment: "placeholder for outline item table"))
                    .style(.table)
                    .disabled(item.value.kind == .separator)
                }
                .width(min: 40, ideal: 140)
                
                TableColumn(String(localized: "Description", table: "SyntaxEditor", comment: "table column header")) { $item in
                    TextField(text: $item.value.description ?? "", label: EmptyView.init)
                }
                .width(min: 40, ideal: 100)
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
            
            HStack {
                Spacer()
                HelpLink(anchor: "syntax_outline_settings")
            }
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var items: [SyntaxObject.Outline] = [
        .init(value: .init(pattern: "abc")),
        .init(value: .init(pattern: "def", ignoreCase: true, kind: .heading)),
    ]
    
    SyntaxOutlineEditView(items: $items)
        .padding()
}
