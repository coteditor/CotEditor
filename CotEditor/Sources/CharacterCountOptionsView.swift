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
//  © 2021-2022 1024jp
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
        
        VStack(alignment: .column) {
            HStack(alignment: .firstTextBaseline) {
                Text("Whitespace:")
                
                VStack(alignment: .leading) {
                    Toggle("Ignore line endings", isOn: self.setting.$ignoresNewlines)
                    Toggle("Ignore whitespace", isOn: self.setting.$ignoresWhitespaces)
                    Toggle("Treat consecutive whitespace as one space", isOn: self.setting.$treatsConsecutiveWhitespaceAsSingle)
                        .disabled(self.setting.ignoresNewlines && self.setting.ignoresWhitespaces)
                }
                .alignmentGuide(.column) { $0[.leading] }
                .background(WidthGetter(key: WidthKey.self))
            }.fixedSize()
            
            HStack(alignment: .firstTextBaseline) {
                Text("Unit:")
                    .fixedSize()
                
                VStack(alignment: .leading) {
                    Picker("Unit:", selection: self.setting.$unit) {
                        Text("Grapheme cluster").tag(CharacterCountOptions.CharacterUnit.graphemeCluster)
                        Text("Unicode scalar").tag(CharacterCountOptions.CharacterUnit.unicodeScalar)
                        Text("UTF-16").tag(CharacterCountOptions.CharacterUnit.utf16)
                        Text("Byte").tag(CharacterCountOptions.CharacterUnit.byte)
                    }.labelsHidden()
                        .fixedSize()
                    
                    if self.setting.unit == .byte {
                        Picker("Encoding:", selection: self.$setting.encoding) {
                            ForEach(0..<String.sortedAvailableStringEncodings.count, id: \.self) { index in
                                if let encoding = String.sortedAvailableStringEncodings[index] {
                                    Text(String.localizedName(of: encoding)).tag(Int(encoding.rawValue))
                                } else {
                                    Divider()
                                }
                            }
                        }.fixedSize()
                            .background(WidthGetter(key: WidthKey.self))
                    }
                    
                    Text(self.setting.unit.description)
                        .foregroundColor(.secondaryLabel)
                        .controlSize(.small)
                        .frame(width: max(300, self.contentWidth ?? 0), alignment: .leading)
                        .fixedSize()
                    
                    
                    if self.setting.unit != .graphemeCluster {
                        HStack(alignment: .firstTextBaseline) {
                            Toggle("Normalization:", isOn: self.setting.$normalizes)
                            Picker("Normalization:", selection: self.setting.$normalizationForm) {
                                ForEach(UnicodeNormalizationForm.standardForms, id: \.self) { (form) in
                                    Text(form.localizedName).tag(form).help(form.localizedDescription)
                                }
                                Divider()
                                ForEach(UnicodeNormalizationForm.modifiedForms, id: \.self) { (form) in
                                    Text(form.localizedName).tag(form).help(form.localizedDescription)
                                }
                            }.labelsHidden()
                                .disabled(!self.setting.normalizes)
                        }.fixedSize()
                    }
                }
                .alignmentGuide(.column) { $0[.leading] }
            }
        }
        .onPreferenceChange(WidthKey.self) { self.contentWidth = $0 }
        .animation(.default, value: self.setting.unit)
    }
}



// MARK: Model

private extension CharacterCountOptions.CharacterUnit {
    
    var description: LocalizedStringKey {
        
        switch self {
            case .graphemeCluster:
                return "Count in the intuitive way defined in Unicode. A character consisting of multiple Unicode code points, such as emojis, is counted as one character."
            case .unicodeScalar:
                return "Count Unicode code points. Same as counting UTF-32."
            case .utf16:
                return "Count Unicode code points but a surrogate pair as two characters."
            case .byte:
                return "Count bytes of the text encoded with the specified encoding."
        }
    }
}



// MARK: - Preview

struct CharacterCountOptionsView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        CharacterCountOptionsView()
    }
}
