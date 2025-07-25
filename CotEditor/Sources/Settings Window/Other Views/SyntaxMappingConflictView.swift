//
//  SyntaxMappingConflictView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-06-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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

private struct FileMappingConflict: Identifiable {
    
    let id = UUID()
    
    var name: String
    var primarySyntax: String
    var duplicatedSyntaxes: [String]
    
    
    init(name: String, syntaxes: [String]) {
        
        self.name = name
        self.primarySyntax = syntaxes[0]
        self.duplicatedSyntaxes = Array(syntaxes[1...])
    }
}


struct SyntaxMappingConflictView: View {
    
    var dismiss: () -> Void = { }
    
    private var extensionConflicts: [FileMappingConflict]
    private var filenameConflicts: [FileMappingConflict]
    private var interpreterConflicts: [FileMappingConflict]
    
    
    init(table: SyntaxManager.MappingTable) {
        
        self.extensionConflicts = table[\.extensions]?.map { .init(name: $0.key, syntaxes: $0.value) } ?? []
        self.filenameConflicts = table[\.filenames]?.map { .init(name: $0.key, syntaxes: $0.value) } ?? []
        self.interpreterConflicts = table[\.interpreters]?.map { .init(name: $0.key, syntaxes: $0.value) } ?? []
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            Text("Syntax Mapping Conflicts", tableName: "SyntaxMappingConflict", comment: "heading")
                .font(.headline)
                .accessibilityHeading(.h1)
            Text("The following file mapping rules are registered in multiple syntaxes. CotEditor uses the first syntax automatically. To resolve conflicts, edit each syntax definition.", tableName: "SyntaxMappingConflict")
                .controlSize(.small)
            
            if !self.extensionConflicts.isEmpty {
                ConflictTable(String(localized: "Extension", table: "SyntaxMappingConflict", comment: "heading"), items: self.extensionConflicts)
            }
            if !self.filenameConflicts.isEmpty {
                ConflictTable(String(localized: "Filename", table: "SyntaxMappingConflict", comment: "heading"), items: self.filenameConflicts)
            }
            if !self.interpreterConflicts.isEmpty {
                ConflictTable(String(localized: "Interpreter", table: "SyntaxMappingConflict", comment: "heading"), items: self.interpreterConflicts)
            }
            
            HStack {
                HelpLink(anchor: "syntax_file_mapping")
                Spacer()
                Button(.ok) {
                    self.dismiss()
                }.keyboardShortcut(.defaultAction)
            }
        }
        .onExitCommand {
            self.dismiss()
        }
        .scenePadding()
        .frame(width: 400, height: 500)
    }
}


private struct ConflictTable: View {
    
    typealias Item = FileMappingConflict
    
    var name: String
    @State var items: [Item]
    
    @State private var selection: Item.ID?
    @State private var sortOrder = [KeyPathComparator(\Item.name)]
    
    
    init(_ name: String, items: [Item]) {
        
        self.name = name
        self.items = items
    }
    
    
    var body: some View {
        
        Section {
            Table(self.items, selection: $selection, sortOrder: $sortOrder) {
                TableColumn(self.name, value: \.name)
                TableColumn(String(localized: "Used syntax", table: "SyntaxMappingConflict", comment: "table column header"), value: \.primarySyntax) {
                    Text($0.primarySyntax).fontWeight(.semibold)
                }
                TableColumn(String(localized: "Duplicated syntaxes", table: "SyntaxMappingConflict", comment: "table column header"), sortUsing: KeyPathComparator(\.duplicatedSyntaxes.first)) {
                    Text($0.duplicatedSyntaxes, format: .list(type: .and, width: .narrow))
                }
            }
            .onChange(of: self.sortOrder) { _, newValue in
                self.items.sort(using: newValue)
            }
            .tableStyle(.bordered)
            
        } header: {
            Text(self.name).fontWeight(.medium)
        }
    }
}


// MARK: - Preview

#Preview {
    SyntaxMappingConflictView(table: [
        \.extensions: ["svg": ["SVG", "XML"]],
        \.filenames: ["foo": ["SVG", "XML", "Foo"]],
    ])
}
