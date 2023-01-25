//
//  MultipleReplace.Settings+Object.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2023 1024jp
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

import Foundation

extension MultipleReplace.Settings {
    
    /// Observable object to modify settings in the UI.
    @MainActor final class Object: ObservableObject {
        
        @Published var textIsLiteralSearch: Bool
        @Published var textIgnoresDiacriticMarks: Bool
        @Published var textIgnoresWidth: Bool
        
        @Published var regexIsSingleline: Bool
        @Published var regexIsMultiline: Bool
        @Published var regexUsesUnicodeBoundaries: Bool
        
        @Published var textMatchesFullWord: Bool
        @Published var regexUnescapesReplacementString: Bool
        
        
        
        // MARK: - Lifecycle
        
        init(settings: MultipleReplace.Settings) {
            
            self.textIsLiteralSearch = settings.textualOptions.contains(.literal)
            self.textIgnoresDiacriticMarks = settings.textualOptions.contains(.diacriticInsensitive)
            self.textIgnoresWidth = settings.textualOptions.contains(.widthInsensitive)
            
            self.regexIsSingleline = settings.regexOptions.contains(.dotMatchesLineSeparators)
            self.regexIsMultiline = settings.regexOptions.contains(.anchorsMatchLines)
            self.regexUsesUnicodeBoundaries = settings.regexOptions.contains(.useUnicodeWordBoundaries)
            
            self.textMatchesFullWord = settings.matchesFullWord
            self.regexUnescapesReplacementString = settings.unescapesReplacementString
        }
        
        
        var settings: MultipleReplace.Settings {
            
            let textualOptions = String.CompareOptions()
                .union(self.textIsLiteralSearch ? .literal : [])
                .union(self.textIgnoresDiacriticMarks ? .diacriticInsensitive : [])
                .union(self.textIgnoresWidth ? .widthInsensitive : [])
            
            let regexOptions = NSRegularExpression.Options()
                .union(self.regexIsSingleline ? .dotMatchesLineSeparators : [])
                .union(self.regexIsMultiline ? .anchorsMatchLines : [])
                .union(self.regexUsesUnicodeBoundaries ? .useUnicodeWordBoundaries : [])
            
            return MultipleReplace.Settings(textualOptions: textualOptions,
                                            regexOptions: regexOptions,
                                            matchesFullWord: self.textMatchesFullWord,
                                            unescapesReplacementString: self.regexUnescapesReplacementString)
        }
    }
}
