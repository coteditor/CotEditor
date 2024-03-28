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
                Text("Whitespace:", tableName: "AdvancedCharacterCount", comment: "label")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(String(localized: "Ignore line endings", table: "AdvancedCharacterCount", comment: "setting option"),
                           isOn: $setting.ignoresNewlines)
                    Toggle(String(localized: "Ignore whitespace", table: "AdvancedCharacterCount", comment: "setting option"),
                           isOn: $setting.ignoresWhitespaces)
                    Toggle(String(localized: "Treat consecutive whitespace as one space", table: "AdvancedCharacterCount", comment: "setting option"),
                           isOn: $setting.treatsConsecutiveWhitespaceAsSingle)
                    .disabled(self.setting.ignoresNewlines && self.setting.ignoresWhitespaces)
                }
            }.fixedSize()
            
            GridRow {
                Text("Unit:", tableName: "AdvancedCharacterCount", comment: "label")
                
                VStack(alignment: .leading) {
                    Picker(selection: $setting.unit.animation()) {
                        ForEach(CharacterCountOptions.CharacterUnit.allCases, id: \.self) {
                            Text($0.label)
                        }
                    } label: {
                        EmptyView()
                    }.fixedSize()

                    
                    Text(self.setting.unit.description)
                        .foregroundStyle(.secondary)
                        .controlSize(.small)
                        .frame(width: max(300, self.contentWidth ?? 0), alignment: .leading)
                    
                    if self.setting.unit == .byte {
                        Picker(String(localized: "Encoding:", table: "AdvancedCharacterCount", comment: "label"), selection: self.$setting.encoding) {
                            ForEach(String.sortedAvailableStringEncodings.indices, id: \.self) { index in
                                if let encoding = String.sortedAvailableStringEncodings[index] {
                                    Text(String.localizedName(of: encoding))
                                        .tag(Int(encoding.rawValue))
                                } else {
                                    Divider()
                                }
                            }
                        }.fixedSize()
                            .background(SizeGetter(key: MaxSizeKey.self))
                    }
                    
                    if self.setting.unit != .graphemeCluster {
                        Toggle(isOn: $setting.normalizes) {
                            Picker(String(localized: "Normalization:", table: "AdvancedCharacterCount", comment: "label"), selection: $setting.normalizationForm) {
                                Section {
                                    ForEach(UnicodeNormalizationForm.standardForms, id: \.self) { form in
                                        Text(form.localizedName)
                                            .help(form.localizedDescription)
                                    }
                                }
                                Section {
                                    ForEach(UnicodeNormalizationForm.modifiedForms, id: \.self) { form in
                                        Text(form.localizedName)
                                            .help(form.localizedDescription)
                                    }
                                }
                            }
                            .disabled(!self.setting.normalizes)
                            .fixedSize()
                        }
                    }
                }
            }
        }
        .onPreferenceChange(MaxSizeKey.self) { self.contentWidth = $0.width }
        .animation(.default, value: self.setting.unit)
    }
}



// MARK: Model

private extension CharacterCountOptions.CharacterUnit {
    
    var label: String {
        
        switch self {
            case .graphemeCluster:
                String(localized: "CharacterUnit.graphemeCluster.label",
                       defaultValue: "Grapheme cluster",
                       table: "AdvancedCharacterCount",
                       comment: "count unit (technical term defined in Unicode)")
            case .unicodeScalar:
                String(localized: "CharacterUnit.unicodeScalar.label",
                       defaultValue: "Unicode scalar",
                       table: "AdvancedCharacterCount",
                       comment: "count unit")
            case .utf16:
                String(localized: "CharacterUnit.utf16.label",
                       defaultValue: "UTF-16",
                       table: "AdvancedCharacterCount",
                       comment: "count unit")
            case .byte:
                String(localized: "CharacterUnit.byte.label",
                       defaultValue: "Byte",
                       table: "AdvancedCharacterCount",
                       comment: "count unit")
        }
    }
    
    
    var description: String {
        
        switch self {
            case .graphemeCluster:
                String(localized: "CharacterUnit.graphemeCluster.description",
                       defaultValue: "Count in the intuitive way defined in Unicode. A character consisting of multiple Unicode code points, such as emojis, is counted as one character.",
                       table: "AdvancedCharacterCount",
                       comment: "description for grapheme cluster")
            case .unicodeScalar:
                String(localized: "CharacterUnit.unicodeScalar.description",
                       defaultValue: "Count Unicode code points. Same as counting UTF-32.",
                       table: "AdvancedCharacterCount",
                       comment: "description for unicode scalar")
            case .utf16:
                String(localized: "CharacterUnit.utf16.description",
                       defaultValue: "Count Unicode code points but a surrogate pair as two characters.",
                       table: "AdvancedCharacterCount",
                       comment: "description for UTF-16")
            case .byte:
                String(localized: "CharacterUnit.byte.description",
                       defaultValue: "Count bytes of the text encoded with the specified encoding.",
                       table: "AdvancedCharacterCount",
                       comment: "description for byte")
        }
    }
}



// MARK: - Preview

#Preview {
    CharacterCountOptionsView()
        .scenePadding()
}
