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
//  © 2014-2026 1024jp
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

struct AppearanceSettingsView: View {
    
    private static let windowAlphaRange = 0.2...1.0
    private static let verticalSpace: CGFloat = 6
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    @AppStorage(.font) private var font
    @AppStorage(.shouldAntialias) private var shouldAntialias
    @AppStorage(.ligature) private var ligature
    @AppStorage(.monospacedFont) private var monospacedFont
    @AppStorage(.monospacedShouldAntialias) private var monospacedShouldAntialias
    @AppStorage(.monospacedLigature) private var monospacedLigature
    
    @AppStorage(.lineHeight) private var lineHeight
    @AppStorage(.documentAppearance) private var documentAppearance
    @AppStorage(.prefersOpaqueBarBackground) private var prefersOpaqueBarBackground
    @AppStorage(.windowAlpha) private var windowAlpha
    
    @State private var monospacedAlertFont: Data?
    @State private var isRestoringMonospacedFont = false
    
    
    var body: some View {
        
        Form {
            LabeledContent(.init("Standard font:", table: "AppearanceSettings")) {
                FontSettingView(data: $font, fallback: FontType.standard.systemFont(), antialias: $shouldAntialias, ligature: $ligature)
            }
            .padding(.bottom, Self.verticalSpace)
            
            LabeledContent(.init("Monospaced font:", table: "AppearanceSettings")) {
                FontSettingView(data: $monospacedFont, fallback: FontType.monospaced.systemFont(), antialias: $monospacedShouldAntialias, ligature: $monospacedLigature)
                    .onChange(of: self.monospacedFont) { oldValue, newValue in
                        if self.isRestoringMonospacedFont {
                            self.isRestoringMonospacedFont = false
                            return
                        }
                        guard
                            let newValue,
                            let font = NSFont(archivedData: newValue),
                            !font.isFixedPitch
                        else { return }
                        
                        // ignore if only font size changed
                        if let oldValue,
                           let oldFont = NSFont(archivedData: oldValue),
                           font.fontName == oldFont.fontName
                        { return }
                        
                        self.monospacedAlertFont = oldValue
                    }
                    .alert(.init("MonospacedFontAlert.title", defaultValue: "The selected font doesn’t seem to be monospaced.", table: "AppearanceSettings"), item: $monospacedAlertFont) { font in
                        Button(.ok) { }
                        Button(role: .cancel) {
                            self.isRestoringMonospacedFont = true
                            self.monospacedFont = font
                        }
                    } message: { _ in
                        Text(.init("MonospacedFontAlert.message", defaultValue: "Do you want to use it for the monospaced font?", table: "AppearanceSettings", comment: "“it” is the selected font in the title."))
                    }
            }
            .padding(.bottom, Self.verticalSpace)
            
            LabeledContent(.init("Line height:", table: "AppearanceSettings")) {
                HStack(alignment: .firstTextBaseline) {
                    Stepper(value: $lineHeight, in: 0.1...10, step: 0.1, format: .number.precision(.fractionLength(1...2)).numberLocale, label: EmptyView.init)
                        .monospacedDigit()
                        .multilineTextAlignment(self.layoutDirection == .rightToLeft ? .leading : .trailing)
                        .accessibilityValue(.init("\(self.lineHeight, format: .number) times", table: "AppearanceSettings",
                                                  comment: "accessibility label for line height"))
                    
                    Text("times", tableName: "AppearanceSettings", comment: "unit for line height")
                        .accessibilityHidden(true)
                }
                .labelsHidden()
            }
            .padding(.bottom, Self.verticalSpace)
            
            Picker(.init("Appearance:", table: "AppearanceSettings"), selection: $documentAppearance) {
                ForEach(AppearanceMode.allCases, id: \.self) {
                    Text($0.label)
                }
            }
            .pickerStyle(.radioGroup)
            .horizontalRadioGroupLayout()
            .padding(.bottom, Self.verticalSpace)
            
            Picker(.init("Status bar:", table: "AppearanceSettings"), selection: $prefersOpaqueBarBackground) {
                Text("Tinted", tableName: "AppearanceSettings")
                    .tag(false)
                Text("Opaque", tableName: "AppearanceSettings")
                    .tag(true)
            }
            .pickerStyle(.radioGroup)
            .horizontalRadioGroupLayout()
            .padding(.bottom, Self.verticalSpace)
            
            LabeledContent(.init("Editor opacity:", table: "AppearanceSettings")) {
                HStack(alignment: .firstTextBaseline) {
                    Slider(value: self.windowAlphaBinding, enabledBounds: Self.windowAlphaRange) {
                        EmptyView()
                    } currentValueLabel: {
                        Text(self.windowAlphaBinding.wrappedValue, format: .percent)
                    } minimumValueLabel: {
                        OpacitySample(opacity: Self.windowAlphaRange.lowerBound)
                            .frame(height: 20)
                            .help(.init("OpacitySlider.minimumValue.label", defaultValue: "Transparent", table: "AppearanceSettings"))
                    } maximumValueLabel: {
                        OpacitySample(opacity: Self.windowAlphaRange.upperBound)
                            .frame(height: 20)
                            .help(.init("OpacitySlider.maximumValue.label", defaultValue: "Opaque", table: "AppearanceSettings"))
                    } ticks: {
                        SliderTickContentForEach(Array(stride(from: ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 ? 0.2 : 0, through: 1, by: 0.1)), id: \.self) { value in
                            SliderTick(value)
                        }
                    }
                    .frame(maxWidth: 260)
                    
                    TextField(value: self.windowAlphaBinding, format: .percent.precision(.fractionLength(0)), prompt: Text(1, format: .percent), label: EmptyView.init)
                        .monospacedDigit()
                        .multilineTextAlignment(self.layoutDirection == .rightToLeft ? .leading : .trailing)
                        .frame(width: 64)
                }
                .labelsHidden()
            }
            .accessibilityElement(children: .contain)
        }
        .padding(.bottom)
        
        ThemeView()
        
        HStack {
            Spacer()
            HelpLink(anchor: "settings_appearance")
        }
    }
    
    
    /// A binding for the editor opacity clamped to the supported range.
    private var windowAlphaBinding: Binding<Double> {
        
        Binding(get: { self.windowAlpha.clamped(to: Self.windowAlphaRange) },
                set: { self.windowAlpha = $0.clamped(to: Self.windowAlphaRange) })
    }
}


private struct FontSettingView: View {
    
    @Binding var data: Data?
    var fallback: NSFont
    @Binding var antialias: Bool
    @Binding var ligature: Bool
    
    private var font: Binding<NSFont> {
        
        Binding(get: { self.data.flatMap(NSFont.init(archivedData:)) ?? self.fallback },
                set: { self.data = (try? $0.archivedData) ?? self.data })
    }
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                let font = self.font.wrappedValue
                
                AntialiasingText(font.displayNameAndSize)
                    .antialiasDisabled(!self.antialias)
                    .font(nsFont: font.withSize(0))
                    .help(font.displayNameAndSize)
                    .frame(maxWidth: 260)
                    .alignmentGuide(.firstTextBaseline, computeValue: \.height)
                FontSizeStepper(.init("Font size", table: "AppearanceSettings"), font: self.font)
                    .accessibilityValue(.init("\(font.pointSize, format: .number) points",
                                              table: "AppearanceSettings", comment: "accessibility label for font size"))
                    .labelsHidden()
                    .padding(.leading, -4)
                FontPicker(.init("Select…", table: "AppearanceSettings", comment: "label for font picker button"), selection: self.font)
            }
            HStack {
                Toggle(.init("Antialias", table: "AppearanceSettings"), isOn: $antialias)
                Toggle(.init("Ligatures", table: "AppearanceSettings"), isOn: $ligature)
            }.controlSize(.small)
        }
    }
}


private extension NSFont {
    
    /// Returns the font name and size to display.
    var displayNameAndSize: String {
        
        "\(self.displayName ?? self.fontName)  \(self.pointSize.formatted())"
    }
}


private extension AppearanceMode {
    
    var label: LocalizedStringResource {
        
        switch self {
            case .default:
                .init("AppearanceMode.automatic.label",
                      defaultValue: "Match System",
                      table: "AppearanceSettings")
            case .light:
                .init("AppearanceMode.light.label",
                      defaultValue: "Light",
                      table: "AppearanceSettings")
            case .dark:
                .init("AppearanceMode.dark.label",
                      defaultValue: "Dark",
                      table: "AppearanceSettings")
        }
    }
}


// MARK: - Preview

#Preview {
    AppearanceSettingsView()
        .scenePadding()
}

#Preview("FontSettingView") {
    @Previewable @State var antialias = false
    @Previewable @State var ligature = false
    
    FontSettingView(data: .constant(Data()), fallback: .systemFont(ofSize: 0), antialias: $antialias, ligature: $ligature)
        .scenePadding()
}
