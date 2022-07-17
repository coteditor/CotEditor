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
    
    @StateObject var counter: AdvancedCharacterCounter
    
    @State private var isSettingPresented = false
    
    
    var body: some View {
        
        HStack(alignment: .firstTextBaseline) {
            
            if let selectionCount = self.counter.selectionCount,
               let count = (selectionCount > 0) ? selectionCount : self.counter.entireCount
            {
                (Text(count, format: .number).font(.body.monospacedDigit().weight(.medium)) +
                 Text(" characters").foregroundColor(.secondary))
                .textSelection(.enabled)
            } else {
                Text(Image(systemName: "exclamationmark.triangle.fill").symbolRenderingMode(.multicolor))
                Text("failed")
                    .foregroundColor(.secondary)
            }
            
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
}



// MARK: - Preview

struct AdvancedCharacterCounterView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        AdvancedCharacterCounterView(counter: .init(textView: .init()))
    }
    
}
