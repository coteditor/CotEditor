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
        
        VStack(alignment: .leading, spacing: 0) {
            if let description = self.info.localizedDescription {
                Text(description)
                    .fontWeight(self.info.isComplex ? .regular : .semibold)
                    .foregroundColor(.label)  // Workaround to keep text color when selected (2022-12, macOS 13, FB10747746, fixed on macOS 14).
                    .textSelection(.enabled)
            } else {
                Text("Unknown")
                    .foregroundColor(.secondaryLabel)
            }
            
            if !self.info.isComplex {
                ScalarDetailView(scalar: self.info.character.unicodeScalars.first!)
                    .controlSize(.small)
                    .padding(.top, 4)
            }
            
            if self.info.character.unicodeScalars.count > 1 {
                ForEach(Array(self.info.character.unicodeScalars.enumerated()), id: \.offset) { (_, scalar) in
                    DisclosureGroup {
                        HStack(alignment: .top) {
                            Text(String(scalar))
                                .font(.system(size: 28, design: .serif))
                                .frame(minWidth: 30, idealWidth: 30)
                                .border(.primary.opacity(0.1))
                            ScalarDetailView(scalar: scalar, items: [.block, .category])
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                        
                    } label: {
                        Text(scalar.codePoint)
                            .monospacedDigit()
                            .frame(minWidth: 44, alignment: .leading)
                        if let name = scalar.name {
                            Text(name)
                                .fontWeight(.medium)
                        }
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
    
    struct Items: OptionSet {
        
        let rawValue: Int
        
        static let codePoint = Self(rawValue: 1 << 0)
        static let block     = Self(rawValue: 1 << 1)
        static let category  = Self(rawValue: 1 << 2)
        static let version   = Self(rawValue: 1 << 3)
        
        static let all: Self = [.codePoint, .block, .category, .version]
    }
    
    
    let scalar: Unicode.Scalar
    var items: Items = .all
    
    
    var body: some View {
        
        Grid(alignment: .leadingLastTextBaseline, verticalSpacing: 2) {
            if self.items.contains(.codePoint) {
                GridRow {
                    Text("Code Point:")
                        .gridColumnAlignment(.trailing)
                    
                    HStack {
                        if let surrogates = self.scalar.surrogateCodePoints {
                            Text(verbatim: "\(self.scalar.codePoint) (\(surrogates.lead) \(surrogates.trail))")
                        } else {
                            Text(self.scalar.codePoint)
                        }
                        if self.scalar.properties.isDeprecated {
                            Spacer()
                            DeprecatedBadge()
                        }
                    }
                    .monospacedDigit()
                    .foregroundColor(.label)
                    .textSelection(.enabled)
                }
            }
            
            if self.items.contains(.block) {
                GridRow {
                    Text("Block:")
                    
                    if let blockName = self.scalar.localizedBlockName {
                        Text(blockName)
                            .foregroundColor(.label)
                            .textSelection(.enabled)
                    } else {
                        Text("No Block")
                            .foregroundColor(.secondaryLabel)
                    }
                }
            }
            
            if self.items.contains(.category) {
                GridRow {
                    Text("Category:")
                    
                    let category = self.scalar.properties.generalCategory
                    Text(verbatim: "\(category.longName) (\(category.shortName))")
                        .foregroundColor(.label)
                        .textSelection(.enabled)
                }
            }
            
            if self.items.contains(.version), let age = self.scalar.properties.age {
                GridRow {
                    Text("Version:")
                    
                    Text(verbatim: "Unicode \(age.major).\(age.minor)")
                }
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
    
    
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextField, context: Context) -> CGSize? {
        
        nsView.intrinsicContentSize
    }
}


private struct DeprecatedBadge: View {
    
    var body: some View {
        
        Text("deprecated", comment: "badge in the character inspector for when the inspected character is deprecated in the latest Unicode specification")
            .padding(.horizontal, 3)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.secondary))
            .foregroundColor(.secondary)
    }
}



// MARK: - Preview

#Preview("𓆏") {
    CharacterInspectorView(info: CharacterInfo(character: "𓆏"))
}

#Preview("\\n") {
    CharacterInspectorView(info: CharacterInfo(character: "\n"))
}

#Preview("ơ̟̤̖̗͖͇̍͋̀͆̓́͞͡") {
    CharacterInspectorView(info: CharacterInfo(character: "ơ̟̤̖̗͖͇̍͋̀͆̓́͞͡"))
}

#Preview("🏴‍☠️") {
    CharacterInspectorView(info: CharacterInfo(character: "🏴‍☠️"))
}

#Preview("🇦🇦") {
    CharacterInspectorView(info: CharacterInfo(character: "🇦🇦"))
}

#Preview("deprecated") {
    CharacterInspectorView(info: CharacterInfo(character: "ឣ"))
}
