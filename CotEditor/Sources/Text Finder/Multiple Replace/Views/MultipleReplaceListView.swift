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
import UniformTypeIdentifiers

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
    @State private var importingError: ImportDuplicationError?
    @State private var error: (any Error)?
    
    
    var body: some View {
        
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
        }
        .modifier { content in
            if #available(macOS 26, *) {
                content
                    .safeAreaBar(edge: .bottom) {
                        self.bottomAccessoryView
                    }
                    .scrollEdgeEffectStyle(.hard, for: .bottom)
            } else {
                content
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        self.bottomAccessoryView
                    }
            }
        }
        .contextMenu(forSelectionType: String.self) { selections in
            if let selection = selections.first {
                self.menu(for: selection, isContext: true)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Sidebar", table: "MultipleReplace", comment: "accessibility label"))
        .onReceive(self.manager.$settingNames) { self.settingNames = $0 }
        .onAppear {
            // separate from `.onChange(of: self.settingNames.isEmpty)`
            // to avoid evaluating before initializing settingNames
            if self.settingNames.isEmpty {
                self.createUntitledSetting()
            }
        }
        .onChange(of: self.settingNames.isEmpty) { _, newValue in
            if newValue {
                self.createUntitledSetting()
            }
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.cotReplacement, .tabSeparatedText], allowsMultipleSelection: true) { result in
            switch result {
                case .success(let urls):
                    for url in urls {
                        let accessing = url.startAccessingSecurityScopedResource()
                        defer {
                            if accessing { url.stopAccessingSecurityScopedResource() }
                        }
                        
                        let name = url.deletingPathExtension().lastPathComponent
                        let type = UTType(filenameExtension: url.pathExtension)
                        do {
                            let data = try Data(contentsOf: url)
                            try self.manager.importSetting(data: data, name: name, type: type, overwrite: false)
                        } catch let error as ImportDuplicationError {
                            self.importingError = error
                            self.isImportConfirmationPresented = true
                            return
                        } catch {
                            self.error = error
                            return
                        }
                        self.selection = name
                    }
                case .failure(let error):
                    self.error = error
            }
        }
        .fileDialogMessage(String(localized: "FileImporter.message",
                                  defaultValue: "Choose CotEditor Replace Definition or TSV (Tab-separated values) files.", table: "MultipleReplace",
                                  comment: "CotEditor Replace Definition is a proper file type name. Refer to InfoPlist.xcstrings."))
        .fileDialogConfirmationLabel(String(localized: "Action.import.label", defaultValue: "Import"))
        .confirmationDialog(String(localized: "ImportDuplicationError.description",
                                   defaultValue: "“\(self.importingError?.name ?? String(localized: .unknown))” already exists. Do you want to replace it?",
                                   comment: "%@ is a name of a setting. Refer to the same expression by Apple."),
                            isPresented: $isImportConfirmationPresented, presenting: self.importingError) { item in
            Button(String(localized: "Action.replace.label", defaultValue: "Replace")) {
                self.importingError = nil
                do {
                    try self.manager.importSetting(data: item.data, name: item.name, overwrite: true)
                } catch {
                    self.error = error
                }
            }
            Button(.cancel, role: .cancel) {
                self.importingError = nil
            }
        } message: { error in
            Text(error.recoverySuggestion)
        }
        // place fileExporter after `fileDialogConfirmationLabel(_:)` for the import action to use the default label for the export.
        .fileExporter(isPresented: $isExporterPresented, item: self.exportingItem, contentTypes: [.cotReplacement], defaultFilename: self.exportingItem?.name) { result in
            switch result {
                case .success:
                    break
                case .failure(let error):
                    self.error = error
            }
        }
        .confirmationDialog(String(localized: "DeletionConfirmation.title",
                                   defaultValue: "Are you sure you want to delete “\(self.deletingItem ?? String(localized: .unknown))”?"),
                            isPresented: $isDeleteConfirmationPresented, presenting: self.deletingItem)
        { name in
            Button(String(localized: "Action.delete.label", defaultValue: "Delete"), role: .destructive) {
                self.deletingItem = nil
                do {
                    try self.manager.removeSetting(name: name)
                } catch {
                    self.error = error
                    return
                }
                self.selection = self.settingNames.first
            }
            Button(.cancel, role: .cancel) {
                self.deletingItem = nil
            }
        } message: { _ in
            Text(String(localized: "DeletionConfirmation.message",
                        defaultValue: "This action cannot be undone."))
        }
        .alert(error: $error)
    }
    
    
    /// The action buttons to place at the bottom of the list.
    @ViewBuilder private var bottomAccessoryView: some View {
        
        HStack {
            Button {
                self.createUntitledSetting()
            } label: {
                Image(systemName: "plus")
                    .accessibilityLabel(String(localized: "Action.add.label", defaultValue: "Add"))
                    .padding(2)
            }
            .help(String(localized: "Action.add.tooltip", defaultValue: "Add new item"))
            .frame(width: 16)
            
            Button {
                self.deletingItem = self.selection
                self.isDeleteConfirmationPresented = true
            } label: {
                Image(systemName: "minus")
                    .accessibilityLabel(String(localized: "Action.delete.label", defaultValue: "Delete"))
                    .padding(2)
            }
            .help(String(localized: "Action.delete.tooltip", defaultValue: "Delete selected items"))
            .frame(width: 16)
            
            Spacer()
            
            Menu {
                self.menu(for: self.selection)
            } label: {
                Image(systemName: "ellipsis")
                    .symbolVariant(.circle)
                    .accessibilityLabel(String(localized: "Button.actions.label", defaultValue: "Actions"))
            }
        }
        .buttonStyle(.borderless)
        .padding(6)
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
            
            // -> ShareLink in menu can't find the appropriate popover origin. (2025-08, macOS 26, FB19287270)
            if let url = self.manager.urlForUserSetting(name: selection) {
                ShareLink(item: url)
            }
        }
        
        if !isContext {
            Divider()
            
            Button(String(localized: "Action.import.ellipsis.label", defaultValue: "Import…"), systemImage: "square.and.arrow.down") {
                self.isImporterPresented = true
            }
            .modifierKeyAlternate(.option) {
                Button(String(localized: "Reload All Definitions", table: "MultipleReplace"), systemImage: "arrow.clockwise") {
                    Task {
                        await self.manager.invalidateUserSettings()
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
    
    
    init(name: String, data: @autoclosure @escaping @Sendable () -> Data?) {
        
        self.name = name
        self.data = data
    }
    
    
    static var transferRepresentation: some TransferRepresentation {
        
        DataRepresentation(exportedContentType: .cotReplacement) { item in
            guard let data = item.data() else { throw CocoaError(.fileNoSuchFile) }
            return data
        }
        .suggestedFileName(\.name)
        
        FileRepresentation(importedContentType: .cotReplacement) { received in
            let name = received.file.deletingPathExtension().lastPathComponent
            let data = try Data(contentsOf: received.file)
            return Self(name: name, data: data)
        }
    }
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 140, height: 300)) {
    @Previewable @State var selection: String?
    
    MultipleReplaceListView(selection: $selection, manager: .shared)
}
