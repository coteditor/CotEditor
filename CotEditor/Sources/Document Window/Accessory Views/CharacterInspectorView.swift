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

import CharacterInfo
import SwiftUI

struct CharacterInspectorView: View {
    
    var info: CharacterInfo
    
    
    var body: some View {
        
        HStack(alignment: .top) {
            CharacterView(info: self.info)
                .frame(minWidth: 64)
            CharacterDetailView(info: self.info)
        }
        .padding(10)
    }
}


private struct CharacterDetailView: View {
    
    var info: CharacterInfo
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            if let description = self.info.localizedDescription {
                Text(description)
                    .fontWeight(self.info.isComplex ? .regular : .semibold)
                    .textSelection(.enabled)
            } else {
                Text("Unknown", tableName: "CharacterInspector")
                    .foregroundStyle(.secondary)
            }
            
            if !self.info.isComplex {
                ScalarDetailView(scalar: self.info.character.unicodeScalars.first!)
                    .controlSize(.small)
                    .padding(.top, 4)
            }
            
            if self.info.character.unicodeScalars.count > 1 {
                VStack(spacing: 4) {
                    ForEach(Array(self.info.character.unicodeScalars.enumerated()), id: \.offset) { (_, scalar) in
                        DisclosureGroup {
                            HStack(alignment: .top) {
                                Text(String(scalar))
                                    .font(.system(size: 28, design: .serif))
                                    .frame(minWidth: 30, idealWidth: 30)
                                    .border(.separator)
                                ScalarDetailView(scalar: scalar, items: [.block, .category])
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                }
                .controlSize(.small)
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
    
    
    var scalar: Unicode.Scalar
    var items: Items = .all
    
    @Namespace private var accessibility
    
    
    var body: some View {
        
        Grid(alignment: .leadingLastTextBaseline, verticalSpacing: 2) {
            if self.items.contains(.codePoint) {
                GridRow {
                    Text("Code Point:", tableName: "CharacterInspector")
                        .accessibilityLabeledPair(role: .label, id: "codePoint", in: self.accessibility)
                        .gridColumnAlignment(.trailing)
                    
                    HStack(alignment: .firstTextBaseline) {
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
                    .textSelection(.enabled)
                    .accessibilityLabeledPair(role: .content, id: "codePoint", in: self.accessibility)
                }
            }
            
            if self.items.contains(.block) {
                GridRow {
                    Text("Block:", tableName: "CharacterInspector")
                        .gridColumnAlignment(.trailing)
                        .accessibilityLabeledPair(role: .label, id: "block", in: self.accessibility)
                    
                    Group {
                        if let blockName = self.scalar.localizedBlockName {
                            Text(blockName)
                                .textSelection(.enabled)
                        } else {
                            Text("No Block", tableName: "CharacterInspector")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabeledPair(role: .content, id: "block", in: self.accessibility)
                }
            }
            
            if self.items.contains(.category) {
                GridRow {
                    Text("Category:", tableName: "CharacterInspector")
                        .accessibilityLabeledPair(role: .label, id: "category", in: self.accessibility)
                    
                    let category = self.scalar.properties.generalCategory
                    Text(verbatim: "\(category.longName) (\(category.shortName))")
                        .textSelection(.enabled)
                        .accessibilityLabeledPair(role: .content, id: "category", in: self.accessibility)
                }
            }
            
            if self.items.contains(.version), let age = self.scalar.properties.age {
                GridRow {
                    Text("Version:", tableName: "CharacterInspector")
                        .accessibilityLabeledPair(role: .label, id: "version", in: self.accessibility)
                    
                    Text(verbatim: "Unicode \(age.major).\(age.minor)")
                        .accessibilityLabeledPair(role: .content, id: "version", in: self.accessibility)
                }
            }
        }.fixedSize()
    }
}


private struct CharacterView: NSViewRepresentable {
    
    typealias NSViewType = NSTextField
    
    var info: CharacterInfo
    
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
        
        Text("deprecated", tableName: "CharacterInspector", comment: "badge for when the inspected character is deprecated in the latest Unicode specification")
            .padding(.horizontal, 3)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.secondary))
            .foregroundStyle(.secondary)
    }
}


private extension CharacterInfo {
    
    var localizedDescription: String? {
        
        let unicodes = self.character.unicodeScalars
        if self.isComplex {
            return String(localized: "<a letter consisting of \(unicodes.count) characters>",
                          table: "CharacterInspector",
                          comment: "%lld is always 2 or more.")
        }
        
        guard var unicodeName = unicodes.first?.name else { return nil }
        
        if self.isVariant, let variantDescription = unicodes.last?.variantDescription {
            unicodeName += String(localized: " (\(variantDescription))")
        }
        
        return unicodeName
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
