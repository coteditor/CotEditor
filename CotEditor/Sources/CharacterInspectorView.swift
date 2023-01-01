//
//  CharacterInspectorView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2021-04-28.
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

struct CharacterInspectorView: View {
    
    @State var info: CharacterInfo
    
    
    var body: some View {
        
        HStack(alignment: .top) {
            CharacterView(info: self.$info)
                .frame(minWidth: 64)
            self.detailView
        }
        .padding(10)
    }
    
    
    private var detailView: some View {
        
        VStack(alignment: .leading, spacing: 2) {
            Text(self.info.localizedDescription ?? "Unknown")
                .fontWeight(self.info.isComplex ? .regular : .semibold)
                .foregroundColor(.label)  // Workaround to keep text color when selected (2022-12, macOS 13, FB10747746).
                .textSelection(.enabled)
            
            if !self.info.isComplex {
                ScalarDetailView(scalar: self.info.character.unicodeScalars.first!,
                                 showsCodePoint: self.info.character.unicodeScalars.count == 1)
                    .controlSize(.small)
            }
            
            if self.info.character.unicodeScalars.count > 1 {
                ForEach(Array(self.info.character.unicodeScalars.enumerated()), id: \.offset) { (_, scalar) in
                    if let name = scalar.name {
                        Text(verbatim: scalar.codePoint.padding(toLength: 7, withPad: " ", startingAt: 0))
                            .monospacedDigit() + Text(verbatim: " " + name)
                    } else {
                        Text(verbatim: scalar.codePoint)
                            .monospacedDigit()
                    }
                }
                .controlSize(.small)
                .foregroundColor(.label)
                .textSelection(.enabled)
            }
        }.fixedSize()
    }
}


private struct ScalarDetailView: View {
    
    let scalar: Unicode.Scalar
    var showsCodePoint = true
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 2) {
            if self.showsCodePoint {
                HStack(alignment: .firstTextBaseline) {
                    if let surrogates = self.scalar.surrogateCodePoints {
                        Text(verbatim: "\(self.scalar.codePoint) (\(surrogates.lead) \(surrogates.trail))")
                    } else {
                        Text(verbatim: self.scalar.codePoint)
                    }
                }
                .monospacedDigit()
                .foregroundColor(.label)
                .textSelection(.enabled)
            }
            
            HStack(alignment: .firstTextBaseline) {
                if let blockName = self.scalar.localizedBlockName {
                    Text(blockName)
                        .foregroundColor(.label)
                        .textSelection(.enabled)
                } else {
                    Text("No Block")
                        .foregroundColor(.secondaryLabel)
                }
            }
            
            HStack(alignment: .firstTextBaseline) {
                let category = self.scalar.properties.generalCategory
                Text("\(category.longName) (\(category.shortName))")
                    .foregroundColor(.label)
                    .textSelection(.enabled)
            }
        }.fixedSize()
    }
}



private struct CharacterView: NSViewRepresentable {
    
    typealias NSViewType = NSTextField
    
    @Binding var info: CharacterInfo
    var fontSize: CGFloat = 64
    
    
    func makeNSView(context: Context) -> NSTextField {
        
        let character = self.info.pictureString ?? String(self.info.character)
        let nsView = CharacterField(labelWithString: character)
        nsView.font = NSFont.systemFont(ofSize: self.fontSize).fontDescriptor
            .withDesign(.serif)
            .flatMap { NSFont(descriptor: $0, size: self.fontSize) }
        
        return nsView
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        
        nsView.stringValue = self.info.pictureString ?? String(self.info.character)
        nsView.textColor = (self.info.pictureString != nil) ? .tertiaryLabelColor : .labelColor
    }
}



// MARK: - Preview

struct CharacterInspectorView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        CharacterInspectorView(info: CharacterInfo(character: "𓆏"))
            .previewDisplayName("𓆏")
        CharacterInspectorView(info: CharacterInfo(character: "\n"))
            .previewDisplayName("\\n")
        CharacterInspectorView(info: CharacterInfo(character: "ơ̟̤̖̗͖͇̍͋̀͆̓́͞͡"))
            .previewDisplayName("ơ̟̤̖̗͖͇̍͋̀͆̓́͞͡")
        CharacterInspectorView(info: CharacterInfo(character: "🏴‍☠️"))
            .previewDisplayName("🏴‍☠️")
        CharacterInspectorView(info: CharacterInfo(character: "ឣ"))
            .previewDisplayName("deprecated")
    }
}
