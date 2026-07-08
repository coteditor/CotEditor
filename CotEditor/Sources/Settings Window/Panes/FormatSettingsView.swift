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
import UniformTypeIdentifiers
import Defaults
import FileEncoding
import LineEnding
import SyntaxFormat

struct FormatSettingsView: View {
    
    @MainActor @Observable final class Presentation {
        
        static let shared = Presentation()
        
        private(set) var encodingListRequestID: UUID?
        
        
        /// Requests the encoding list sheet to be presented.
        func requestEncodingList() {
            
            self.encodingListRequestID = UUID()
        }
    }
    
    
    @Namespace private var accessibility
    
    @AppStorage(.lineEndCharCode) private var lineEnding
    
    @AppStorage(.encoding) private var encoding
    @AppStorage(.saveUTF8BOM) private var saveUTF8BOM
    @AppStorage(.referToEncodingTag) private var referToEncodingTag
    
    @AppStorage(.syntax) private var syntax
    
    private var syntaxManager: SyntaxManager = .shared
    
    @State private var encodingManager: EncodingManager = .shared
    @State private var presentation: Presentation = .shared
    @State private var syntaxNames: [String] = []
    @State private var handledEncodingListRequestID: UUID?
    
    
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
                .accessibilityLabeledPair(role: .content, id: "lineEnding", in: self.accessibility)
            }
            
            Divider()
                .padding(.vertical, 6)
            
            GridRow {
                Text("Default text encoding:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "fileEncoding", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                Picker(selection: self.fileEncoding) {
                    ForEach(self.encodingManager.fileEncodings.enumerated(), id: \.offset) { _, encoding in
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
                .buttonSizing(.flexible)
                .frame(maxWidth: 260)
                .accessibilityLabeledPair(role: .content, id: "fileEncoding", in: self.accessibility)
            }
            
            GridRow {
                Text("Encoding priorities:", tableName: "FormatSettings")
                    .accessibilityLabeledPair(role: .label, id: "encodingPriority", in: self.accessibility)
                    .gridColumnAlignment(.trailing)
                
                VStack {
                    VStack(alignment: .leading) {
                        Button(String(localized: "Edit List…", table: "FormatSettings")) {
                            self.isEncodingListPresented.toggle()
                        }
                        .sheet(isPresented: $isEncodingListPresented) {
                            EncodingListView(defaultEncoding: self.encodingManager.defaultEncoding)
                                .scenePadding()
                                .presentationSizing(.fitted)
                        }
                        
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
                .buttonSizing(.flexible)
                .frame(maxWidth: 260)
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
        .onChange(of: self.syntaxManager.settingNames, initial: true) { _, newValue in self.syntaxNames = newValue }
        .onChange(of: self.presentation.encodingListRequestID, initial: true) { _, requestID in
            guard
                let requestID,
                requestID != self.handledEncodingListRequestID
            else { return }
            
            self.handledEncodingListRequestID = requestID
            self.isEncodingListPresented = true
        }
    }
}


private struct SyntaxListView: View {
    
    private enum EditingMode: Identifiable {
        
        case new
        case edit(SettingState)
        
        
        var id: String? {
            
            switch self {
                case .new: nil
                case .edit(let state): state.name
            }
        }
    }
    
    
    var settingNames: [String]
    var manager: SyntaxManager
    
    @State private var settingStates: [SettingState] = []
    @State private var selection: SettingState?
    @State private var exportingItem: TransferableSyntax?
    @State private var deletingItem: String?
    @State private var editingMode: EditingMode?
    
    @State private var isExporterPresented = false
    @State private var isImporterPresented = false
    @State private var isListCustomizationViewPresented = false
    @State private var isFileMappingConflictPresented = false
    @State private var importingError: ImportDuplicationError?
    @State private var error: (any Error)?
    
    @State private var settingUpdateObserver: NotificationCenter.ObservationToken?
    
    
    var body: some View {
        
        List(self.settingStates, selection: $selection) { state in
            Label {
                Text(state.name)
            } icon: {
                Circle()
                    .frame(width: 4)
                    .foregroundStyle(.secondary)
                    .help(String(localized: "This syntax is customized.", table: "FormatSettings"))
                    .opacity(state.isCustomized ? 1 : 0)
                    .accessibilityHidden(!state.isCustomized)
            }
            .labelReservedIconWidth(12)
            .listRowSeparator(.hidden)
            .modifier { container in
                if state.isCustomized {
                    container
                        .draggable(containerItemID: state.name)
                } else {
                    container
                }
            }
            .tag(state)
        }
        .safeAreaBar(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                self.bottomAccessoryView
            }
        }
        .scrollEdgeEffectStyle(.hard, for: .bottom)
        .dragContainer { draggedItemIDs in
            draggedItemIDs.compactMap { name in
                self.manager.urlForUserSetting(name: name)
                    .map { TransferableSyntax(name: name, url: $0) }
            }
        }
        .dragConfiguration(DragConfiguration(allowMove: false, allowDelete: true))
        .onDragSessionUpdated { session in
            switch session.phase {
                case .ended(.delete):
                    let names = session.draggedItemIDs(for: String.self)
                        .filter { self.manager.state(of: $0)?.isBundled != true }
                    
                    guard let name = names.first else { return }
                    
                    do {
                        try self.manager.removeSetting(name: name)
                    } catch {
                        self.error = error
                        return
                    }
                    if self.selection?.name == name {
                        self.selection = nil
                    }
                    
                default:
                    break
            }
        }
        .dropDestination(for: URL.self) { urls, session in
            guard session.localSession == nil else { return }
            
            self.importSettings(at: urls)
        }
        .contextMenu(forSelectionType: SettingState.self) { selections in
            self.menu(for: selections.first, isContext: true)
        } primaryAction: { selections in
            self.editingMode = selections.first.map { .edit($0) }
        }
        .accessibilityRotor(String(localized: "Customized Syntaxes", table: "FormatSettings"),
                            entries: self.settingStates.filter(\.isCustomized), entryID: \.id, entryLabel: \.name)
        .listStyle(.plain)
        .border(.separator)
        .onChange(of: self.settingNames, initial: true) { _, settingNames in
            self.settingStates = settingNames.compactMap(self.manager.state(of:))
        }
        .onAppear {
            // update for the "customized" dots
            self.settingUpdateObserver = NotificationCenter.default.addObserver(of: self.manager, for: DidManagerUpdateSettingMessage.self) { _ in
                self.settingStates = self.manager.settingNames.compactMap(self.manager.state(of:))
            }
        }
        .onDisappear {
            self.settingUpdateObserver = nil
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.cotSyntax, .yaml], allowsMultipleSelection: true) { result in
            switch result {
                case .success(let urls):
                    self.importSettings(at: urls)
                case .failure(let error):
                    self.error = error
            }
        }
        .fileDialogConfirmationLabel(String(localized: "Action.import.label", defaultValue: "Import"))
        .confirmationDialog(String(localized: "ImportDuplicationError.description",
                                   defaultValue: "“\(self.importingError?.name ?? String(localized: .unknown))” already exists. Do you want to replace it?",
                                   comment: "%@ is a name of a setting. Refer to the same expression by Apple."),
                            item: $importingError) { item in
            Button(String(localized: "Action.replace.label", defaultValue: "Replace")) {
                do {
                    try item.item.withSecurityScopedAccess {
                        try self.manager.importSetting(item.item, name: item.name, type: item.type, overwrite: true)
                    }
                } catch {
                    self.error = error
                }
            }
        } message: { error in
            Text(error.recoverySuggestion)
        }
        // place fileExporter after `fileDialogConfirmationLabel(_:)` for the import action to use the default label for the export.
        .fileExporter(isPresented: $isExporterPresented, item: self.exportingItem, contentTypes: [.cotSyntax], defaultFilename: self.exportingItem?.name) { result in
            switch result {
                case .success:
                    break
                case .failure(let error):
                    self.error = error
            }
        }
        .confirmationDialog(String(localized: "DeletionConfirmation.title",
                                   defaultValue: "Are you sure you want to delete “\(self.deletingItem ?? String(localized: .unknown))”?"),
                            item: $deletingItem)
        { name in
            Button(String(localized: "Action.delete.label", defaultValue: "Delete"), role: .destructive) {
                do {
                    try self.manager.removeSetting(name: name)
                } catch {
                    self.error = error
                }
            }
        } message: { _ in
            Text(String(localized: "DeletionConfirmation.message",
                        defaultValue: "This action cannot be undone."))
        }
        .sheet(item: $editingMode) { mode in
            let state: SettingState? = if case .edit(let state) = mode { state } else { nil }
            let syntax = state.flatMap { try? self.manager.setting(name: $0.name) }
            let customizableFeatures = state.flatMap { self.manager.customizableFeatures(name: $0.name) } ?? .all
            
            SyntaxEditView(syntax: syntax, name: state?.name, isBundled: state?.isBundled ?? false, customizableFeatures: customizableFeatures) { syntax, name in
                try self.manager.save(setting: syntax, name: name, oldName: state?.name)
            } validationAction: { name in
                try self.manager.validate(settingName: name, originalName: state?.name)
            }
            .presentationSizing(.fitted)
        }
        .sheet(isPresented: $isListCustomizationViewPresented) {
            SyntaxListCustomizationView(items: self.settingNames)
                .scenePadding()
                .presentationSizing(.fitted)
            
        }
        .sheet(isPresented: $isFileMappingConflictPresented) {
            SyntaxMappingConflictView(table: self.manager.mappingConflicts)
                .scenePadding()
                .presentationSizing(.fitted)
        }
        .alert(error: $error)
    }
    
    
    /// The action buttons to place at the bottom of the list.
    @ContentBuilder private var bottomAccessoryView: some View {
        
        HStack {
            Button {
                self.editingMode = .new
            } label: {
                Label(String(localized: "Action.add.label", defaultValue: "Add"), systemImage: "plus")
                    .padding(2)
            }
            .help(String(localized: "Action.add.tooltip", defaultValue: "Add new item"))
            .labelStyle(.iconOnly)
            .frame(width: 16)
            
            Button {
                self.deletingItem = self.selection?.name
            } label: {
                Label(String(localized: "Action.delete.label", defaultValue: "Delete"), systemImage: "minus")
                    .padding(2)
            }
            .help(String(localized: "Action.delete.tooltip", defaultValue: "Delete selected items"))
            .labelStyle(.iconOnly)
            .frame(width: 16)
            .disabled(self.selection?.isBundled != false)
            
            Button {
                self.editingMode = .edit(self.selection!)
            } label: {
                Label(String(localized: "Action.edit.label", defaultValue: "Edit"), systemImage: "pencil")
                    .padding(2)
            }
            .help(String(localized: "Edit selected item", table: "FormatSettings"))
            .labelStyle(.iconOnly)
            .frame(width: 16)
            .disabled(self.selection == nil)
            
            Spacer()
            
            Menu {
                self.menu(for: self.selection)
            } label: {
                Label(String(localized: "Button.actions.label", defaultValue: "Actions"), systemImage: "ellipsis")
                    .symbolVariant(.circle)
                    .labelStyle(.iconOnly)
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
    @ContentBuilder private func menu(for selection: SettingState?, isContext: Bool = false) -> some View {
        
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
                }
                .disabled(selection.isBundled)
            }
            
            Button(isContext
                   ? String(localized: "Action.export.label", defaultValue: "Export…")
                   : String(localized: "Action.export.named.label", defaultValue: "Export “\(selection.name)”…"),
                   systemImage: "square.and.arrow.up")
            {
                if let url = self.manager.urlForUserSetting(name: selection.name) {
                    self.exportingItem = TransferableSyntax(name: selection.name, url: url)
                    self.isExporterPresented = true
                }
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
            
            Button(String(localized: "Customize Syntax Menu…", table: "FormatSettings"), systemImage: "square.and.pencil") {
                self.isListCustomizationViewPresented = true
            }
            
            Button(String(localized: "Show File Mapping Conflicts", table: "FormatSettings"), systemImage: "exclamationmark.triangle") {
                self.isFileMappingConflictPresented = true
            }
            .disabled(self.manager.mappingConflicts.isEmpty)
        }
    }
    
    
    /// Imports setting files at the given URLs.
    ///
    /// - Parameter urls: The file URLs to import.
    private func importSettings(at urls: [URL]) {
        
        for url in urls {
            guard url.isFileURL else { continue }
            
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }
            
            let name = url.deletingPathExtension().lastPathComponent
            do {
                let type = try url.resourceValues(forKeys: [.contentTypeKey]).contentType
                guard type?.conforms(to: .cotSyntax) == true || type?.conforms(to: .yaml) == true else { continue }
                
                try self.manager.importSetting(.url(url), name: name, type: type, overwrite: false)
            } catch let error as ImportDuplicationError {
                self.importingError = error
                return
            } catch {
                self.error = error
                return
            }
            self.selection = self.manager.state(of: name)
        }
    }
}


private struct TransferableSyntax: TransferableFile {
    
    static let fileType: UTType = .cotSyntax
    
    var name: String
    var url: URL
}


// MARK: - Preview

#Preview {
    FormatSettingsView()
        .scenePadding()
}
