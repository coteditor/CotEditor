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
//  © 2023-2024 1024jp
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

struct ModeSettingsView: View {
    
    @State private var selection: Mode = .kind(.general)
    @State private var options: ModeOptions = .init()
    
    
    var body: some View {
        
        VStack {
            HStack {
                ModeListView(selection: $selection)
                    .frame(width: 120)
                
                GroupBox {
                    ModeOptionsView(options: $options)
                        .disabled(!self.selection.available)
                        .onChange(of: self.options) { newValue in
                            Task {
                                await ModeManager.shared.save(setting: newValue, mode: self.selection)
                            }
                        }
                        .frame(maxWidth: .infinity)
                }
            }
            
            HStack {
                Spacer()
                HelpButton(anchor: "settings_mode")
            }
        }
        .task {
            self.options = await ModeManager.shared.setting(for: self.selection)
        }
        .onChange(of: self.selection) { mode in  // migrate to .onChange(of:initial:...
            Task {
                self.options = await ModeManager.shared.setting(for: mode)
            }
        }
        .scenePadding()
        .frame(minWidth: 600, idealWidth: 600)
    }
}


private struct ModeListView: View {
    
    @Binding var selection: Mode
    
    @State private var syntaxModes: [Mode] = []
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            List(selection: $selection) {
                Section(String(localized: "Mode", table: "ModeSettings")) {
                    ForEach(Syntax.Kind.allCases, id: \.self) { kind in
                        Text(kind.label)
                            .tag(Mode.kind(kind))
                            .listRowSeparator(.hidden)
                    }
                }
                
                if !self.syntaxModes.isEmpty {
                    Section(String(localized: "Syntax", table: "ModeSettings")) {
                        ForEach(self.syntaxModes, id: \.self) { mode in
                            let available = mode.available
                            HStack {
                                Text(mode.label)
                                if !available {
                                    Spacer()
                                    Image(systemName: "exclamationmark.triangle")
                                        .accessibilityLabel(String(localized: "Not found", table: "ModeSettings", comment: "accessibility label"))
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
            
            Divider()
                .padding(.horizontal, 6)
            
            HStack(spacing: 0) {
                Menu {
                    Section(String(localized: "Syntax", table: "ModeSettings")) {
                        ForEach(SyntaxManager.shared.settingNames, id: \.self) { syntaxName in
                            Button(syntaxName) {
                                Task {
                                    await ModeManager.shared.addSetting(for: syntaxName)
                                    let syntaxModes = await ModeManager.shared.syntaxModes
                                    withAnimation {
                                        self.syntaxModes = syntaxModes
                                        self.selection = .syntax(syntaxName)
                                    }
                                }
                            }.disabled(self.syntaxModes.compactMap(\.syntaxName).contains(syntaxName))
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .padding(4)
                .menuIndicator(.hidden)
                .accessibilityLabel(String(localized: "Add", table: "ModeSettings"))
                
                Button {
                    Task {
                        await ModeManager.shared.removeSetting(for: self.selection)
                        let syntaxModes = await ModeManager.shared.syntaxModes
                        withAnimation {
                            self.syntaxModes = syntaxModes
                            self.selection = .kind(.general)
                        }
                    }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 14, height: 14)
                        .fontWeight(.medium)
                }
                .padding(4)
                .accessibilityLabel(String(localized: "Remove", table: "ModeSettings"))
                .disabled(self.selection.syntaxName == nil)
            }
            .padding(2)
            .buttonStyle(.borderless)
        }
        .task {
            self.syntaxModes = await ModeManager.shared.syntaxModes
        }
        .border(.separator)
        .background()
    }
}



private struct ModeOptionsView: View {
    
    @Binding var options: ModeOptions
    
    @Environment(\.isEnabled) var isEnabled
    
    
    var body: some View {
        
        Form {
            Picker(String(localized: "Font:", table: "ModeSettings"), selection: $options.fontType) {
                ForEach(FontType.allCases, id: \.self) { type in
                    Text(type.label)
                }
            }
            .pickerStyle(.radioGroup)
            .horizontalRadioGroupLayout()
            .padding(.bottom, 8)
            
            LabeledContent(String(localized: "Substitution:", table: "ModeSettings")) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(String(localized: "Smart copy/paste", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.smartInsertDelete)
                    Toggle(String(localized: "Smart quotes", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticQuoteSubstitution)
                    Toggle(String(localized: "Smart dashes", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticDashSubstitution)
                    Toggle(String(localized: "Automatically insert closing brackets and quotes", table: "ModeSettings"),
                           isOn: $options.automaticSymbolBalancing)
                }
            }
            .padding(.bottom, 8)
            
            LabeledContent(String(localized: "Spelling:", table: "ModeSettings")) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(String(localized: "Check spelling while typing", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.continuousSpellChecking)
                    Toggle(String(localized: "Check grammar with spelling", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.grammarChecking)
                    Toggle(String(localized: "Correct spelling automatically", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticSpellingCorrection)
                }
            }
            .padding(.bottom, 8)
            
            LabeledContent(String(localized: "Completion:", table: "ModeSettings")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Completion list includes:", tableName: "ModeSettings")
                        .foregroundStyle(self.isEnabled ? .primary : .tertiary)
                    Group {
                        Toggle(String(localized: "Standard words", table: "ModeSettings"),
                               isOn: $options.completionWordTypes.bind(.standard))
                        Toggle(String(localized: "Words in document", table: "ModeSettings"),
                               isOn: $options.completionWordTypes.bind(.document))
                        Toggle(String(localized: "Words defined in syntax", table: "ModeSettings"),
                               isOn: $options.completionWordTypes.bind(.syntax))
                    }.padding(.leading, 20)
                    Toggle(String(localized: "Suggest completions while typing", table: "ModeSettings"),
                           isOn: $options.automaticCompletion)
                    .disabled(self.options.completionWordTypes.isEmpty)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(10)
    }
}


private extension Mode {
    
    /// Syntax name for `case .syntax`.
    var syntaxName: String? {
        
        switch self {
            case .kind:
                nil
            case .syntax(let name):
                name
        }
    }
    
    
    /// Localized name to display for user.
    var label: String {
        
        switch self {
            case .kind(let kind):
                kind.label
            case .syntax(let name):
                name
        }
    }
    
    
    /// Whether the given mode is available in the current user environment.
    var available: Bool {
        
        switch self {
            case .kind: true
            case .syntax(let name): SyntaxManager.shared.settingNames.contains(name)
        }
    }
}


private extension FontType {
    
    var label: String {
        
        switch self {
            case .standard:
                String(localized: "FontType.standard.label",
                       defaultValue: "Standard",
                       table: "ModeSettings")
            case .monospaced:
                String(localized: "FontType.monospaced.label",
                       defaultValue: "Monospaced",
                       table: "ModeSettings")
        }
    }
}



// MARK: - Preview

#Preview {
    ModeSettingsView()
}
