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
//  © 2022-2026 1024jp
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
import Defaults
import SyntaxFormat
import UniformTypeIdentifiers

struct ThemeView: View {
    
    private var manager: ThemeManager = .shared
    
    @Environment(\.colorScheme) private var colorScheme
    
    @AppStorage(.theme) private var themeName
    @AppStorage(.pinsThemeAppearance) private var pinsThemeAppearance
    @AppStorage(.documentAppearance) private var documentAppearance
    
    @State private var selection: String = ""
    @State private var theme: Theme = .init()
    @State private var isBundled: Bool = false
    
    @State private var error: any Error?
    
    @State private var settingUpdateObserver: NotificationCenter.ObservationToken?
    
    
    var body: some View {
        
        HStack(spacing: 0) {
            ThemeListView(manager: self.manager, selection: $selection)
            
            Divider()
            
            ThemeEditorView(theme: $theme, isBundled: self.isBundled)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(width: 400)
                .onChange(of: self.theme) { _, newValue in
                    do {
                        try self.manager.save(setting: newValue, name: self.selection)
                    } catch {
                        self.error = error
                    }
                }
        }
        .onAppear {
            self.selectDefaultTheme()
            
            self.settingUpdateObserver = NotificationCenter.default.addObserver(of: self.manager, for: DidManagerUpdateSettingMessage.self) { message in
                guard let name = message.change.new, name == self.themeName else { return }
                self.setTheme(name: name)
            }
        }
        .onDisappear {
            self.settingUpdateObserver = nil
        }
        .onChange(of: self.documentAppearance) {
            self.selectDefaultTheme()
        }
        .onChange(of: self.themeName) {
            self.selectDefaultTheme()
        }
        .onChange(of: self.selection) { _, newValue in
            self.setTheme(name: newValue)
        }
        .background()
        .border(.separator)
        .alert(error: $error)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Theme", table: "ThemeEditor"))
    }
    
    
    /// Selects the effective default theme.
    private func selectDefaultTheme() {
        
        self.selectTheme(name: self.manager.userDefaultSettingName(inDarkMode: self.colorScheme == .dark))
    }
    
    
    /// Selects the given theme.
    ///
    /// - Parameter name: The theme name.
    private func selectTheme(name: String) {
        
        if self.selection == name {
            self.setTheme(name: name)
        } else {
            self.selection = name
        }
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
        let usesDarkAppearance = self.manager.usesDarkAppearance(inDarkMode: self.colorScheme == .dark)
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
    @State private var importingError: ImportDuplicationError?
    @State private var error: any Error?
    
    
    var body: some View {
        
        List(selection: $selection) {
            Section(String(localized: "Theme", table: "ThemeEditor")) {
                ForEach(self.settingNames, id: \.self) { name in
                    let state = self.manager.state(of: name)
                    
                    SettingNameField(text: name) { newName in
                        do {
                            self.selection = try self.manager.renameSetting(name: name, to: newName)
                        } catch {
                            self.error = error
                            return false
                        }
                        return true
                    }
                    .editDisabled(state?.isBundled == true)
                    .focused($editingItem, equals: name)
                    .draggable(TransferableTheme.self) {
                        self.manager.urlForUserSetting(name: name)
                            .map { .init(name: name, url: $0) }
                    }
                    .tag(name)
                }
            }
            .listRowSeparator(.hidden)
        }
        .safeAreaBar(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                self.bottomAccessoryView
                    .padding(6)
            }
        }
        .scrollEdgeEffectStyle(.hard, for: .bottom)
        .dragConfiguration(DragConfiguration(allowMove: false, allowDelete: true))
        .dropDestination(for: URL.self) { urls, session in
            guard session.localSession == nil else { return }
            
            self.importSettings(at: urls)
        }
        .contextMenu(forSelectionType: String.self) { selections in
            if let selection = selections.first {
                self.menu(for: selection, isContext: true)
            }
        }
        .onChange(of: self.manager.settingNames, initial: true) { _, newValue in self.settingNames = newValue }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.cotTheme], allowsMultipleSelection: true) { result in
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
                            item: $deletingItem)
        { name in
            Button(String(localized: "Action.delete.label", defaultValue: "Delete"), role: .destructive) {
                do {
                    try self.manager.removeSetting(name: name)
                } catch {
                    self.error = error
                    return
                }
                UserDefaults.standard.restore(key: .theme)
            }
        } message: { _ in
            Text(String(localized: "DeletionConfirmation.message",
                        defaultValue: "This action cannot be undone."))
        }
        .alert(error: $error)
    }
    
    
    /// The action buttons to place at the bottom of the list.
    @ContentBuilder private var bottomAccessoryView: some View {
        
        HStack {
            Button {
                do {
                    self.selection = try self.manager.createUntitledSetting()
                } catch {
                    self.error = error
                }
            } label: {
                Label(String(localized: "Action.add.label", defaultValue: "Add"), systemImage: "plus")
                    .padding(2)
            }
            .help(String(localized: "Action.add.tooltip", defaultValue: "Add new item"))
            .labelStyle(.iconOnly)
            .frame(width: 16)
            
            Button {
                self.deletingItem = self.selection
            } label: {
                Label(String(localized: "Action.delete.label", defaultValue: "Delete"), systemImage: "minus")
                    .padding(2)
            }
            .help(String(localized: "Action.delete.tooltip", defaultValue: "Delete selected items"))
            .labelStyle(.iconOnly)
            .frame(width: 16)
            .disabled(self.manager.state(of: self.selection)?.isBundled != false)
            
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
    }
    
    
    /// Builds menu items for either the Action menu button or the context menu.
    ///
    /// - Parameters:
    ///   - selection: The action target.
    ///   - isContext: Whether the items are for the context menu.
    /// - Returns: Menu items.
    @ContentBuilder private func menu(for selection: String, isContext: Bool = false) -> some View {
        
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
                }
                .disabled(selection.isBundled)
            }
            
            Button(isContext
                   ? String(localized: "Action.export.label", defaultValue: "Export…")
                   : String(localized: "Action.export.named.label", defaultValue: "Export “\(selection.name)”…"),
                   systemImage: "square.and.arrow.up")
            {
                if let url = self.manager.urlForUserSetting(name: selection.name) {
                    self.exportingItem = TransferableTheme(name: selection.name, url: url)
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
                Button(String(localized: "Reload All Themes", table: "ThemeEditor"), systemImage: "arrow.clockwise") {
                    Task {
                        await self.manager.invalidateUserSettings()
                    }
                }
            }
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
                guard type?.conforms(to: .cotTheme) == true else { continue }
                
                try self.manager.importSetting(.url(url), name: name, type: type, overwrite: false)
            } catch let error as ImportDuplicationError {
                self.importingError = error
                return
            } catch {
                self.error = error
                return
            }
            self.selection = name
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
                                      systemColor: Color(nsColor: .textInsertionPointColor),
                                      supportsOpacity: false)
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
    
    
    @ContentBuilder private func itemView(_ title: some StringProtocol, text: Binding<String>, lineLimit: ClosedRange<Int> = 1...1) -> some View {
        
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


private struct TransferableTheme: TransferableFile {
    
    static let fileType: UTType = .cotTheme
    
    var name: String
    var url: URL
}


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 480, height: 280)) {
    ThemeView()
}

#Preview("ThemeEditorView", traits: .fixedLayout(width: 400, height: 280)) {
    @Previewable @State var theme = try! ThemeManager.shared.setting(name: "Anura")
    
    ThemeEditorView(theme: $theme, isBundled: false)
        .scenePadding()
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
