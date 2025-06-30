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
import Syntax

struct ModeSettingsView: View {
    
    private var manager: ModeManager = .shared
    
    @State private var syntaxes: [String] = []
    @State private var selection: Mode = .kind(.general)
    @State private var options: ModeOptions = .init()
    
    
    var body: some View {
        
        VStack {
            HStack {
                ModeListView(manager: self.manager, selection: $selection, syntaxes: self.syntaxes)
                    .frame(width: 120)
                
                GroupBox {
                    ModeOptionsView(options: $options)
                        .disabled(!self.selection.available(within: self.syntaxes))
                        .onChange(of: self.options) { (_, newValue) in
                            self.manager.save(setting: newValue, mode: self.selection)
                        }
                        .frame(maxWidth: .infinity)
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
        .onChange(of: self.selection, initial: true) { (_, newValue) in
            self.options = self.manager.setting(for: newValue)
        }
        .padding(.top, 14)
        .scenePadding([.horizontal, .bottom])
        .frame(minWidth: 600, idealWidth: 600)
    }
}


private struct ModeListView: View {
    
    var manager: ModeManager
    
    @Binding var selection: Mode
    
    var syntaxes: [String]
    @State private var syntaxModes: [Mode] = []
    @State private var error: (any Error)?
    
    
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
                            let available = mode.available(within: self.syntaxes)
                            HStack {
                                Text(mode.label)
                                if !available {
                                    Spacer()
                                    Label(String(localized: "Not found", table: "ModeSettings", comment: "accessibility label"), systemImage: "exclamationmark.triangle")
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
            
            Divider()
                .padding(.horizontal, 6)
            
            HStack(spacing: 0) {
                Menu(String(localized: "Button.add.label", defaultValue: "Add", table: "Control"), systemImage: "plus") {
                    Section(String(localized: "Syntax", table: "ModeSettings")) {
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
                }
                .padding(EdgeInsets(top: 4, leading: 2, bottom: 4, trailing: 2))
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
                    Label(String(localized: "Button.remove.label", defaultValue: "Remove", table: "Control"), systemImage: "minus")
                        .frame(width: 14, height: 14)
                        .fontWeight(.medium)
                }
                .padding(EdgeInsets(top: 4, leading: 2, bottom: 4, trailing: 2))
                .disabled(self.selection.syntaxName == nil)
            }
            .padding(2)
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
        .onAppear {
            self.syntaxModes = self.manager.syntaxModes
        }
        .border(.separator)
        .background()
    }
}


private struct ModeOptionsView: View {
    
    @Binding var options: ModeOptions
    
    @Environment(\.isEnabled) private var isEnabled
    
    
    var body: some View {
        
        Form {
            Picker(String(localized: "Font:", table: "ModeSettings"), selection: $options.fontType) {
                ForEach(FontType.allCases, id: \.self) { type in
                    Text(type.label)
                }
            }
            .pickerStyle(.radioGroup)
            .horizontalRadioGroupLayout()
            .padding(.bottom, isLiquidGlass ? 12 : 8)
            
            LabeledContent(String(localized: "Substitution:", table: "ModeSettings")) {
                VStack(alignment: .leading, spacing: isLiquidGlass ? nil : 6) {
                    Toggle(String(localized: "Smart copy/paste", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.smartInsertDelete)
                    Toggle(String(localized: "Smart quotes", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticQuoteSubstitution)
                    Toggle(String(localized: "Smart dashes", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticDashSubstitution)
                    Toggle(String(localized: "Text replacement", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticTextReplacement)
                    Toggle(String(localized: "Add period with double-space", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticPeriodSubstitution)
                    Toggle(String(localized: "Automatically insert closing brackets and quotes", table: "ModeSettings"),
                           isOn: $options.automaticSymbolBalancing)
                }
            }
            .padding(.bottom, isLiquidGlass ? 12 : 8)
            
            LabeledContent(String(localized: "Spelling:", table: "ModeSettings")) {
                VStack(alignment: .leading, spacing: isLiquidGlass ? nil : 6) {
                    Toggle(String(localized: "Check spelling while typing", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.continuousSpellChecking)
                    Toggle(String(localized: "Check grammar with spelling", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.grammarChecking)
                    Toggle(String(localized: "Correct spelling automatically", table: "ModeSettings", comment: "use localization provided by Apple"),
                           isOn: $options.automaticSpellingCorrection)
                }
            }
            .padding(.bottom, isLiquidGlass ? 12 : 8)
            
            LabeledContent(String(localized: "Completion:", table: "ModeSettings")) {
                VStack(alignment: .leading, spacing: isLiquidGlass ? nil : 6) {
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
