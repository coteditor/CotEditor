//
//  CharacterCountOptionsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-07-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2021-2024 1024jp
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

struct CharacterCountOptionsView: View {
    
    @StateObject private var setting = CharacterCountOptionsSetting()
    
    @State private var contentWidth: CGFloat?
    
    
    var body: some View {
        
        Grid(alignment: .topLeading) {
            GridRow {
                Text("Whitespace:")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Ignore line endings", isOn: $setting.ignoresNewlines)
                    Toggle("Ignore whitespace", isOn: $setting.ignoresWhitespaces)
                    Toggle("Treat consecutive whitespace as one space", isOn: $setting.treatsConsecutiveWhitespaceAsSingle)
                        .disabled(self.setting.ignoresNewlines && self.setting.ignoresWhitespaces)
                }
            }.fixedSize()
            
            GridRow {
                Text("Unit:")
                
                VStack(alignment: .leading) {
                    Picker("Unit:", selection: $setting.unit.animation()) {
                        ForEach(CharacterCountOptions.CharacterUnit.allCases, id: \.self) {
                            Text($0.label).tag($0)
                        }
                    }.labelsHidden()
                        .fixedSize()
                    
                    Text(self.setting.unit.description)
                        .foregroundStyle(.secondary)
                        .controlSize(.small)
                        .frame(width: max(300, self.contentWidth ?? 0), alignment: .leading)
                        .fixedSize()
                    
                    if self.setting.unit == .byte {
                        Picker("Encoding:", selection: self.$setting.encoding) {
                            ForEach(String.sortedAvailableStringEncodings.indices, id: \.self) { index in
                                if let encoding = String.sortedAvailableStringEncodings[index] {
                                    Text(String.localizedName(of: encoding))
                                        .tag(Int(encoding.rawValue))
                                } else {
                                    Divider()
                                }
                            }
                        }.fixedSize()
                            .background(WidthGetter(key: WidthKey.self))
                    }
                    
                    if self.setting.unit != .graphemeCluster {
                        HStack(alignment: .firstTextBaseline) {
                            Toggle("Normalization:", isOn: $setting.normalizes)
                            Picker("Normalization:", selection: $setting.normalizationForm) {
                                Section {
                                    ForEach(UnicodeNormalizationForm.standardForms, id: \.self) { form in
                                        Text(form.localizedName).tag(form)
                                            .help(form.localizedDescription)
                                    }
                                }
                                Section {
                                    ForEach(UnicodeNormalizationForm.modifiedForms, id: \.self) { form in
                                        Text(form.localizedName).tag(form)
                                            .help(form.localizedDescription)
                                    }
                                }
                            }
                            .labelsHidden()
                            .disabled(!self.setting.normalizes)
                        }.fixedSize()
                    }
                }
            }
        }
        .onPreferenceChange(WidthKey.self) { self.contentWidth = $0 }
        .animation(.default, value: self.setting.unit)
    }
}



// MARK: Model

private extension CharacterCountOptions.CharacterUnit {
    
    var label: LocalizedStringKey {
        
        switch self {
            case .graphemeCluster: "Grapheme cluster"
            case .unicodeScalar: "Unicode scalar"
            case .utf16: "UTF-16"
            case .byte: "Byte"
        }
    }
    
    
    var description: LocalizedStringKey {
        
        switch self {
            case .graphemeCluster:
                "Count in the intuitive way defined in Unicode. A character consisting of multiple Unicode code points, such as emojis, is counted as one character."
            case .unicodeScalar:
                "Count Unicode code points. Same as counting UTF-32."
            case .utf16:
                "Count Unicode code points but a surrogate pair as two characters."
            case .byte:
                "Count bytes of the text encoded with the specified encoding."
        }
    }
}



// MARK: - Preview

#Preview {
    CharacterCountOptionsView()
}
