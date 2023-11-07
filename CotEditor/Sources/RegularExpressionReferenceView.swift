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
        
        VStack(alignment: .leading) {
            Text("Basic Regular Expression Syntax")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    DefinitionList(Definition.characters, title: "Characters")
                    DefinitionList(Definition.anchors, title: "Anchors")
                }
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    DefinitionList(Definition.quantifiers, title: "Quantifiers")
                    DefinitionList(Definition.extendedGroups, title: "Extended Groups")
                    DefinitionList(Definition.backReference, title: "Back Reference")
                }
            }.controlSize(.small)
            
            let icuURL = "https://unicode-org.github.io/icu/userguide/strings/regexp.html"
            let icuLink = AttributedString(localized: "ICU Regular Expressions")
                .settingAttributes(.init([.link: URL(string: icuURL)!]))
            
            Text("The syntax conforms to the \(icuLink) specifications.",
                 comment: "%@ is the name of the regex engine (ICU Regular Expressions)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .tint(.accentColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 8)
        }
        .fixedSize()
        .scenePadding()
    }
    
    
    private struct DefinitionList: View {
        
        @State private var title: LocalizedStringKey
        @State private var definitions: [Definition]
        
        
        init(_ definitions: [Definition], title: LocalizedStringKey) {
            
            self.definitions = definitions
            self.title = title
        }
        
        
        var body: some View {
            
            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Grid(alignment: .leading, verticalSpacing: 1) {
                    ForEach(self.definitions) { definition in
                        GridRow {
                            Text(definition.term)
                                .fontWeight(.medium)
                            Text(definition.description)
                        }
                    }
                }
            }.frame(minWidth: 200, alignment: .leading)
        }
    }
}



// MARK: - Preview

#Preview {
    RegularExpressionReferenceView()
}
