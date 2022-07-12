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
import AppKit.NSFont

struct CharacterCountOptionsView: View {
    
    @AppStorage("countOption.unit") private var unit: CharacterCountOptions.CharacterUnit = .graphemeCluster
    @AppStorage("countOption.normalizationForm") private var normalizationForm: UnicodeNormalizationForm = .nfc
    @AppStorage("countOption.normalizes") private var normalizes = false
    @AppStorage("countOption.ignoresNewlines") private var ignoresNewlines = false
    @AppStorage("countOption.ignoresWhitespaces") private var ignoresWhitespaces = false
    @AppStorage("countOption.treatsConsecutiveWhitespaceAsSingle") private var treatsConsecutiveWhitespaceAsSingle = false
    
    @State private var contentWidth: CGFloat?
    
    
    var body: some View {
        
        VStack(alignment: .column) {
            HStack(alignment: .firstTextBaseline) {
                Text("Whitespace:")
                
                VStack(alignment: .leading) {
                    Toggle("Ignore line endings", isOn: $ignoresNewlines)
                    Toggle("Ignore whitespace", isOn: $ignoresWhitespaces)
                    Toggle("Treat consecutive whitespace as one space", isOn: $treatsConsecutiveWhitespaceAsSingle)
                        .disabled(ignoresNewlines && ignoresWhitespaces)
                }
                .alignmentGuide(.column) { $0[.leading] }
                .background(SizeGetter())
                .onPreferenceChange(SizeKey.self) { self.contentWidth = $0.map(\.width).max() }
            }.fixedSize()
            
            HStack(alignment: .firstTextBaseline) {
                Text("Unit:")
                    .fixedSize()
                
                VStack(alignment: .leading) {
                    Picker("Unit:", selection: $unit.animation(.linear(duration: 0.15))) {
                        Text("Grapheme cluster").tag(CharacterCountOptions.CharacterUnit.graphemeCluster)
                        Text("Unicode scalar").tag(CharacterCountOptions.CharacterUnit.unicodeScalar)
                        Text("UTF-16").tag(CharacterCountOptions.CharacterUnit.utf16)
                    }.labelsHidden()
                        .fixedSize()
                    Text(self.unit.description)
                        .font(.system(size: NSFont.smallSystemFontSize))
                        .foregroundColor(.secondary)
                        .frame(width: max(300, self.contentWidth ?? 0), alignment: .leading)
                        .fixedSize()
                    
                    if self.unit != .graphemeCluster {
                        HStack(alignment: .firstTextBaseline) {
                            Toggle("Normalization:", isOn: $normalizes)
                            Picker("Normalization:", selection: $normalizationForm) {
                                Text("NFD").tag(UnicodeNormalizationForm.nfd)
                                Text("NFC").tag(UnicodeNormalizationForm.nfc)
                                Text("NFKD").tag(UnicodeNormalizationForm.nfkd)
                                Text("NFKC").tag(UnicodeNormalizationForm.nfkc)
                                Text("NFKC casefold").tag(UnicodeNormalizationForm.nfkcCasefold)
                            }.labelsHidden()
                                .disabled(!self.normalizes)
                        }.fixedSize()
                    }
                }
                .alignmentGuide(.column) { $0[.leading] }
            }
        }
    }
}



// MARK: Model

extension CharacterCountOptions.CharacterUnit {
    
    var description: LocalizedStringKey {
        
        switch self {
            case .graphemeCluster:
                return "Count in the intuitive way defined in Unicode. A character consisting of multiple Unicode code points, such as emojis, is counted as one character."
            case .unicodeScalar:
                return "Count Unicode code points. Same as counting UTF-32."
            case .utf16:
                return "Count Unicode code points but a surrogate pair as two characters."
        }
    }
}



// MARK: - Preview

struct CharacterCountOptionsView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        CharacterCountOptionsView()
    }
}
