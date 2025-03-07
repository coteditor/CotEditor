//
//  FindSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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
import Defaults

struct FindSettingsView: View {
    
    @AppStorage(.findIsWrap) var findIsWrap: Bool
    @AppStorage(.findSearchesIncrementally) var findSearchesIncrementally: Bool
    
    @AppStorage(.findMatchesFullWord) var findMatchesFullWord: Bool
    @AppStorage(.findTextIsLiteralSearch) var findTextIsLiteralSearch: Bool
    @AppStorage(.findTextIgnoresDiacriticMarks) var findTextIgnoresDiacriticMarks: Bool
    @AppStorage(.findTextIgnoresWidth) var findTextIgnoresWidth: Bool
    
    @AppStorage(.findRegexIsSingleline) var findRegexIsSingleline: Bool
    @AppStorage(.findRegexIsMultiline) var findRegexIsMultiline: Bool
    @AppStorage(.findRegexUsesUnicodeBoundaries) var findRegexUsesUnicodeBoundaries: Bool
    @AppStorage(.findRegexUnescapesReplacementString) var findRegexUnescapesReplacementString: Bool
    
    
    var body: some View {
        
        VStack {
            Text("Advanced Find Options", tableName: "TextFind")
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .controlSize(.regular)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)
                .padding(.bottom, 6)
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Section {
                        Toggle(String(localized: "FindSettings.findIsWrap.label",
                                      defaultValue: "Wrap search around",
                                      table: "TextFind", comment: "toggle button label"),
                               isOn: $findIsWrap)
                        
                        Toggle(String(localized: "FindSettings.findSearchesIncrementally.label",
                                      defaultValue: "Search incrementally",
                                      table: "TextFind", comment: "toggle button label"),
                               isOn: $findSearchesIncrementally)
                    }
                }
                
                FindTextualOptionsView(
                    matchesFullWord: $findMatchesFullWord,
                    isLiteralSearch: $findTextIsLiteralSearch,
                    ignoresDiacriticMarks: $findTextIgnoresDiacriticMarks,
                    ignoresWidth: $findTextIgnoresWidth
                )
                
                FindRegularExpressionOptionsView(
                    isSingleLine: $findRegexIsSingleline,
                    isMultiline: $findRegexIsMultiline,
                    usesUnicodeBoundaries: $findRegexUsesUnicodeBoundaries,
                    unescapesReplacementString: $findRegexUnescapesReplacementString
                )
                
                HStack {
                    Spacer()
                    HelpLink(anchor: "howto_find")
                }
            }
        }
        .controlSize(.small)
        .fixedSize()
        .scenePadding()
    }
}


struct FindTextualOptionsView: View {
    
    @Binding var matchesFullWord: Bool
    @Binding var isLiteralSearch: Bool
    @Binding var ignoresDiacriticMarks: Bool
    @Binding var ignoresWidth: Bool
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            Section {
                Toggle(String(localized: "FindSettings.matchesFullWord.label",
                              defaultValue: "Match only whole word",
                              table: "TextFind", comment: "toggle button label"),
                       isOn: $matchesFullWord)
                .help(String(localized: "FindSettings.matchesFullWord.description",
                             defaultValue: "Restrict search results to the whole words.",
                             table: "TextFind", comment: "tooltip"))
                
                Toggle(String(localized: "FindSettings.isLiteralSearch.label",
                              defaultValue: "Distinguish characters strictly",
                              table: "TextFind", comment: "toggle button label"),
                       isOn: $isLiteralSearch)
                .help(String(localized: "FindSettings.isLiteralSearch.description",
                             defaultValue: "Exact character-by-character equivalence.",
                             table: "TextFind", comment: "tooltip"))
                
                Toggle(String(localized: "FindSettings.ignoresDiacriticMarks.label",
                              defaultValue: "Ignore diacritical marks",
                              table: "TextFind", comment: "toggle button label"),
                       isOn: $ignoresDiacriticMarks)
                .help(String(localized: "FindSettings.ignoresDiacriticMarks.description",
                             defaultValue: "Search ignores diacritical marks (e.g., ö = o).",
                             table: "TextFind", comment: "tooltip"))
                
                Toggle(String(localized: "FindSettings.ignoresWidth.label",
                              defaultValue: "Ignore width differences",
                              table: "TextFind", comment: "toggle button label"),
                       isOn: $ignoresWidth)
                .help(String(localized: "FindSettings.ignoresWidth.description",
                             defaultValue: "Search ignores width differences in character forms (e.g., ａ = a).",
                             table: "TextFind", comment: "tooltip"))
            } header: {
                Text("Textual Search", tableName: "TextFind", comment: "heading")
                    .fontWeight(.semibold)
            }
        }
    }
}


struct FindRegularExpressionOptionsView: View {
    
    @Binding var isSingleLine: Bool
    @Binding var isMultiline: Bool
    @Binding var usesUnicodeBoundaries: Bool
    @Binding var unescapesReplacementString: Bool
    
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 6) {
            Section {
                Toggle(String(localized: "FindSettings.isSingleLine.label",
                              defaultValue: "Dot matches line separators",
                              table: "TextFind", comment: "toggle button label"),
                       isOn: $isSingleLine)
                .help(String(localized: "FindSettings.isSingleLine.description",
                             defaultValue: "Allow . to match any character, including newline characters (singleline).",
                             table: "TextFind", comment: "tooltip"))
                
                Toggle(String(localized: "FindSettings.isMultiline.label",
                              defaultValue: "Anchors match lines",
                              table: "TextFind", comment: "toggle button label"),
                       isOn: $isMultiline)
                .help(String(localized: "FindSettings.isMultiline.description",
                             defaultValue: "Allow ^ and $ to match the start and end of lines (multiline).",
                             table: "TextFind", comment: "tooltip"))
                
                Toggle(String(localized: "FindSettings.usesUnicodeBoundaries.label",
                              defaultValue: "Use Unicode word boundaries",
                              table: "TextFind", comment: "toggle button label"),
                       isOn: $usesUnicodeBoundaries)
                .help(String(localized: "FindSettings.usesUnicodeBoundaries.description",
                             defaultValue: "Use Unicode TR#29 to specify word boundaries",
                             table: "TextFind", comment: "tooltip"))
                
                Toggle(String(localized: "FindSettings.unescapesReplacementString.label",
                              defaultValue: "Unescape replacement string",
                              table: "TextFind", comment: "toggle button label"),
                       isOn: $unescapesReplacementString)
                .help(String(localized: "FindSettings.unescapesReplacementString.description",
                             defaultValue: "Unescape meta characters with backslash in replacement string.",
                             table: "TextFind", comment: "tooltip"))
            } header: {
                Text("Regular Expression Search", tableName: "TextFind", comment: "heading")
                    .fontWeight(.semibold)
            }
        }
    }
}


// MARK: - Preview

#Preview {
    FindSettingsView()
}
