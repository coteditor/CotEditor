//
//  MultipleReplaceSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2025 1024jp
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
import TextFind

struct MultipleReplaceSettingsView: View {
    
    @State var settings: MultipleReplace.Settings
    var completionHandler: (MultipleReplace.Settings) -> Void
    
    
    // MARK: View
    
    var body: some View {
        
        VStack {
            Text("Advanced Find Options", tableName: "TextFind")
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .controlSize(.regular)
                .padding(.bottom, 6)
            
            VStack(alignment: .leading, spacing: 14) {
                FindTextualOptionsView(
                    matchesFullWord: $settings.matchesFullWord,
                    isLiteralSearch: $settings.textualOptions.bind(.literal),
                    ignoresDiacriticMarks: $settings.textualOptions.bind(.diacriticInsensitive),
                    ignoresWidth: $settings.textualOptions.bind(.widthInsensitive)
                )
                
                FindRegularExpressionOptionsView(
                    isSingleLine: $settings.regexOptions.bind(.dotMatchesLineSeparators),
                    isMultiline: $settings.regexOptions.bind(.anchorsMatchLines),
                    usesUnicodeBoundaries: $settings.regexOptions.bind(.useUnicodeWordBoundaries),
                    unescapesReplacementString: $settings.unescapesReplacementString
                )
            }
        }
        .onDisappear {
            self.completionHandler(self.settings)
        }
        .controlSize(.small)
        .fixedSize()
        .scenePadding()
    }
}


// MARK: - Preview

#Preview {
    MultipleReplaceSettingsView(settings: .init()) { _ in }
}
