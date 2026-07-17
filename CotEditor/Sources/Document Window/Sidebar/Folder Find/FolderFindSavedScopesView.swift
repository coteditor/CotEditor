//
//  FolderFindSavedScopesView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-07-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

public import FolderFind
import SwiftUI
import StringUtils

struct FolderFindSavedScopesView: View {
    
    private struct EditingScope: Identifiable {
        
        var name: String
        var scope: FileScope
        
        var id: String  { self.name }
    }
    
    
    @Binding var scopes: [String: FileScope]
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selection: String?
    @State private var editingItem: EditingScope?
    @State private var deletingItem: String?
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Saved scopes:", tableName: "Document")
            
            List(selection: $selection) {
                ForEach(self.scopes.keys.sorted(using: .localizedStandard), id: \.self) { name in
                    Text(name)
                        .listRowSeparator(.hidden)
                }
            }
            .contextMenu(forSelectionType: String.self) { selections in
                if selections.count == 1, let selection = selections.first {
                    self.contextMenu(for: selection)
                }
            }
            .border(.separator)
            .frame(minWidth: 240, minHeight: 180)
            
            HStack {
                Button(String(localized: "Action.delete.label", defaultValue: "Delete"), systemImage: "minus") {
                    self.deletingItem = self.selection
                }
                .help(String(localized: "Action.delete.tooltip", defaultValue: "Delete selected items"))
                .labelStyle(.iconOnly)
                .disabled(self.selection == nil)
                
                Spacer()
                
                Button(String(localized: "Action.edit.ellipsis.label", defaultValue: "Edit…")) {
                    if let name = self.selection, let scope = self.scopes[name] {
                        self.editingItem = EditingScope(name: name, scope: scope)
                    }
                }
                .disabled(self.selection == nil)
                
                Button(role: .close) {
                    self.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .sheet(item: $editingItem) { item in
            FolderFindFileScopeView(fileScope: item.scope, name: item.name, savedScopes: $scopes) { _, name in
                self.selection = name
            }
            .scenePadding()
            .presentationSizing(.fitted)
        }
        .confirmationDialog(String(localized: "DeletionConfirmation.title",
                                   defaultValue: "Are you sure you want to delete “\(self.deletingItem ?? String(localized: .unknown))”?"),
                            item: $deletingItem)
        { name in
            Button(String(localized: "Action.delete.label", defaultValue: "Delete"), role: .destructive) {
                self.scopes[name] = nil
                self.selection = nil
            }
        } message: { _ in
            Text(String(localized: "DeletionConfirmation.message",
                        defaultValue: "This action cannot be undone."))
        }
    }
    
    
    /// Builds the context menu for the list item.
    ///
    /// - Parameter name: The name of the selected item.
    /// - Returns: The context menu content.
    @ContentBuilder private func contextMenu(for name: String) -> some View {
        
        Button(String(localized: "Action.duplicate.label", defaultValue: "Duplicate"), systemImage: "plus.square.on.square") {
            self.duplicateScope(name)
        }
        
        Button(String(localized: "Action.delete.label", defaultValue: "Delete"), systemImage: "trash") {
            self.deletingItem = name
        }
    }
    
    
    /// Duplicates the saved scope under a unique name.
    ///
    /// - Parameter name: The name of the scope to duplicate.
    private func duplicateScope(_ name: String) {
        
        guard let scope = self.scopes[name] else { return }
        
        let newName = name.appendingUniqueNumber(in: self.scopes.keys)
        
        self.scopes[newName] = scope
        self.selection = newName
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var scopes: [String: FileScope] = [
        "Swift": FileScope(rules: [.init(target: .fileExtension, comparison: .isEqualTo, value: "swift")]),
        "No Builds": FileScope(rules: [.init(target: .filePath, comparison: .doesNotContain, value: "build")]),
    ]
    
    FolderFindSavedScopesView(scopes: $scopes)
        .scenePadding()
}
