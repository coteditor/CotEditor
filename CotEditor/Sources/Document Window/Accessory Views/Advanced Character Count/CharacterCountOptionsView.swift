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
//  © 2021-2025 1024jp
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
import StringUtils

extension UnicodeNormalizationForm: @retroactive DefaultInitializable {

    public static let defaultValue: Self = .nfc
}


extension CharacterCountOptions.CharacterUnit: @retroactive DefaultInitializable {
    
    public static let defaultValue: Self = .graphemeCluster
}


struct CharacterCountOptionsView: View {
    
    @Namespace private var accessibility
    
    @AppStorage(.countUnit) private var unit: CharacterCountOptions.CharacterUnit
    @AppStorage(.countNormalizationForm) private var normalizationForm: UnicodeNormalizationForm
    @AppStorage(.countNormalizes) private var normalizes
    @AppStorage(.countIgnoresNewlines) private var ignoresNewlines
    @AppStorage(.countIgnoresWhitespaces) private var ignoresWhitespaces
    @AppStorage(.countTreatsConsecutiveWhitespaceAsSingle) private var treatsConsecutiveWhitespaceAsSingle
    @AppStorage(.countEncoding) private var encoding: Int
    
    @State private var contentWidth: CGFloat?
    
    
    var body: some View {
        
        Grid(alignment: .topLeading, verticalSpacing: 14) {
            GridRow {
                Text("Whitespace:", tableName: "AdvancedCharacterCount", comment: "label")
                    .gridColumnAlignment(.trailing)
                
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(String(localized: "Ignore line endings", table: "AdvancedCharacterCount", comment: "setting option"),
                           isOn: $ignoresNewlines)
                    Toggle(String(localized: "Ignore whitespace", table: "AdvancedCharacterCount", comment: "setting option"),
                           isOn: $ignoresWhitespaces)
                    Toggle(String(localized: "Treat consecutive whitespace as one space", table: "AdvancedCharacterCount", comment: "setting option"),
                           isOn: $treatsConsecutiveWhitespaceAsSingle)
                    .disabled(self.ignoresNewlines && self.ignoresWhitespaces)
                }
            }
            .fixedSize()
            .accessibilityElement(children: .contain)
            
            GridRow {
                Text("Unit:", tableName: "AdvancedCharacterCount", comment: "label")
                    .accessibilityLabeledPair(role: .label, id: "unit", in: self.accessibility)
                
                VStack(alignment: .leading) {
                    Picker(selection: $unit.animation()) {
                        ForEach(CharacterCountOptions.CharacterUnit.allCases, id: \.self) {
                            Text($0.label)
                        }
                    } label: {
                        EmptyView()
                    }
                    .fixedSize()
                    .accessibilityLabeledPair(role: .content, id: "unit", in: self.accessibility)

                    Text(self.unit.description)
                        .foregroundStyle(.secondary)
                        .controlSize(.small)
                        .frame(width: max(300, self.contentWidth ?? 0), alignment: .leading)
                    
                    if self.unit == .byte {
                        Picker(String(localized: "Encoding:", table: "AdvancedCharacterCount", comment: "label"), selection: self.$encoding) {
                            ForEach(String.sortedAvailableStringEncodings.indices, id: \.self) { index in
                                if let encoding = String.sortedAvailableStringEncodings[index] {
                                    Text(String.localizedName(of: encoding))
                                        .tag(Int(encoding.rawValue))
                                } else {
                                    Divider()
                                }
                            }
                        }
                        .fixedSize()
                        .onGeometryChange(for: CGFloat.self, of: \.size.width) { self.contentWidth = $0 }
                    }
                    
                    if self.unit != .graphemeCluster {
                        HStack(alignment: .firstTextBaseline) {
                            Toggle(String(localized: "Normalization:", table: "AdvancedCharacterCount", comment: "label"), isOn: $normalizes)
                            Picker(String(localized: "Normalization:", table: "AdvancedCharacterCount", comment: "label"), selection: $normalizationForm) {
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
                            .labelsHidden()
                            .disabled(!self.normalizes)
                        }
                        .fixedSize()
                    }
                }
            }
            .accessibilityElement(children: .contain)
        }
        .animation(.default, value: self.unit)
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
