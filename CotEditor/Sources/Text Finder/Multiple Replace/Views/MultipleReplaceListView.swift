//
//  MultipleReplaceListView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2025 1024jp
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

struct MultipleReplaceListView: View {
    
    @Binding var selection: String?
    var manager: ReplacementManager = .shared
    
    
    @State private var settingNames: [String] = []
    @State private var exportingItem: TransferableReplacement?
    @State private var deletingItem: String?
    @FocusState private var editingItem: String?
    
    @State private var isExporterPresented = false
    @State private var isImporterPresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var isImportConfirmationPresented = false
    @State private var importingError: SettingImportError?
    @State private var error: (any Error)?
    
    
    var body: some View {
        
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(self.settingNames, id: \.self) { name in
                    SettingNameField(text: name) { newName in
                        do {
                            try self.manager.renameSetting(name: name, to: newName)
                        } catch {
                            self.error = error
                            return false
                        }
                        self.selection = newName
                        return true
                    }
                    .focused($editingItem, equals: name)
                    .draggable(TransferableReplacement(name: name, data: self.manager.dataForUserSetting(name: name))) {
                        Label {
                            Text(name)
                        } icon: {
                            Image(nsImage: NSWorkspace.shared.icon(for: .cotReplacement))
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
            .contextMenu(forSelectionType: String.self) { selections in
                if let selection = selections.first {
                    self.menu(for: selection, isContext: true)
                }
            }
            .listStyle(.sidebar)
            
            HStack {
                Button {
                    self.createUntitledSetting()
                } label: {
                    Label(String(localized: "Button.add.label", defaultValue: "Add", table: "Control"), systemImage: "plus")
                        .padding(2)
                }
                .frame(width: 16)
                
                Button {
                    self.deletingItem = self.selection
                    self.isDeleteConfirmationPresented = true
                } label: {
                    Label(String(localized: "Button.remove.label", defaultValue: "Remove", table: "Control"), systemImage: "minus")
                        .padding(2)
                }
                .frame(width: 16)
                
                Spacer()
                
                Menu(String(localized: "Button.actions.label", defaultValue: "Actions", comment: "label for action menu button"), systemImage: "ellipsis") {
                    if #unavailable(macOS 26) {
                        self.menu(for: self.selection)
                            .labelStyle(.titleOnly)
                    } else {
                        self.menu(for: self.selection)
                    }
                }
                .symbolVariant(.circle)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .padding(6)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Sidebar", table: "MultipleReplace", comment: "accessibility label"))
        .onReceive(self.manager.$settingNames) { settingNames in
            self.settingNames = settingNames
        }
        .onAppear {
            // separate from `.onChange(of: self.settingNames.isEmpty)`
            // to avoid evaluating before initializing settingNames
            if self.settingNames.isEmpty {
                self.createUntitledSetting()
            }
        }
        .onChange(of: self.settingNames.isEmpty) { (_, newValue) in
            if newValue {
                self.createUntitledSetting()
            }
        }
        .fileExporter(isPresented: $isExporterPresented, item: self.exportingItem, contentTypes: [.cotReplacement], defaultFilename: self.exportingItem?.name) { result in
            switch result {
                case .success:
                    break
                case .failure(let error):
                    self.error = error
            }
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.cotReplacement], allowsMultipleSelection: true) { result in
            switch result {
                case .success(let urls):
                    for url in urls {
                        let accessing = url.startAccessingSecurityScopedResource()
                        defer {
                            if accessing {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                        
                        let name = url.deletingPathExtension().lastPathComponent
                        do {
                            let data = try Data(contentsOf: url)
                            try self.manager.importSetting(data: data, name: name, overwrite: false)
                        } catch let error as SettingImportError {
                            self.importingError = error
                            self.isImportConfirmationPresented = true
                        } catch {
                            self.error = error
                        }
                    }
                case .failure(let error):
                    self.error = error
            }
        }
        .fileDialogConfirmationLabel(String(localized: "Button.import.label", defaultValue: "Import"))
        .confirmationDialog(String(localized: "ImportDuplicationError.description",
                                   defaultValue: "“\(self.importingError?.name ?? String(localized: .unknown))” already exists. Do you want to replace it?",
                                   comment: "%@ is a name of a setting. Refer the same expression by Apple."),
                            isPresented: $isImportConfirmationPresented, presenting: self.importingError) { item in
            Button(String(localized: "Button.replace.label", defaultValue: "Replace")) {
                self.importingError = nil
                do {
                    try self.manager.importSetting(data: item.data, name: item.name, overwrite: true)
                } catch {
                    self.error = error
                }
            }
            Button("Cancel", role: .cancel) {
                self.importingError = nil
            }
        } message: { _ in
            Text(String(localized: "ImportDuplicationError.recoverySuggestion",
                        defaultValue: "A custom setting with the same name already exists. Replacing it will overwrite its current contents.",
                        comment: "Refer similar expressions by Apple."))
        }
        .confirmationDialog(String(localized: "DeletionConfirmationAlert.message",
                                   defaultValue: "Are you sure you want to delete “\(self.deletingItem ?? String(localized: .unknown))”?"),
                            isPresented: $isDeleteConfirmationPresented, presenting: self.deletingItem)
        { name in
            Button(String(localized: "DeletionConfirmationAlert.button.delete", defaultValue: "Delete"), role: .destructive) {
                self.deletingItem = nil
                do {
                    try self.manager.removeSetting(name: name)
                } catch {
                    self.error = error
                    return
                }
                self.selection = self.settingNames.first
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                self.deletingItem = nil
            }
        } message: { _ in
            Text(String(localized: "DeletionConfirmationAlert.informativeText",
                        defaultValue: "This action cannot be undone."))
        }
        .alert(error: $error)
    }
    
    
    /// Builds menu items for either the Action menu button or the context menu.
    ///
    /// - Parameters:
    ///   - selection: The action target.
    ///   - isContext: Whether the items are for the context menu.
    /// - Returns: Menu items.
    @ViewBuilder private func menu(for selection: String?, isContext: Bool = false) -> some View {
        
        if let selection {
            Button(isContext
                   ? String(localized: "Action.duplicate.label", defaultValue: "Duplicate")
                   : String(localized: "Action.duplicate.named.label", defaultValue: "Duplicate “\(selection)”"),
                   systemImage: "plus.square.on.square")
            {
                do {
                    try self.manager.duplicateSetting(name: selection)
                } catch {
                    self.error = error
                }
            }
            
            Button(isContext
                   ? String(localized: "Action.rename.label", defaultValue: "Rename")
                   : String(localized: "Action.rename.named.label", defaultValue: "Rename “\(selection)”"),
                   systemImage: "pencil")
            {
                self.editingItem = selection
            }
            
            if isContext {
                Button(String(localized: "Action.delete.label", defaultValue: "Delete"), systemImage: "trash") {
                    self.deletingItem = selection
                    self.isDeleteConfirmationPresented = true
                }
            }
            
            Button(isContext
                   ? String(localized: "Action.export.label", defaultValue: "Export…")
                   : String(localized: "Action.export.named.label", defaultValue: "Export “\(selection)”…"),
                   systemImage: "square.and.arrow.up")
            {
                self.exportingItem = TransferableReplacement(name: selection, data: self.manager.dataForUserSetting(name: selection))
                self.isExporterPresented = true
            }
            .modifierKeyAlternate(.option) {
                Button(isContext
                       ? String(localized: "Action.revealInFinder.label", defaultValue: "Reveal in Finder")
                       : String(localized: "Action.revealInFinder.named.label", defaultValue: "Reveal “\(selection)” in Finder"),
                       systemImage: "finder")
                {
                    guard let url = self.manager.urlForUserSetting(name: selection) else { return }
                    
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
            
            if let url = self.manager.urlForUserSetting(name: selection) {
                // -> ShareLink doesn't work for context menu. (macOS 26, 2025-06)
                if !isContext {
                    if #available(macOS 26, *) {
                        ShareLink(item: url)
                    } else {
                        ShareLink(item: url) {
                            Text(String(localized: "Action.share.label", defaultValue: "Share…"))
                        }
                    }
                }
            }
        }
        
        if !isContext {
            Divider()
            
            Button(String(localized: "Action.import.label", defaultValue: "Import…"), systemImage: "square.and.arrow.down") {
                self.isImporterPresented = true
            }
            .modifierKeyAlternate(.option) {
                Button(String(localized: "Reload All Definitions", table: "MultipleReplace"), systemImage: "arrow.clockwise") {
                    Task.detached(priority: .utility) {
                        self.manager.loadUserSettings()
                    }
                }
            }
        }
    }
    
    
    /// Creates an empty untitled setting.
    private func createUntitledSetting() {
        
        do {
            self.selection = try self.manager.createUntitledSetting()
        } catch {
            self.error = error
        }
    }
}


private struct TransferableReplacement: Transferable {
    
    var name: String
    var data: @Sendable () -> Data?
    
    
    init(name: String, data: @autoclosure @Sendable @escaping () -> Data?) {
        
        self.name = name
        self.data = data
    }
    
    
    static var transferRepresentation: some TransferRepresentation {
        
        DataRepresentation(exportedContentType: .cotReplacement) { item in
            guard let data = item.data() else { throw CocoaError(.fileNoSuchFile) }
            return data
        }
        .suggestedFileName { $0.name }
        
        FileRepresentation(importedContentType: .cotReplacement) { received in
            let name = received.file.deletingPathExtension().lastPathComponent
            let data = try Data(contentsOf: received.file)
            return TransferableReplacement(name: name, data: data)
        }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var selection: String?
    
    MultipleReplaceListView(selection: $selection, manager: .shared)
}
