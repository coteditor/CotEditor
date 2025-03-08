//
//  SyntaxFileMappingEditView.swift
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

struct SyntaxFileMappingEditView: View {
    
    @Binding var extensions: [SyntaxObject.KeyString]
    @Binding var filenames: [SyntaxObject.KeyString]
    @Binding var interpreters: [SyntaxObject.KeyString]
    
    
    // MARK: View
    
    var body: some View {
        
        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 20) {
            GridRow {
                EditTable($extensions) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Extensions:", tableName: "SyntaxEditor", comment: "label for file extensions")
                        Text("(without dot)", tableName: "SyntaxEditor", comment: "additional label to “Extensions:”")
                            .fontWeight(.regular)
                            .foregroundStyle(.secondary)
                    }
                }
                
                EditTable($filenames) {
                    Text("Filenames:", tableName: "SyntaxEditor", comment: "label")
                }
            }
            
            GridRow {
                EditTable($interpreters) {
                    Text("Interpreters:", tableName: "SyntaxEditor", comment: "label")
                }
                
                VStack {
                    Text("The interpreters are used to determine the syntax from the shebang in the document.", tableName: "SyntaxEditor", comment: "description")
                        .controlSize(.small)
                        .padding(.top, 18)
                    Spacer()
                    HStack {
                        Spacer()
                        HelpLink(anchor: "syntax_file_mapping")
                    }
                }
            }
        }
    }
    
    
    struct EditTable<Label: View>: View {
        
        typealias Item = SyntaxObject.KeyString
        
        
        @Binding var items: [Item]
        var label: () -> Label
        
        @State private var selection: Set<Item.ID> = []
        @FocusState private var focusedField: Item.ID?
        
        
        init(_ items: Binding<[Item]>, @ViewBuilder label: @escaping () -> Label) {
            
            self._items = items
            self.label = label
        }
        
        
        var body: some View {
            
            VStack(alignment: .leading) {
                self.label()
                    .accessibilityAddTraits(.isHeader)
                
                List(selection: $selection) {
                    ForEach($items) {
                        TextField(text: $0.string, label: EmptyView.init)
                            .focused($focusedField, equals: $0.id)
                    }
                    .onMove { (indexes, index) in
                        withAnimation {
                            self.items.move(fromOffsets: indexes, toOffset: index)
                        }
                    }
                }
                .alternatingRowBackgrounds()
                .listStyle(.bordered)
                .border(Color(nsColor: .gridColor))
                
                AddRemoveButton($items, selection: $selection, focus: $focusedField, newItem: Item.init)
            }.accessibilityElement(children: .contain)
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var extensions: [SyntaxObject.KeyString] = [.init(string: "abc")]
    @Previewable @State var filenames: [SyntaxObject.KeyString] = []
    @Previewable @State var interpreters: [SyntaxObject.KeyString] = []
    
    return SyntaxFileMappingEditView(extensions: $extensions,
                                     filenames: $filenames,
                                     interpreters: $interpreters)
    .padding()
}
