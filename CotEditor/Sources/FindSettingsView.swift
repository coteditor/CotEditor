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
//  © 2022-2023 1024jp
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

@MainActor final private class FindSettings: ObservableObject {
    
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
}


struct FindSettingsView: View {
    
    @StateObject private var settings = FindSettings()
    
    
    var body: some View {
        
        VStack {
            Text("Advanced Find Options")
                .fontWeight(.semibold)
                .foregroundColor(.secondaryLabel)
                .padding(.bottom, 2)
            
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Section {
                        Toggle("Wrap search around", isOn: $settings.findIsWrap)
                        Toggle("Search incrementally", isOn: $settings.findSearchesIncrementally)
                    }
                }
                
                FindTextualOptionsView(matchesFullWord: $settings.findMatchesFullWord,
                                       isLiteralSearch: $settings.findTextIsLiteralSearch,
                                       ignoresDiacriticMarks: $settings.findTextIgnoresDiacriticMarks,
                                       ignoresWidth: $settings.findTextIgnoresWidth)
                
                FindRegularExpressionOptionsView(isSingleLine: $settings.findRegexIsSingleline,
                                                 isMultiline: $settings.findRegexIsMultiline,
                                                 usesUnicodeBoundaries: $settings.findRegexUsesUnicodeBoundaries,
                                                 unescapesReplacementString: $settings.findRegexUnescapesReplacementString)
                
                HStack {
                    Spacer()
                    HelpButton(anchor: "howto_find")
                }
            }.controlSize(.small)
        }
        .fixedSize()
        .padding()
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
                Toggle("Match only whole word", isOn: $matchesFullWord)
                    .help("Restrict search results to the whole words.")
                Toggle("Distinguish characters strictly", isOn: $isLiteralSearch)
                    .help("Exact character-by-character equivalence.")
                Toggle("Ignore diacritical marks", isOn: $ignoresDiacriticMarks)
                    .help("Search ignores diacritical marks (e.g., ö = o).")
                Toggle("Ignore width differences", isOn: $ignoresWidth)
                    .help("Search ignores width differences in character forms (e.g., ａ = a).")
            } header: {
                Text("Textural Search")
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
                Toggle("Dot matches line separators", isOn: $isSingleLine)
                    .help("Allow . to match any character, including newline characters (singleline).")
                Toggle("Anchors match lines", isOn: $isMultiline)
                    .help("Allow ^ and $ to match the start and end of lines (multiline).")
                Toggle("Use Unicode word boundaries", isOn: $usesUnicodeBoundaries)
                    .help("Use Unicode TR#29 to specify word boundaries")
                Toggle("Unescape replacement string", isOn: $unescapesReplacementString)
                    .help("Unescape meta characters with backslash in replacement string.")
            } header: {
                Text("Regular Expression Search")
                    .fontWeight(.semibold)
            }
        }
    }
}



// MARK: - Preview

struct FindSettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        FindSettingsView()
    }
}
