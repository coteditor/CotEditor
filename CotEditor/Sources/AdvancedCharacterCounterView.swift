//
//  AdvancedCharacterCounterView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2021-05-27.
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

struct AdvancedCharacterCounterView: View {
    
    @State var string: String
    @State private var isSettingPresented = false
    
    @AppStorage("countOption.unit") private var unit: CharacterCountOptions.CharacterUnit = .graphemeCluster
    @AppStorage("countOption.normalizationForm") private var normalizationForm: UnicodeNormalizationForm = .nfc
    @AppStorage("countOption.normalizes") private var normalizes = false
    @AppStorage("countOption.ignoresNewlines") private var ignoresNewlines = false
    @AppStorage("countOption.ignoresWhitespaces") private var ignoresWhitespaces = false
    @AppStorage("countOption.treatsConsecutiveWhitespaceAsSingle") private var treatsConsecutiveWhitespaceAsSingle = false
    
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline) {
            (Text(self.string.count(options: self.options), format: .number)
                .font(.body.monospacedDigit().weight(.medium)) +
             Text(" characters")
                .foregroundColor(.secondary))
            .textSelection(.enabled)
            
            Spacer()
            
            Button {
                self.isSettingPresented.toggle()
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help("Change options")
            .popover(isPresented: self.$isSettingPresented) {
                CharacterCountOptionsView()
                    .padding()
            }
        }
        .padding(10)
        .background(.regularMaterial)
        .cornerRadius(8)
        .shadow(radius: 4, y: 2)
    }
    
    
    private var options: CharacterCountOptions {
        
        .init(unit: self.unit,
              normalizationForm: self.normalizes ? self.normalizationForm : nil,
              ignoresNewlines: self.ignoresNewlines,
              ignoresWhitespaces: self.ignoresWhitespaces,
              treatsConsecutiveWhitespaceAsSingle: self.treatsConsecutiveWhitespaceAsSingle)
    }
}



// MARK: - Preview

struct AdvancedCharacterCounterView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        AdvancedCharacterCounterView(string: "dog  \r\n abc")
    }
    
}
