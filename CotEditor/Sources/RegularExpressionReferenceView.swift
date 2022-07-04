//
//  RegularExpressionReferenceView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2021-12-02.
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

private struct Definition: Identifiable {
    
    var term: String
    var description: LocalizedStringKey
    let id = UUID()
}


extension Definition {
    
    static let characters = [
        Self(term: ".", description: "any character"),
        Self(term: "\\R", description: "new line character"),
        Self(term: "\\t", description: "tab character"),
        Self(term: "\\w", description: "word character"),
        Self(term: "\\s", description: "whitespace character"),
        Self(term: "\\S", description: "non-whitespace character"),
        Self(term: "\\d", description: "decimal number"),
        Self(term: "[A-Z]", description: "any character in range A to Z"),
        Self(term: "[^A-Z]", description: "any character not in range A to Z"),
    ]
    
    static let anchors = [
        Self(term: "^", description: "beginning of the line"),
        Self(term: "$", description: "end of the line"),
        Self(term: "\\b", description: "word boundary"),
    ]
    
    static let quantifiers = [
        Self(term: "?", description: "1 or 0 times"),
        Self(term: "*", description: "0 or more times"),
        Self(term: "+", description: "1 or more times"),
        Self(term: "{n,m}", description: "at least n but not more than m times"),
        Self(term: "{n,}", description: "at least n times"),
        Self(term: "{,n}", description: "at least 0 but not more than n times"),
        Self(term: "{n}", description: "n times"),
    ]
    
    static let extendedGroups = [
        Self(term: "(?=subexp)", description: "look-ahead"),
        Self(term: "(?<=subexp)", description: "look-behind"),
    ]
    
    static let backReference = [
        Self(term: "$1", description: "first match"),
    ]
}


struct RegularExpressionReferenceView: View {
    
    var body: some View {
        
        Section {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    DefinitionList(Definition.characters, title: "Characters")
                    Spacer()
                    DefinitionList(Definition.anchors, title: "Anchors")
                }
                Divider()
                VStack(alignment: .leading) {
                    DefinitionList(Definition.quantifiers, title: "Quantifiers")
                    Spacer()
                    DefinitionList(Definition.extendedGroups, title: "Extended Groups")
                    Spacer()
                    DefinitionList(Definition.backReference, title: "Back Reference")
                }
            }
            .font(.system(size: NSFont.smallSystemFontSize))
            
        } header: {
            Text("Basic Regular Expression Syntax")
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
        } footer: {
            let icuLink = try! AttributedString(markdown: "[ICU Regular Expressions](https://unicode-org.github.io/icu/userguide/strings/regexp.html)")
            Text("The syntax conforms to the \(icuLink) specifications.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.leading)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding()
    }
    
    
    private struct DefinitionList: View {
        
        @State private var title: LocalizedStringKey
        @State private var definitions: [Definition]
        
        @State private var width: CGFloat?
        
        
        init(_ definitions: [Definition], title: LocalizedStringKey) {
            
            self.definitions = definitions
            self.title = title
        }
        
        
        var body: some View {
            
            Section {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(self.definitions) { definition in
                        HStack(alignment: .firstTextBaseline) {
                            Text(definition.term)
                                .fontWeight(.medium)
                                .frame(width: self.width, alignment: .leading)
                                .background(SizeGetter())
                            Text(definition.description)
                        }
                        .fixedSize()
                    }
                }
                .onPreferenceChange(SizeKey.self) { self.width = $0.map(\.width).max() }
                
            } header: {
                Text(self.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 200, alignment: .leading)
        }
    }
    
}



private struct SizeGetter: View {
    
    var body: some View {
        
        GeometryReader { (geometry) in
            Path().preference(key: SizeKey.self, value: [geometry.size])
        }
    }
}



private struct SizeKey: PreferenceKey {
    
    static var defaultValue: [CGSize] = []
    
    static func reduce(value: inout [CGSize], nextValue: () -> [CGSize]) {
        
        value.append(contentsOf: nextValue())
    }
}



// MARK: - Preview

struct RegularExpressionReferenceView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        RegularExpressionReferenceView()
    }
    
}
