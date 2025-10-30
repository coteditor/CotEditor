//
//  FormatSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-11-29.
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
import UniformTypeIdentifiers
import Defaults
import FileEncoding
import LineEnding

@MainActor @objc protocol EncodingsListHolder: AnyObject {
    
    func showEncodingsListView(_ sender: Any?)
}


struct FormatSettingsView: View {
    
    @Namespace private var accessibility
    
    @AppStorage(.lineEndCharCode) private var lineEnding
    
    @AppStorage(.encoding) private var encoding
    @AppStorage(.saveUTF8BOM) private var saveUTF8BOM
    @AppStorage(.referToEncodingTag) private var referToEncodingTag
    
    @AppStorage(.syntax) private var syntax
    
    private var syntaxManager: SyntaxManager = .shared
    
    @State private var encodingManager: EncodingManager = .shared
    @State private var syntaxNames: [String] = []
    
    
    private var fileEncoding: Binding<FileEncoding> {
        
        Binding(
            get: {
                FileEncoding(encoding: String.Encoding(rawValue: UInt(self.encoding)),
                             withUTF8BOM: self.saveUTF8BOM)
            },
            set: {
                self.encoding = Int($0.encoding.rawValue)
                self.saveUTF8BOM = $0.withUTF8BOM
            })
    }
    
    @State private var isEncodingListPresented = false
    
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                Text("Default line endings:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "lineEnding", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                Picker(selection: $lineEnding) {
                    ForEach(LineEnding.allCases.filter(\.isBasic), id: \.self) {
                        Text(verbatim: "\($0.description) (\($0.label))")
                            .tag($0.index)
                    }
                } label: {
                    EmptyView()
                }
                .fixedSize()
                .accessibilityLabeledPair(role: .content, id: "lineEnding", in: self.accessibility)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            GridRow {
                Text("Default encoding:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "fileEncoding", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                Picker(selection: self.fileEncoding) {
                    ForEach(Array(self.encodingManager.fileEncodings.enumerated()), id: \.offset) { _, encoding in
                        if let encoding {
                            Text(encoding.localizedName)
                                .tag(encoding)
                        } else {
                            Divider()
                        }
                    }
                } label: {
                    EmptyView()
                }
                .modifier { content in
                    if #available(macOS 26, *) {
                        content
                            .buttonSizing(.flexible)
                    } else {
                        content
                    }
                }
                .frame(maxWidth: 260)
                .accessibilityLabeledPair(role: .content, id: "fileEncoding", in: self.accessibility)
            }
            
            GridRow {
                Text("Priority of encodings:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "encodingPriority", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                VStack {
                    VStack(alignment: .leading) {
                        Button(String(localized: "Edit List…", table: "FormatSettings")) {
                            self.isEncodingListPresented.toggle()
                        }
                        .sheet(isPresented: $isEncodingListPresented, content: EncodingListView.init)
                        
                        Toggle(String(localized: "Refer to encoding declaration in document", table: "FormatSettings"), isOn: $referToEncodingTag)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityLabeledPair(role: .content, id: "encodingPriority", in: self.accessibility)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            GridRow {
                Text("Default syntax:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "syntax", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                Picker(selection: $syntax) {
                    Text(String(localized: "SyntaxName.none", defaultValue: "None"))
                        .tag(SyntaxName.none)
                    
                    Divider()
                    
                    if !(self.syntaxNames + [SyntaxName.none]).contains(self.syntax) {
                        Text(self.syntax).tag(self.syntax)
                            .help(String(localized: "This syntax does not exist",
                                         table: "FormatSettings", comment: "tooltip"))
                            .foregroundStyle(.secondary)
                    }
                    
                    ForEach(self.syntaxNames, id: \.self) {
                        Text($0).tag($0)
                    }
                } label: {
                    EmptyView()
                }
                .frame(maxWidth: 260, alignment: .leading)
                .accessibilityLabeledPair(role: .content, id: "syntax", in: self.accessibility)
            }
            
            GridRow(alignment: .top) {
                Text("Available syntaxes:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "availableSyntaxes", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                SyntaxListView(settingNames: self.syntaxNames, manager: self.syntaxManager)
                    .frame(width: 260, height: 140)
                    .accessibilityLabeledPair(role: .content, id: "availableSyntaxes", in: self.accessibility)
            }
            
            HStack {
                Spacer()
                HelpLink(anchor: "settings_format")
            }
        }
        .onReceive(self.syntaxManager.$settingNames) { settingNames in
            self.syntaxNames = settingNames
        }
        .onCommand(#selector((any EncodingsListHolder).showEncodingsListView)) {
            self.isEncodingListPresented = true
        }
        .scenePadding()
        .frame(width: 600)
    }
}


private struct SyntaxListView: View {
    
    var settingNames: [String]
    var manager: SyntaxManager
    
    private let rowHeight: Double = 14
    
    @State private var settingStates: [SettingState] = []
    @State private var selection: SettingState?
    @State private var exportingItem: TransferableSyntax?
    @State private var deletingItem: String?
    @State private var editingMode: SyntaxEditView.Mode?
    
    @State private var isExporterPresented = false
    @State private var isImporterPresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var isImportConfirmationPresented = false
    @State private var isFileMappingConflictPresented = false
    @State private var importingError: ImportDuplicationError?
    @State private var error: (any Error)?
    
    
    var body: some View {
        
        List(self.settingStates, selection: $selection) { state in
            HStack(spacing: 0) {
                Circle()
                    .frame(width: 4, height: 4)
                    .foregroundStyle(.tertiary)
                    .padding(6)
                    .help(String(localized: "This syntax is customized.", table: "FormatSettings"))
                    .opacity(state.isCustomized ? 1 : 0)
                    .accessibilityHidden(!state.isCustomized)
                Text(state.name)
            }
            .tag(state)
            .frame(height: self.rowHeight)
            .listRowSeparator(.hidden)
            .draggable(TransferableSyntax(name: state.name, canExport: !state.isBundled, data: self.manager.dataForUserSetting(name: state.name))) {
                Label {
                    Text(state.name)
                } icon: {
                    Image(nsImage: NSWorkspace.shared.icon(for: .yaml))
                }
            }
        }
        .modifier { content in
            if #available(macOS 26, *) {
                content
                    .safeAreaBar(edge: .bottom) {
                        VStack(spacing: 0) {
                            Divider()
                            self.bottomAccessoryView
                        }
                    }
                    .scrollEdgeEffectStyle(.hard, for: .bottom)
            } else {
                content
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 0) {
                            Divider()
                                .padding(.horizontal, 4)
                            self.bottomAccessoryView
                        }
                        .background()
                    }
            }
        }
        .contextMenu(forSelectionType: SettingState.self) { selections in
            self.menu(for: selections.first, isContext: true)
        } primaryAction: { selections in
            self.editingMode = selections.first.map { .edit($0) }
        }
        .accessibilityRotor(String(localized: "Customized Syntaxes", table: "FormatSettings"),
                            entries: self.settingStates.filter(\.isCustomized), entryID: \.id, entryLabel: \.name)
        .environment(\.defaultMinListRowHeight, self.rowHeight)
        .listStyle(.plain)
        .border(.separator)
        .onChange(of: self.settingNames, initial: true) { _, settingNames in
            self.settingStates = settingNames.compactMap(self.manager.state(of:))
        }
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateSettingNotification, object: self.manager)) { _ in
            // update for the "customized" dots
            self.settingStates = self.manager.settingNames.compactMap(self.manager.state(of:))
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.yaml], allowsMultipleSelection: true) { result in
            switch result {
                case .success(let urls):
                    for url in urls {
                        let accessing = url.startAccessingSecurityScopedResource()
                        defer {
                            if accessing { url.stopAccessingSecurityScopedResource() }
                        }
                        
                        let name = url.deletingPathExtension().lastPathComponent
                        do {
                            let data = try Data(contentsOf: url)
                            try self.manager.importSetting(data: data, name: name, overwrite: false)
                        } catch let error as ImportDuplicationError {
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
        .fileExporter(isPresented: $isExporterPresented, item: self.exportingItem, contentTypes: [.yaml], defaultFilename: self.exportingItem?.name) { result in
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
                }
            }
            Button(.cancel, role: .cancel) {
                self.deletingItem = nil
            }
        } message: { _ in
            Text(String(localized: "DeletionConfirmation.message",
                        defaultValue: "This action cannot be undone."))
        }
        .sheet(item: $editingMode) { mode in
            let state: SettingState? = if case .edit(let state) = mode { state } else { nil }
            let syntax = state.flatMap { try? self.manager.setting(name: $0.name) }
            
            SyntaxEditView(mode: mode, syntax: syntax, manager: self.manager) { syntax, name in
                try self.manager.save(setting: syntax, name: name, oldName: state?.name)
            }
        }
        .sheet(isPresented: $isFileMappingConflictPresented) {
            SyntaxMappingConflictView(table: self.manager.mappingConflicts)
        }
        .alert(error: $error)
    }
    
    
    /// The action buttons to place at the bottom of the list.
    @ViewBuilder private var bottomAccessoryView: some View {
        
        HStack {
            Button {
                self.editingMode = .new
            } label: {
                Image(systemName: "plus")
                    .accessibilityLabel(String(localized: "Action.add.label", defaultValue: "Add"))
                    .padding(2)
            }
            .help(String(localized: "Action.add.tooltip", defaultValue: "Add new item"))
            .frame(width: 16)
            
            Button {
                self.deletingItem = self.selection?.name
                self.isDeleteConfirmationPresented = true
            } label: {
                Image(systemName: "minus")
                    .accessibilityLabel(String(localized: "Action.delete.label", defaultValue: "Delete"))
                    .padding(2)
            }
            .help(String(localized: "Action.delete.tooltip", defaultValue: "Delete selected items"))
            .frame(width: 16)
            .disabled(self.selection?.isBundled != false)
            
            Button {
                self.editingMode = .edit(self.selection!)
            } label: {
                Image(systemName: "pencil")
                    .accessibilityLabel(String(localized: "Action.edit.label", defaultValue: "Edit"))
                    .padding(2)
            }
            .help(String(localized: "Edit selected item", table: "FormatSettings"))
            .frame(width: 16)
            .disabled(self.selection == nil)
            
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
    @ViewBuilder private func menu(for selection: SettingState?, isContext: Bool = false) -> some View {
        
        if let selection {
            if isContext {
                Button(String(localized: "Edit…", table: "FormatSettings"), systemImage: "square.and.pencil") {
                    self.editingMode = .edit(selection)
                }
            }
            
            Button(isContext
                   ? String(localized: "Action.duplicate.label", defaultValue: "Duplicate")
                   : String(localized: "Action.duplicate.named.label", defaultValue: "Duplicate “\(selection.name)”"),
                   systemImage: "plus.square.on.square")
            {
                do {
                    try self.manager.duplicateSetting(name: selection.name)
                } catch {
                    self.error = error
                }
            }
            
            Button(isContext
                   ? String(localized: "Action.restore.label", defaultValue: "Restore")
                   : String(localized: "Action.restore.named.label", defaultValue: "Restore “\(selection.name)”"),
                   systemImage: "arrow.clockwise")
            {
                do {
                    try self.manager.restoreSetting(name: selection.name)
                } catch {
                    self.error = error
                }
            }
            .disabled(!selection.isRestorable)
            
            if isContext {
                Button(String(localized: "Action.delete.label", defaultValue: "Delete"), systemImage: "trash") {
                    self.deletingItem = selection.name
                    self.isDeleteConfirmationPresented = true
                }
                .disabled(selection.isBundled)
            }
            
            Button(isContext
                   ? String(localized: "Action.export.label", defaultValue: "Export…")
                   : String(localized: "Action.export.named.label", defaultValue: "Export “\(selection.name)”…"),
                   systemImage: "square.and.arrow.up")
            {
                self.exportingItem = TransferableSyntax(name: selection.name, data: self.manager.dataForUserSetting(name: selection.name))
                self.isExporterPresented = true
            }
            .modifierKeyAlternate(.option) {
                Button(isContext
                       ? String(localized: "Action.revealInFinder.label", defaultValue: "Reveal in Finder")
                       : String(localized: "Action.revealInFinder.named.label", defaultValue: "Reveal “\(selection.name)” in Finder"),
                       systemImage: "finder")
                {
                    guard let url = self.manager.urlForUserSetting(name: selection.name) else { return }
                    
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
            .disabled(!selection.isCustomized)
            
            // -> ShareLink in menu can't find the appropriate popover origin. (2025-08, macOS 26, FB19287270)
            if let url = self.manager.urlForUserSetting(name: selection.name) {
                ShareLink(item: url)
                    .disabled(!selection.isCustomized)
            }
        }
        
        if !isContext {
            Divider()
            
            Button(String(localized: "Action.import.ellipsis.label", defaultValue: "Import…"), systemImage: "square.and.arrow.down") {
                self.isImporterPresented = true
            }
            .modifierKeyAlternate(.option) {
                Button(String(localized: "Reload All Syntaxes", table: "FormatSettings"), systemImage: "arrow.clockwise") {
                    Task {
                        await self.manager.invalidateUserSettings()
                    }
                }
            }
            
            Divider()
            
            Button(String(localized: "Show File Mapping Conflicts", table: "FormatSettings"), systemImage: "exclamationmark.triangle") {
                self.isFileMappingConflictPresented = true
            }
            .disabled(self.manager.mappingConflicts.isEmpty)
        }
    }
}


private struct TransferableSyntax: Transferable {
    
    var name: String
    var data: @Sendable () -> Data?
    var canExport: Bool
    
    
    init(name: String, canExport: Bool = true, data: @autoclosure @escaping @Sendable () -> Data?) {
        
        self.name = name
        self.data = data
        self.canExport = canExport
    }
    
    
    static var transferRepresentation: some TransferRepresentation {
        
        DataRepresentation(exportedContentType: .yaml) { item in
            guard let data = item.data() else { throw CocoaError(.fileNoSuchFile) }
            return data
        }
        .suggestedFileName(\.name)
        .exportingCondition(\.canExport)
        
        FileRepresentation(importedContentType: .yaml) { received in
            let name = received.file.deletingPathExtension().lastPathComponent
            let data = try Data(contentsOf: received.file)
            return Self(name: name, data: data)
        }
    }
}


// MARK: - Preview

#Preview {
    FormatSettingsView()
}
