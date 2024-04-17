//
//  AppearanceSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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

struct AppearanceSettingsView: View {
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    @AppStorage(.font) private var font
    @AppStorage(.shouldAntialias) private var shouldAntialias
    @AppStorage(.ligature) private var ligature
    @AppStorage(.monospacedFont) private var monospacedFont
    @AppStorage(.monospacedShouldAntialias) private var monospacedShouldAntialias
    @AppStorage(.monospacedLigature) private var monospacedLigature
    
    @AppStorage(.lineHeight) private var lineHeight
    @AppStorage(.documentAppearance) private var documentAppearance
    @AppStorage(.windowAlpha) private var windowAlpha
    
    @State private var selectingFont: Data?
    @State private var isMonospacedFontAlertPresented = false
    
    
    var body: some View {
        
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 8) {
            GridRow {
                Text("Standard font:", tableName: "AppearanceSettings")
                    .gridColumnAlignment(.trailing)
                
                FontSettingView(data: $font ?? (try! FontType.standard.systemFont().archivedData), antialias: $shouldAntialias, ligature: $ligature)
            }
            
            GridRow {
                Text("Monospaced font:", tableName: "AppearanceSettings")
                    .gridColumnAlignment(.trailing)
                
                FontSettingView(data: $monospacedFont ?? (try! FontType.monospaced.systemFont().archivedData), antialias: $monospacedShouldAntialias, ligature: $monospacedLigature)
                    .onChange(of: self.monospacedFont) { [oldValue = self.monospacedFont] newValue in
                        guard
                            let newValue,
                            let font = NSFont(archivedData: newValue),
                            !font.isFixedPitch
                        else { return }
                        
                        self.selectingFont = oldValue
                        self.isMonospacedFontAlertPresented = true
                    }
                    .alert(String(localized: "The selected font doesn’t seem to be monospaced.", table: "AppearanceSettings"), isPresented: $isMonospacedFontAlertPresented, presenting: self.selectingFont) { font in
                        Button("OK") {
                            self.isMonospacedFontAlertPresented = false
                        }
                        Button("Cancel") {
                            self.monospacedFont = font
                            self.isMonospacedFontAlertPresented = false
                        }
                    } message: { _ in
                        Text("Do you want to use it for the monospaced font?", tableName: "AppearanceSettings", comment: "“it” is the selected font.")
                    }
            }
            
            GridRow {
                Text("Line height:", tableName: "AppearanceSettings")
                    .gridColumnAlignment(.trailing)
                
                HStack(alignment: .firstTextBaseline) {
                    Stepper(value: $lineHeight, in: 0.1...10, step: 0.1, format: .number.precision(.fractionLength(1...2)), label: EmptyView.init)
                        .monospacedDigit()
                        .multilineTextAlignment(self.layoutDirection == .rightToLeft ? .leading : .trailing)
                    
                    Text("times", tableName: "AppearanceSettings", comment: "unit for line height")
                }
            }
            
            GridRow {
                Text("Appearance:", tableName: "AppearanceSettings")
                    .gridColumnAlignment(.trailing)
                
                Picker(selection: $documentAppearance) {
                    ForEach(AppearanceMode.allCases, id: \.self) {
                        Text($0.label)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
                .labelsHidden()
            }
            
            GridRow(alignment: .center) {
                Text("Editor opacity:", tableName: "AppearanceSettings")
                    .gridColumnAlignment(.trailing)
                
                HStack {
                    OpacitySlider(value: $windowAlpha)
                        .frame(width: 240)
                    
                    TextField(value: $windowAlpha, format: .percent.precision(.fractionLength(0)), prompt: Text(1, format: .percent), label: EmptyView.init)
                        .monospacedDigit()
                        .environment(\.layoutDirection, .rightToLeft)
                        .frame(width: 48)
                }
            }
            
            ThemeView()
                .padding(.top, 10)
            
            HStack {
                Spacer()
                HelpButton(anchor: "settings_appearance")
            }
        }
        .scenePadding()
        .frame(minWidth: 600)
    }
}


private struct FontSettingView: View {
    
    @Binding var data: Data
    @Binding var antialias: Bool
    @Binding var ligature: Bool
    
    private var font: Binding<NSFont> {
        
        Binding(get: { NSFont(archivedData: self.data) ?? .init() },
                set: { self.data = (try? $0.archivedData) ?? self.data })
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                AntialiasingText(self.displayFontName)
                    .antialiasDisabled(!self.antialias)
                    .font(nsFont: self.font.wrappedValue.withSize(0))
                    .help(self.displayFontName)
                    .frame(maxWidth: 260)
                    .alignmentGuide(.firstTextBaseline) { $0.height }
                FontPicker(String(localized: "Select…", table: "AppearanceSettings", comment: "label for font picker button"), selection: self.font)
            }
            HStack {
                Toggle(String(localized: "Antialias", table: "AppearanceSettings"), isOn: $antialias)
                Toggle(String(localized: "Ligatures", table: "AppearanceSettings"), isOn: $ligature)
            }.controlSize(.small)
        }
    }
    
    
    /// Returns the font name and size to display.
    private var displayFontName: String {
        
        let font = self.font.wrappedValue
        
        return "\(font.displayName ?? font.fontName)  \(font.pointSize.formatted())"
    }
}


private struct ThemeView: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = ThemeViewController
    
    
    func makeNSViewController(context: Context) -> ThemeViewController {
        
        NSStoryboard(name: "ThemeView", bundle: nil).instantiateInitialController()!
    }
    
    func updateNSViewController(_ nsViewController: ThemeViewController, context: Context) {
        
    }
}


private extension AppearanceMode {
    
    var label: String {
        
        switch self {
            case .default:
                String(localized: "AppearanceMode.automatic.label",
                       defaultValue: "Match System",
                       table: "AppearanceSettings")
            case .light:
                String(localized: "AppearanceMode.light.label",
                       defaultValue: "Light",
                       table: "AppearanceSettings")
            case .dark:
                String(localized: "AppearanceMode.dark.label",
                       defaultValue: "Dark",
                       table: "AppearanceSettings")
        }
    }
}



// MARK: - Preview

#Preview {
    AppearanceSettingsView()
}

#Preview("FontSettingView") {
    @State var antialias = false
    @State var ligature = false
    
    return FontSettingView(data: .constant(Data()), antialias: $antialias, ligature: $ligature)
        .padding()
}
