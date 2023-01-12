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
//  © 2021-2023 1024jp
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
            CharacterView(info: $info)
                .frame(minWidth: 64)
            CharacterDetailView(info: $info)
        }
        .padding(10)
    }
}


    
private struct CharacterDetailView: View {
    
    @Binding var info: CharacterInfo
    
    
    var body: some View {
        
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
                        Text(scalar.codePoint.padding(toLength: 7, withPad: " ", startingAt: 0))
                            .monospacedDigit() + Text(" " + name)
                    } else {
                        Text(scalar.codePoint)
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
                        Text("\(self.scalar.codePoint) (\(surrogates.lead) \(surrogates.trail))")
                    } else {
                        Text(self.scalar.codePoint)
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
    
    private let fontSize: CGFloat = 64
    
    
    func makeNSView(context: Context) -> NSTextField {
        
        let nsView = CharacterField(labelWithString: "")
        nsView.font = .systemFont(ofSize: 0)
            .fontDescriptor
            .withDesign(.serif)
            .flatMap { NSFont(descriptor: $0, size: self.fontSize) }
        
        return nsView
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        
        nsView.stringValue = String(self.info.pictureCharacter ?? self.info.character)
        nsView.textColor = (self.info.pictureCharacter != nil) ? .tertiaryLabelColor : .labelColor
    }
    
    
    @available(macOS 13, *)
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextField, context: Context) -> CGSize? {
        
        nsView.intrinsicContentSize
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
        CharacterInspectorView(info: CharacterInfo(character: "🇦🇦"))
            .previewDisplayName("🇦🇦")
        CharacterInspectorView(info: CharacterInfo(character: "ឣ"))
            .previewDisplayName("deprecated")
    }
}
