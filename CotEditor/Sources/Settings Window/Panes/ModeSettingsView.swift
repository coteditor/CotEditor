//
//  ModeSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-09-13.
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
import Defaults
import SyntaxFormat

struct ModeSettingsView: View {
    
    private var manager: ModeManager = .shared
    
    @State private var syntaxes: [String] = []
    @State private var selection: Mode = .kind(.general)
    @State private var options: ModeOptions = .init()
    
    
    var body: some View {
        
        VStack {
            HStack {
                ModeListView(manager: self.manager, selection: $selection, options: $options, syntaxes: self.syntaxes)
                    .frame(width: 120)
                
                GroupBox {
                    ModeOptionsView(options: $options)
                        .disabled(!self.selection.available(within: self.syntaxes))
                        .onChange(of: self.options) { _, newValue in
                            self.manager.save(setting: newValue, mode: self.selection)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(self.selection.label)
                }
            }
            
            HStack {
                Spacer()
                HelpLink(anchor: "settings_mode")
            }
        }
        .onAppear {
            self.syntaxes = SyntaxManager.shared.settingNames
        }
        .onChange(of: self.selection, initial: true) { _, newValue in
            self.options = self.manager.setting(for: newValue)
        }
    }
}


private struct ModeListView: View {
    
    var manager: ModeManager
    
    @Binding var selection: Mode
    @Binding var options: ModeOptions
    
    var syntaxes: [String]
    @State private var syntaxModes: [Mode] = []
    @State private var error: any Error?
    
    
    var body: some View {
        
        List(selection: $selection) {
            Section(.init("Mode", table: "ModeSettings")) {
                ForEach(Syntax.Kind.allCases, id: \.self) { kind in
                    Text(kind.label)
                        .tag(Mode.kind(kind))
                        .listRowSeparator(.hidden)
                }
            }
            
            if !self.syntaxModes.isEmpty {
                Section(.init("Syntax", table: "ModeSettings")) {
                    ForEach(self.syntaxModes, id: \.self) { mode in
                        let available = mode.available(within: self.syntaxes)
                        HStack {
                            Text(mode.label)
                            if !available {
                                Spacer()
                                Label(.init("Not found", table: "ModeSettings", comment: "accessibility label"), systemImage: "exclamationmark.triangle")
                                    .labelStyle(.iconOnly)
                            }
                        }
                        .tag(mode)
                        .foregroundStyle(available ? .primary : .secondary)
                        .lineLimit(1)
                        .help(available ? "" : String(localized: "This syntax does not exist", table: "ModeSettings", comment: "tooltip"))
                        .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .safeAreaBar(edge: .bottom) {
            if #available(macOS 27, *) {
                self.bottomAccessoryView
                    .padding(6)
            } else {
                VStack(spacing: 0) {
                    Divider()
                    self.bottomAccessoryView
                        .padding(6)
                }
            }
        }
        .scrollEdgeEffectStyle(.hard, for: .bottom)
        .clipShape(.rect(cornerRadius: 7, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(.separator))
        .contextMenu(forSelectionType: Mode.self) { selections in
            if let selection = selections.first {
                self.contextMenu(for: selection)
            }
        }
        .onAppear {
            self.syntaxModes = self.manager.syntaxModes
        }
        .accessibilityLabel(.init("Mode", table: "ModeSettings"))
    }
    
    
    /// The action buttons to place at the bottom of the list.
    @ContentBuilder private var bottomAccessoryView: some View {
        
        HStack {
            Menu {
                Section(.init("Syntax", table: "ModeSettings")) {
                    ForEach(self.syntaxes, id: \.self) { syntaxName in
                        Button(syntaxName) {
                            do {
                                try self.manager.addSetting(for: syntaxName)
                            } catch {
                                self.error = error
                            }
                            let syntaxModes = self.manager.syntaxModes
                            withAnimation {
                                self.syntaxModes = syntaxModes
                                self.selection = .syntax(syntaxName)
                            }
                        }.disabled(self.syntaxModes.compactMap(\.syntaxName).contains(syntaxName))
                    }
                }
            } label: {
                Label(.init("Action.add.label", defaultValue: "Add"), systemImage: "plus")
                    .padding(2)
            }
            .help(.init("Action.add.tooltip", defaultValue: "Add new item"))
            .menuIndicator(.hidden)
            .alert(error: $error)
            
            Button {
                self.manager.removeSetting(for: self.selection)
                let syntaxModes = self.manager.syntaxModes
                withAnimation {
                    self.syntaxModes = syntaxModes
                    self.selection = .kind(.general)
                }
            } label: {
                Label(.init("Action.delete.label", defaultValue: "Delete"), systemImage: "minus")
                    .padding(2)
                    .fontWeight(.medium)
            }
            .help(.init("Action.delete.tooltip", defaultValue: "Delete selected items"))
            .frame(width: 16)
            .disabled(self.selection.syntaxName == nil)
            
            Spacer()
        }
        .buttonStyle(.borderless)
        .labelStyle(.iconOnly)
    }
    
    
    /// Builds the context menu for a list item.
    ///
    /// - Parameter mode: The mode represented by the selected row.
    /// - Returns: The context menu content.
    @ContentBuilder private func contextMenu(for mode: Mode) -> some View {
        
        if case .kind(let kind) = mode {
            let defaultOptions = kind.defaultOptions
            
            Button(.init("Action.restore.label", defaultValue: "Restore")) {
                self.manager.save(setting: defaultOptions, mode: mode)
                if self.selection == mode {
                    self.options = defaultOptions
                }
            }
            .disabled(self.manager.setting(for: mode) == defaultOptions)
        }
    }
}


private struct ModeOptionsView: View {
    
    @Binding var options: ModeOptions
    
    @Environment(\.isEnabled) private var isEnabled
    
    
    var body: some View {
        
        Form {
            Picker(.init("Font:", table: "ModeSettings"), selection: $options.fontType) {
                ForEach(FontType.allCases, id: \.self) { type in
                    Text(type.label)
                }
            }
            .pickerStyle(.radioGroup)
            .horizontalRadioGroupLayout()
            .padding(.bottom, 12)
            
            LabeledContent(.init("Substitution:", table: "ModeSettings")) {
                VStack(alignment: .leading) {
                    Toggle(.init("Smart copy/paste", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.smartInsertDelete)
                    Toggle(.init("Smart quotes", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticQuoteSubstitution)
                    Toggle(.init("Smart dashes", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticDashSubstitution)
                    Toggle(.init("Text replacement", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticTextReplacement)
                    Toggle(.init("Add period with double-space", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticPeriodSubstitution)
                    Toggle(.init("Automatically insert closing brackets and quotes", table: "ModeSettings"),
                           isOn: $options.automaticSymbolBalancing)
                }
                .fixedSize(horizontal: false, vertical: true)  // allow line break in Toggle
            }
            .padding(.bottom, 12)
            
            LabeledContent(.init("Spelling:", table: "ModeSettings")) {
                VStack(alignment: .leading) {
                    Toggle(.init("Check spelling while typing", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.continuousSpellChecking)
                    Toggle(.init("Check grammar with spelling", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.grammarChecking)
                    Toggle(.init("Correct spelling automatically", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticSpellingCorrection)
                }
                .fixedSize(horizontal: false, vertical: true)  // allow line break in Toggle
            }
            .padding(.bottom, 12)
            
            LabeledContent(.init("Completion:", table: "ModeSettings")) {
                VStack(alignment: .leading) {
                    Text("Completion list includes:", tableName: "ModeSettings")
                        .foregroundStyle(self.isEnabled ? .primary : .tertiary)
                    Group {
                        Toggle(.init("Standard words", table: "ModeSettings"),
                               isOn: $options.completionWordTypes.bind(.standard))
                        Toggle(.init("Words in document", table: "ModeSettings"),
                               isOn: $options.completionWordTypes.bind(.document))
                        Toggle(.init("Words defined in syntax", table: "ModeSettings"),
                               isOn: $options.completionWordTypes.bind(.syntax))
                    }.padding(.leading, 20)
                    Toggle(.init("Suggest completions while typing", table: "ModeSettings"),
                           isOn: $options.automaticCompletion)
                    .disabled(self.options.completionWordTypes.isEmpty)
                }
            }
            .padding(.bottom, 12)
            
            LabeledContent(.init("Indentation:", table: "ModeSettings")) {
                ModeIndentOptionsView(options: $options.indentOptions)
            }
        }
    }
}


private struct ModeIndentOptionsView: View {
    
    @Binding var options: ModeOptions.IndentOptions?
    
    
    @Namespace private var accessibility
    
    @AppStorage(.autoExpandTab) private var defaultExpandsTab
    @AppStorage(.tabWidth) private var defaultIndentWidth
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Toggle(.init("Use custom settings", table: "ModeSettings"),
                   isOn: self.usesCustomIndentation)
            
            Group {
                HStack(alignment: .firstTextBaseline) {
                    Text(.init("Prefer using", table: "EditSettings"))
                        .accessibilityLabeledPair(role: .label, id: "expandsTab", in: self.accessibility)
                    Picker(selection: self.expandsTab) {
                        Text("Spaces", tableName: "EditSettings", comment: "indent style").tag(true)
                        Text("Tabs", tableName: "EditSettings", comment: "indent style").tag(false)
                    } label: {
                        EmptyView()
                    }
                    .accessibilityLabeledPair(role: .content, id: "expandsTab", in: self.accessibility)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    Text("Indent width:", tableName: "EditSettings")
                        .accessibilityLabeledPair(role: .label, id: "indentWidth", in: self.accessibility)
                    StepperNumberField(value: self.indentWidth, default: self.defaultIndentWidth, in: 1...99)
                        .accessibilityLabeledPair(role: .content, id: "indentWidth", in: self.accessibility)
                    Text("spaces", tableName: "EditSettings", comment: "unit for indentation")
                }
            }
            .labelsHidden()
            .disabled(self.options == nil)
            .foregroundStyle(self.options != nil ? .primary : .tertiary)
            .padding(.leading, 20)
        }
    }
    
    
    /// Whether the mode uses custom indentation settings.
    private var usesCustomIndentation: Binding<Bool> {
        
        Binding(
            get: { self.options != nil },
            set: { self.options = $0 ? .init(expandsTab: self.defaultExpandsTab, width: self.defaultIndentWidth) : nil })
    }
    
    
    /// Whether tabs are expanded in the custom indentation settings.
    private var expandsTab: Binding<Bool> {
        
        Binding(
            get: { self.options?.expandsTab ?? self.defaultExpandsTab },
            set: { self.options?.expandsTab = $0 })
    }
    
    
    /// The custom indentation width.
    private var indentWidth: Binding<Int> {
        
        Binding(
            get: { self.options?.width ?? self.defaultIndentWidth },
            set: { self.options?.width = $0 })
    }
}


private extension Mode {
    
    /// Syntax name for `case .syntax`.
    var syntaxName: String? {
        
        switch self {
            case .kind: nil
            case .syntax(let name): name
        }
    }
    
    
    /// Whether the given mode is available in the current user environment.
    ///
    /// - Parameter syntaxes: The available syntax names.
    /// - Returns: `true` if available.
    func available(within syntaxes: [String]) -> Bool {
        
        switch self {
            case .kind: true
            case .syntax(let name): syntaxes.contains(name)
        }
    }
}


private extension FontType {
    
    var label: LocalizedStringResource {
        
        switch self {
            case .standard:
                .init("FontType.standard.label", defaultValue: "Standard", table: "ModeSettings")
            case .monospaced:
                .init("FontType.monospaced.label", defaultValue: "Monospaced", table: "ModeSettings")
        }
    }
}


// MARK: - Preview

#Preview {
    ModeSettingsView()
        .scenePadding()
}
