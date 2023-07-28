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

struct MultipleReplaceSettingsView: View {
    
    @StateObject private var options: MultipleReplace.Settings.Object
    
    private let completionHandler: (MultipleReplace.Settings) -> Void
    
    
    // MARK: View
    
    /// Initialize view with given values.
    ///
    /// - Parameters:
    ///   - settings: The current settings use as the initial values.
    ///   - completionHandler: The callback method to perform when the view was dismissed.
    init(settings: MultipleReplace.Settings, completionHandler: @escaping (MultipleReplace.Settings) -> Void) {
        
        self._options = StateObject(wrappedValue: .init(settings: settings))
        self.completionHandler = completionHandler
    }
    
    
    var body: some View {
        
        VStack {
            Text("Advanced Find Options")
                .fontWeight(.semibold)
                .foregroundColor(.secondaryLabel)
                .padding(.bottom, 2)
            
            VStack(alignment: .leading, spacing: 14) {
                FindTextualOptionsView(matchesFullWord: $options.textMatchesFullWord,
                                       isLiteralSearch: $options.textIsLiteralSearch,
                                       ignoresDiacriticMarks: $options.textIgnoresDiacriticMarks,
                                       ignoresWidth: $options.textIgnoresWidth)
                
                FindRegularExpressionOptionsView(isSingleLine: $options.regexIsSingleline,
                                                 isMultiline: $options.regexIsMultiline,
                                                 usesUnicodeBoundaries: $options.regexUsesUnicodeBoundaries,
                                                 unescapesReplacementString: $options.regexUnescapesReplacementString)
            }.controlSize(.small)
        }
        .onDisappear {
            self.completionHandler(self.options.settings)
        }
        .fixedSize()
        .padding()
    }
}



// MARK: - Preview

#Preview {
    MultipleReplaceSettingsView(settings: .init()) { _ in }
}
