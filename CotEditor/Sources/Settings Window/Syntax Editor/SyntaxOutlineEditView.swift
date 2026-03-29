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
import SyntaxFormat

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
                    OutlineKindMenu(kind: $item.value.kind)
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
                    let isSeparator = (item.value.kind == .separator)
                    
                    RegexTextField(
                        text: isSeparator ? .constant("") : $item.value.template,
                        mode: .replacement(unescapes: false),
                        prompt: isSeparator
                            ? "–"
                            : String(localized: "Entire match", table: "SyntaxEditor", comment: "placeholder for outline item table")
                    )
                    .style(.table)
                    .disabled(isSeparator)
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
                ItemCountView(count: self.items.count)
            }
            
            HStack {
                Spacer()
                HelpLink(anchor: "syntax_outline_settings")
            }
        }
        .scenePadding()
    }
}


// MARK: - Outline Kind Menu

private struct OutlineKindMenu: View {
    
    @Binding var kind: Syntax.Outline.Kind?
    
    
    var body: some View {
        
        Menu {
            Button {
                self.kind = nil
            } label: {
                Label {
                    Text("None", tableName: "SyntaxEditor")
                } icon: {
                    Image(systemName: "square")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Divider()
            
            ForEach(Syntax.Outline.Kind.allCases, id: \.self) { kind in
                if kind == .heading(nil) {
                    Menu {
                        Button(Syntax.Outline.Kind.heading(nil).label) {
                            self.kind = .heading(nil)
                        }
                        
                        Divider()
                        
                        ForEach(Syntax.Outline.Kind.levelRange, id: \.self) { level in
                            Button(Syntax.Outline.Kind.heading(level).label) {
                                self.kind = .heading(level)
                            }
                            .monospacedDigit()
                        }
                    } label: {
                        Label {
                            Text(Syntax.Outline.Kind.heading(nil).label)
                        } icon: {
                            Syntax.Outline.Kind.heading(nil).icon(mode: .palette)
                        }
                    }
                } else {
                    if kind == .separator {
                        Divider()
                    }
                    Button {
                        self.kind = kind
                    } label: {
                        Label {
                            Text(kind.label)
                        } icon: {
                            kind.icon(mode: .palette)
                        }
                    }
                }
            }
        } label: {
            if let selection = self.kind {
                selection.icon(mode: .palette)
                    .accessibilityLabel(selection.label)
            } else {
                Image(systemName: "square")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.tertiary)
            }
        }
        .menuStyle(.borderlessButton)
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var items: [SyntaxObject.Outline] = [
        .init(value: .init(pattern: "abc")),
        .init(value: .init(pattern: "def", ignoreCase: true, kind: .heading(nil))),
    ]
    
    SyntaxOutlineEditView(items: $items)
}
