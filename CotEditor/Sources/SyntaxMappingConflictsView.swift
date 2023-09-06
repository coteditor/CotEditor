//
//  SyntaxMappingConflictsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-06-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2023 1024jp
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



// MARK: - SwiftUI View

struct SyntaxMappingConflictsView: View {
    
    weak var parent: NSHostingController<Self>?
    
    private var extensionConflicts: [FileMappingConflict]
    private var filenameConflicts: [FileMappingConflict]
    private var interpreterConflicts: [FileMappingConflict]
    
    
    init(dictionary: [SyntaxKey: [String: [SyntaxManager.SettingName]]]) {
        
        self.extensionConflicts = dictionary[.extensions]?.map { .init(name: $0.key, syntaxes: $0.value) } ?? []
        self.filenameConflicts = dictionary[.filenames]?.map { .init(name: $0.key, syntaxes: $0.value) } ?? []
        self.interpreterConflicts = dictionary[.interpreters]?.map { .init(name: $0.key, syntaxes: $0.value) } ?? []
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            Text("Syntax Mapping Conflicts")
                .font(.headline)
            Text("The following file mapping rules are registered in multiple syntaxes. CotEditor uses the first syntax automatically. To resolve conflicts, edit each syntax definition.")
                .controlSize(.small)
            
            if !self.extensionConflicts.isEmpty {
                ConflictTable("Extension", conflicts: self.extensionConflicts)
            }
            if !self.filenameConflicts.isEmpty {
                ConflictTable("Filename", conflicts: self.filenameConflicts)
            }
            if !self.interpreterConflicts.isEmpty {
                ConflictTable("Interpreter", conflicts: self.interpreterConflicts)
            }
            
            HStack {
                HelpButton(anchor: "syntax_file_mapping")
                Spacer()
                Button("OK") {
                    self.parent?.dismiss(nil)
                }.keyboardShortcut(.defaultAction)
            }
        }
        .onExitCommand {
            self.parent?.dismiss(nil)
        }
        .scenePadding()
        .frame(width: 400, height: 500, alignment: .trailing)
    }
}


private struct ConflictTable: View {
    
    let name: LocalizedStringKey
    @State var conflicts: [FileMappingConflict] = []
    
    @State private var sortOrder = [KeyPathComparator(\FileMappingConflict.name)]
    
    
    init(_ name: LocalizedStringKey, conflicts: [FileMappingConflict]) {
        
        self.name = name
        self._conflicts = .init(wrappedValue: conflicts)
    }
    
    var body: some View {
        
        Section {
            Table(self.conflicts, sortOrder: $sortOrder) {
                TableColumn(self.name, value: \.name)
                TableColumn("Used syntax", value: \.primarySyntax) {
                    Text($0.primarySyntax).fontWeight(.semibold)
                }
                TableColumn("Duplicated syntaxes") {
                    Text($0.duplicatedSyntaxes, format: .list(type: .and, width: .narrow))
                }
            }
            .onChange(of: self.sortOrder) { newOrder in
                self.conflicts.sort(using: newOrder)
            }
            .tableStyle(.bordered)
            
        } header: {
            Text(self.name).fontWeight(.medium)
        }
    }
}


// MARK: - Preview

#Preview {
    SyntaxMappingConflictsView(dictionary: [
        .extensions: ["svg": ["SVG", "XML"]],
        .filenames: ["foo": ["SVG", "XML", "Foo"]],
    ])
}
