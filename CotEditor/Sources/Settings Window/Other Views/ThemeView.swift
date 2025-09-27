//
//  ThemeView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-09-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2025 1024jp
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
import AppKit.NSColor
import Combine
import Defaults
import Syntax

struct ThemeView: View {
    
    private var manager: ThemeManager = .shared
    
    @AppStorage(.theme) private var themeName
    @AppStorage(.pinsThemeAppearance) private var pinsThemeAppearance
    @AppStorage(.documentAppearance) private var documentAppearance
    
    @State private var selection: String = ""
    @State private var theme: Theme = .init()
    @State private var isBundled: Bool = false
    
    @State private var error: (any Error)?
    
    
    var body: some View {
        
        HStack(spacing: 0) {
            ThemeListView(manager: self.manager, selection: $selection)
            
            Divider()
            
            ThemeEditorView(theme: $theme, isBundled: self.isBundled)
                .frame(width: 360)
                .onChange(of: self.theme) { _, newValue in
                    do {
                        try self.manager.save(setting: newValue, name: self.selection)
                    } catch {
                        self.error = error
                    }
                }
        }
        .onAppear {
            self.selection = self.themeName
        }
        .onChange(of: self.documentAppearance) {
            self.themeName = self.manager.userDefaultSettingName
        }
        .onChange(of: self.selection) { _, newValue in
            self.setTheme(name: newValue)
        }
        .task {
            let names = NotificationCenter.default
                .notifications(named: .didUpdateSettingNotification, object: self.manager)
                .compactMap { $0.userInfo?["change"] as? SettingChange }
                .compactMap(\.new)
            
            for await name in names where name == self.themeName {
                self.setTheme(name: name)
            }
        }
        .background()
        .border(.separator)
        .alert(error: $error)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Theme", table: "ThemeEditor"))
    }
    
    
    /// Sets the given theme to the editor.
    ///
    /// - Parameter name: The theme name.
    private func setTheme(name: String) {
        
        let theme: Theme
        do {
            theme = try self.manager.setting(name: name)
        } catch {
            self.error = error
            return
        }
        
        // update default theme setting
        let isDarkTheme = ThemeManager.isDark(name: name)
        let usesDarkAppearance = self.manager.usesDarkAppearance
        self.pinsThemeAppearance = (isDarkTheme != usesDarkAppearance)
        self.themeName = name
        
        self.isBundled = self.manager.state(of: name)?.isBundled == true
        self.theme = theme
    }
}


private struct ThemeListView: View {
    
    var manager: ThemeManager
    
    @Binding var selection: String
    
    
    @State private var settingNames: [String] = []
    @State private var exportingItem: TransferableTheme?
    @State private var deletingItem: String?
    @FocusState private var editingItem: String?
    
    @State private var isExporterPresented = false
    @State private var isImporterPresented = false
    @State private var isDeleteConfirmationPresented = false
    @State private var isImportConfirmationPresented = false
    @State private var importingError: ImportDuplicationError?
    @State private var error: (any Error)?
    
    
    var body: some View {
        
        VStack(spacing: 0) {
            List(selection: $selection) {
                Section(String(localized: "Theme", table: "ThemeEditor")) {
                    ForEach(self.settingNames, id: \.self) { name in
                        let state = self.manager.state(of: name)
                        
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
                        .editDisabled(state?.isBundled == true)
                        .focused($editingItem, equals: name)
                        .draggable(TransferableTheme(name: name, canExport: state?.isCustomized == true, data: self.manager.dataForUserSetting(name: name))) {
                            Label {
                                Text(name)
                            } icon: {
                                Image(nsImage: NSWorkspace.shared.icon(for: .cotTheme))
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
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
                }
            }
            .dropDestination(for: TransferableTheme.self) { items, _ in
                var succeed = false
                for item in items {
                    guard let data = item.data() else { continue }
                    do {
                        try self.manager.importSetting(data: data, name: item.name, overwrite: false)
                        succeed = true
                    } catch let error as ImportDuplicationError {
                        self.importingError = error
                        self.isImportConfirmationPresented = true
                    } catch {
                        self.error = error
                    }
                }
                return succeed
            }
            .contextMenu(forSelectionType: String.self) { selections in
                if let selection = selections.first {
                    self.menu(for: selection, isContext: true)
                }
            }
            .listStyle(.bordered)
            .border(.background)
            
            if #unavailable(macOS 26) {
                Divider()
                    .padding(.horizontal, 4)
                
                self.bottomAccessoryView
            }
        }
        .onReceive(self.manager.$settingNames.receive(on: RunLoop.main)) { settingNames in
            self.settingNames = settingNames
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.cotTheme], allowsMultipleSelection: true) { result in
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
                                   comment: "%@ is a name of a setting. Refer the same expression by Apple."),
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
        .fileExporter(isPresented: $isExporterPresented, item: self.exportingItem, contentTypes: [.cotTheme], defaultFilename: self.exportingItem?.name) { result in
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
                UserDefaults.standard.restore(key: .theme)
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
                do {
                    self.selection = try self.manager.createUntitledSetting()
                } catch {
                    self.error = error
                }
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
            .disabled(self.manager.state(of: self.selection)?.isBundled != false)
            
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
    @ViewBuilder private func menu(for selection: String, isContext: Bool = false) -> some View {
        
        if let selection = self.manager.state(of: selection) {
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
                   ? String(localized: "Action.rename.label", defaultValue: "Rename")
                   : String(localized: "Action.rename.named.label", defaultValue: "Rename “\(selection.name)”"),
                   systemImage: "pencil")
            {
                self.editingItem = selection.name
            }
            .disabled(selection.isBundled)
            
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
                self.exportingItem = TransferableTheme(name: selection.name, data: self.manager.dataForUserSetting(name: selection.name))
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
                Button(String(localized: "Reload All Themes", table: "ThemeEditor"), systemImage: "arrow.clockwise") {
                    Task.detached(priority: .utility) {
                        self.manager.loadUserSettings()
                    }
                }
            }
        }
    }
}


private struct ThemeEditorView: View {
    
    @Binding var theme: Theme
    var isBundled: Bool
    
    @State private var isMetadataPresenting = false
    
    
    // MARK: View
    
    var body: some View {
        
        Grid(alignment: .trailingFirstTextBaseline, verticalSpacing: 4) {
            GridRow {
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "Text:", table: "ThemeEditor"),
                                selection: $theme.text.binding, supportsOpacity: false)
                    ColorPicker(String(localized: "Invisibles:", table: "ThemeEditor"),
                                selection: $theme.invisibles.binding)
                    SystemColorPicker(String(localized: "Cursor:", table: "ThemeEditor"),
                                      selection: $theme.insertionPoint,
                                      systemColor: Color(nsColor: .textInsertionPointColor))
                }.accessibilityElement(children: .contain)
                
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "Background:", table: "ThemeEditor"),
                                selection: $theme.background.binding, supportsOpacity: false)
                    ColorPicker(String(localized: "Current Line:", table: "ThemeEditor"),
                                selection: $theme.lineHighlight.binding)
                    SystemColorPicker(String(localized: "Selection:", table: "ThemeEditor"),
                                      selection: $theme.selection,
                                      systemColor: Color(nsColor: .selectedTextBackgroundColor.forDarkMode(self.theme.isDarkTheme)),
                                      supportsOpacity: false)
                    SystemColorPicker(String(localized: "Highlight:", table: "ThemeEditor"),
                                      selection: $theme.highlight,
                                      systemColor: .accentColor,
                                      supportsOpacity: false)
                }.accessibilityElement(children: .contain)
            }.accessibilityElement(children: .contain)
            
            GridRow {
                Text("Syntax", tableName: "ThemeEditor")
                    .fontWeight(.bold)
                    .gridCellColumns(2)
                    .gridCellAnchor(.leading)
                    .accessibilityAddTraits(.isHeader)
            }
            
            GridRow {
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "\(SyntaxType.keywords.label):"),
                                selection: $theme.keywords.binding)
                    ColorPicker(String(localized: "\(SyntaxType.commands.label):"),
                                selection: $theme.commands.binding)
                    ColorPicker(String(localized: "\(SyntaxType.types.label):"),
                                selection: $theme.types.binding)
                    ColorPicker(String(localized: "\(SyntaxType.attributes.label):"),
                                selection: $theme.attributes.binding)
                    ColorPicker(String(localized: "\(SyntaxType.variables.label):"),
                                selection: $theme.variables.binding)
                }.accessibilityElement(children: .contain)
                
                VStack(alignment: .trailing, spacing: 3) {
                    ColorPicker(String(localized: "\(SyntaxType.values.label):"),
                                selection: $theme.values.binding)
                    ColorPicker(String(localized: "\(SyntaxType.numbers.label):"),
                                selection: $theme.numbers.binding)
                    ColorPicker(String(localized: "\(SyntaxType.strings.label):"),
                                selection: $theme.strings.binding)
                    ColorPicker(String(localized: "\(SyntaxType.characters.label):"),
                                selection: $theme.characters.binding)
                    ColorPicker(String(localized: "\(SyntaxType.comments.label):"),
                                selection: $theme.comments.binding)
                }.accessibilityElement(children: .contain)
            }.accessibilityElement(children: .contain)
            
            HStack {
                Spacer()
                Button(String(localized: "Show theme file information", table: "ThemeEditor"), systemImage: "info") {
                    self.isMetadataPresenting.toggle()
                }
                .symbolVariant(.circle)
                .labelStyle(.iconOnly)
                .popover(isPresented: $isMetadataPresenting, arrowEdge: .trailing) {
                    ThemeMetadataView(metadata: $theme.metadata ?? .init(), isEditable: !self.isBundled)
                }
                .buttonStyle(.borderless)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Theme Editor", table: "ThemeEditor"))
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}


private struct SystemColorPicker: View {
    
    var label: String
    @Binding var selection: Theme.SystemDefaultStyle
    var systemColor: Color
    var supportsOpacity: Bool
    
    @Namespace private var accessibility
    
    
    init(_ label: String, selection: Binding<Theme.SystemDefaultStyle>, systemColor: Color, supportsOpacity: Bool = true) {
        
        self.label = label
        self._selection = selection
        self.systemColor = systemColor
        self.supportsOpacity = supportsOpacity
    }
    
    
    var body: some View {
        
        VStack(alignment: .trailing, spacing: 4) {
            ColorPicker(selection: self.selection.usesSystemSetting ? .constant(self.systemColor) : $selection.binding, supportsOpacity: self.supportsOpacity) {
                Text(self.label)
                    .accessibilityLabeledPair(role: .label, id: "color", in: self.accessibility)
            }
            .disabled(self.selection.usesSystemSetting)
            Toggle(String(localized: "Use system color", table: "ThemeEditor", comment: "toggle button label"), isOn: $selection.usesSystemSetting)
                .controlSize(.small)
                .accessibilityLabeledPair(role: .content, id: "color", in: self.accessibility)
        }.accessibilityElement(children: .contain)
    }
}


private struct ThemeMetadataView: View {
    
    @Binding var metadata: Theme.Metadata
    var isEditable: Bool
    
    @Namespace private var accessibility
    
    
    // MARK: View
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 4) {
            GridRow {
                self.itemView(String(localized: "Author:", table: "ThemeEditor"),
                              text: $metadata.author ?? "")
            }
            GridRow {
                self.itemView(String(localized: "URL:", table: "ThemeEditor"),
                              text: $metadata.distributionURL ?? "")
                .textContentType(.URL)
                LinkButton(url: self.metadata.distributionURL ?? "")
                    .foregroundStyle(.secondary)
            }
            GridRow {
                self.itemView(String(localized: "License:", table: "ThemeEditor"),
                              text: $metadata.license ?? "")
            }
            GridRow {
                self.itemView(String(localized: "Description:", table: "ThemeEditor"),
                              text: $metadata.description ?? "", lineLimit: 2...5)
            }
        }
        .padding(10)
        .controlSize(.small)
        .frame(width: 300, alignment: .leading)
    }
    
    
    @ViewBuilder private func itemView(_ title: some StringProtocol, text: Binding<String>, lineLimit: ClosedRange<Int> = 1...1) -> some View {
        
        Text(title)
            .fontWeight(.bold)
            .gridColumnAlignment(.trailing)
            .accessibilityLabeledPair(role: .label, id: title, in: self.accessibility)
        
        if self.isEditable {
            TextField(title, text: text, prompt: Text("Not defined", tableName: "ThemeEditor", comment: "placeholder"), axis: .vertical)
                .lineLimit(lineLimit)
                .textFieldStyle(.plain)
                .accessibilityLabeledPair(role: .content, id: title, in: self.accessibility)
        } else {
            Text(text.wrappedValue)
                .textSelection(.enabled)
                .accessibilityLabeledPair(role: .content, id: title, in: self.accessibility)
        }
    }
}


private extension Theme.Style {
    
    var binding: Color {
        
        get { Color(nsColor: self.color) }
        set { self.color = NSColor(newValue).componentBased }
    }
}


private extension Theme.SystemDefaultStyle {
    
    var binding: Color {
        
        get { Color(nsColor: self.color) }
        set { self.color = NSColor(newValue).componentBased }
    }
}


private struct TransferableTheme: Transferable {
    
    var name: String
    var canExport: Bool
    var data: @Sendable () -> Data?
    
    
    init(name: String, canExport: Bool = true, data: @autoclosure @Sendable @escaping () -> Data?) {
        
        self.name = name
        self.canExport = canExport
        self.data = data
    }
    
    
    static var transferRepresentation: some TransferRepresentation {
        
        DataRepresentation(exportedContentType: .cotTheme) { item in
            guard let data = item.data() else { throw CocoaError(.fileNoSuchFile) }
            return data
        }
        .suggestedFileName { $0.name }
        .exportingCondition { $0.canExport }
        
        FileRepresentation(importedContentType: .cotTheme) { received in
            let name = received.file.deletingPathExtension().lastPathComponent
            let data = try Data(contentsOf: received.file)
            return TransferableTheme(name: name, data: data)
        }
    }
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 480, height: 280)) {
    ThemeView()
}

#Preview("ThemeEditorView", traits: .fixedLayout(width: 360, height: 280)) {
    @Previewable @State var theme = try! ThemeManager.shared.setting(name: "Anura")
    
    ThemeEditorView(theme: $theme, isBundled: false)
}

#Preview("Metadata (editable)") {
    @Previewable @State var metadata = Theme.Metadata(
        author: "Clarus",
        distributionURL: "https://coteditor.com"
    )
    
    ThemeMetadataView(metadata: $metadata, isEditable: true)
}

#Preview("Metadata (fixed)") {
    @Previewable @State var metadata = Theme.Metadata(
        author: "Clarus"
    )
    
    ThemeMetadataView(metadata: $metadata, isEditable: false)
}
