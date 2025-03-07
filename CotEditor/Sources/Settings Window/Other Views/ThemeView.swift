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
import Defaults
import Syntax

struct ThemeView: View {
    
    @AppStorage(.theme) private var themeName
    @AppStorage(.pinsThemeAppearance) private var pinsThemeAppearance
    @AppStorage(.documentAppearance) private var documentAppearance
    
    @State private var theme: Theme = .init()
    @State private var isBundled: Bool = false
    
    @State private var error: (any Error)?
    
    
    var body: some View {
        
        HStack(spacing: 0) {
            ThemeListView(selection: $themeName)
            
            Divider()
            
            ThemeEditorView(theme: $theme, isBundled: self.isBundled)
                .frame(width: 360)
                .onChange(of: self.theme) { (_, newValue) in
                    do {
                        try ThemeManager.shared.save(setting: newValue, name: self.themeName)
                    } catch {
                        self.error = error
                    }
                }
        }
        .onChange(of: self.documentAppearance, initial: true) {
            self.themeName = ThemeManager.shared.userDefaultSettingName
        }
        .onChange(of: self.themeName, initial: true) { (_, newValue) in
            self.setTheme(name: newValue)
        }
        .task {
            let changes = NotificationCenter.default
                .notifications(named: .didUpdateSettingNotification, object: ThemeManager.shared)
                .compactMap { $0.userInfo?["change"] as? SettingChange }
            
            for await name in changes.compactMap(\.new) {
                await MainActor.run {
                    guard
                        name == self.themeName,
                        let theme = try? ThemeManager.shared.setting(name: name)
                    else { return }
                    
                    self.theme = theme
                }
            }
        }
        .background()
        .border(.separator)
        .alert(error: $error)
    }
    
    
    /// Sets the given theme to the editor.
    ///
    /// - Parameter name: The theme name.
    private func setTheme(name: String) {
        
        let theme: Theme
        do {
            theme = try ThemeManager.shared.setting(name: name)
        } catch {
            self.error = error
            return
        }
        
        // update default theme setting
        let isDarkTheme = ThemeManager.isDark(name: name)
        let usesDarkAppearance = ThemeManager.shared.usesDarkAppearance
        self.pinsThemeAppearance = (isDarkTheme != usesDarkAppearance)
        self.themeName = name
        
        self.isBundled = ThemeManager.shared.state(of: name)?.isBundled == true
        self.theme = theme
    }
}


private struct ThemeListView: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = ThemeListViewController
    
    @Binding var selection: String
    
    
    func makeNSViewController(context: Context) -> ThemeListViewController {
        
        NSStoryboard(name: "ThemeListView", bundle: nil).instantiateInitialController { coder in
            ThemeListViewController(coder: coder, selection: $selection)
        }!
    }
    
    
    func updateNSViewController(_ nsViewController: ThemeListViewController, context: Context) {
        
        nsViewController.select(settingName: self.selection)
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
                .popover(isPresented: self.$isMetadataPresenting, arrowEdge: .trailing) {
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
    
    
    @ViewBuilder private func itemView(_ title: String, text: Binding<String>, lineLimit: ClosedRange<Int> = 1...1) -> some View {
        
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


// MARK: - Preview

#Preview(traits: .fixedLayout(width: 480, height: 280)) {
    ThemeView()
}

#Preview("ThemeEditorView", traits: .fixedLayout(width: 360, height: 280)) {
    @Previewable @State var theme = try! ThemeManager.shared.setting(name: "Anura")
    
    return ThemeEditorView(theme: $theme, isBundled: false)
}

#Preview("Metadata (editable)") {
    @Previewable @State var metadata = Theme.Metadata(
        author: "Clarus",
        distributionURL: "https://coteditor.com"
    )
    
    return ThemeMetadataView(metadata: $metadata, isEditable: true)
}

#Preview("Metadata (fixed)") {
    @Previewable @State var metadata = Theme.Metadata(
        author: "Clarus"
    )
    
    return ThemeMetadataView(metadata: $metadata, isEditable: false)
}
