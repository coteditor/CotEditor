//
//  MultipleReplacementSettingsView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

struct MultipleReplacementSettingsView: View {
    
    @ObservedObject var options: MultipleReplacement.Settings.Object
    
    let completionHandler: (MultipleReplacement.Settings) -> Void
    
    
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
        .padding()
    }
}



// MARK: - Preview

struct MultipleReplacementSettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        MultipleReplacementSettingsView(options: .init(settings: .init())) { _ in }
    }
}
