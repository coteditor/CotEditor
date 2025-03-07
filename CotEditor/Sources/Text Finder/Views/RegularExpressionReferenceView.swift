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

import SwiftUI

private struct Definition: Identifiable {
    
    var term: String
    var description: String
    
    var id: String { self.term }
}


extension Definition {
    
    static let characters = [
        Self(term: ".", description: String(localized: "any character", table: "RegexReference")),
        Self(term: "\\R", description: String(localized: "new line character", table: "RegexReference")),
        Self(term: "\\t", description: String(localized: "tab character", table: "RegexReference")),
        Self(term: "\\w", description: String(localized: "word character", table: "RegexReference")),
        Self(term: "\\s", description: String(localized: "whitespace character", table: "RegexReference")),
        Self(term: "\\S", description: String(localized: "non-whitespace character", table: "RegexReference")),
        Self(term: "\\d", description: String(localized: "decimal number", table: "RegexReference")),
        Self(term: "[A-Z]", description: String(localized: "any character in range A to Z", table: "RegexReference")),
        Self(term: "[^A-Z]", description: String(localized: "any character not in range A to Z", table: "RegexReference")),
    ]
    
    static let anchors = [
        Self(term: "^", description: String(localized: "beginning of the line", table: "RegexReference")),
        Self(term: "$", description: String(localized: "end of the line", table: "RegexReference")),
        Self(term: "\\b", description: String(localized: "word boundary", table: "RegexReference")),
    ]
    
    static let quantifiers = [
        Self(term: "?", description: String(localized: "1 or 0 times", table: "RegexReference")),
        Self(term: "*", description: String(localized: "0 or more times", table: "RegexReference")),
        Self(term: "+", description: String(localized: "1 or more times", table: "RegexReference")),
        Self(term: "{n,m}", description: String(localized: "at least n but not more than m times", table: "RegexReference")),
        Self(term: "{n,}", description: String(localized: "at least n times", table: "RegexReference")),
        Self(term: "{,n}", description: String(localized: "at least 0 but not more than n times", table: "RegexReference")),
        Self(term: "{n}", description: String(localized: "n times", table: "RegexReference")),
    ]
    
    static let extendedGroups = [
        Self(term: "(?=subexp)", description: String(localized: "look-ahead", table: "RegexReference")),
        Self(term: "(?<=subexp)", description: String(localized: "look-behind", table: "RegexReference")),
    ]
    
    static let backReference = [
        Self(term: "$1", description: String(localized: "first match", table: "RegexReference")),
    ]
}


struct RegularExpressionReferenceView: View {
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Basic Regular Expression Syntax", tableName: "RegexReference", comment: "title")
                .font(.title3)
                .foregroundStyle(.secondary)
                .accessibilityHeading(.h1)
            
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    DefinitionList(Definition.characters,
                                   title: String(localized: "Characters", table: "RegexReference", comment: "heading"))
                    DefinitionList(Definition.anchors,
                                   title: String(localized: "Anchors", table: "RegexReference", comment: "heading"))
                }
                .accessibilityElement(children: .contain)
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    DefinitionList(Definition.quantifiers,
                                   title: String(localized: "Quantifiers", table: "RegexReference", comment: "heading"))
                    DefinitionList(Definition.extendedGroups,
                                   title: String(localized: "Extended Groups", table: "RegexReference", comment: "heading"))
                    DefinitionList(Definition.backReference,
                                   title: String(localized: "Back Reference", table: "RegexReference", comment: "heading"))
                }
                .accessibilityElement(children: .contain)
            }
            
            let icuURL = "https://unicode-org.github.io/icu/userguide/strings/regexp.html"
            let icuLink = AttributedString(localized: "ICU Regular Expressions", table: "RegexReference")
                .settingAttributes(AttributeContainer
                    .link(URL(string: icuURL)!)
                    .underlineStyle(.single))
            
            Text("The syntax conforms to the \(icuLink) specifications.",
                 tableName: "RegexReference",
                 comment: "%@ is the name of the regex engine (ICU Regular Expressions)")
                .foregroundStyle(.secondary)
                .tint(.accentColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 8)
        }
        .controlSize(.small)
        .fixedSize()
        .scenePadding()
    }
    
    
    private struct DefinitionList: View {
        
        @State private var title: String
        @State private var definitions: [Definition]
        
        
        init(_ definitions: [Definition], title: String) {
            
            self.definitions = definitions
            self.title = title
        }
        
        
        var body: some View {
            
            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                
                Grid(alignment: .leading, verticalSpacing: 1) {
                    ForEach(self.definitions) { definition in
                        GridRow {
                            Text(definition.term)
                                .fontWeight(.medium)
                            Text(definition.description)
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .frame(minWidth: 200, alignment: .leading)
        }
    }
}


// MARK: - Preview

#Preview {
    RegularExpressionReferenceView()
}
