//
//  TextFind.Error+Localization.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2025 1024jp
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
import TextFind

extension TextFind.Error: @retroactive LocalizedError {
    
    public var errorDescription: String? {
        
        switch self {
            case .regularExpression:
                String(localized: "TextFind.Error.regularExpression.errorDescription",
                       defaultValue: "Invalid regular expression",
                       table: "TextFind")
            case .emptyFindString:
                String(localized: "TextFind.Error.emptyFindString.errorDescription",
                       defaultValue: "Empty find string",
                       table: "TextFind")
            case .emptyInSelectionSearch:
                String(localized: "TextFind.Error.emptyInSelectionSearch.errorDescription",
                       defaultValue: "The option “in selection” is selected, although nothing is selected.",
                       table: "TextFind")
        }
    }
    
    
    public var recoverySuggestion: String? {
        
        switch self {
            case .regularExpression(let reason):
                reason
            case .emptyFindString:
                String(localized: "TextFind.Error.emptyFindString.recoverySuggestion",
                       defaultValue: "Input text to find.",
                       table: "TextFind")
            case .emptyInSelectionSearch:
                String(localized: "TextFind.Error.emptyInSelectionSearch.recoverySuggestion",
                       defaultValue: "Select the search scope in the document or deselect the “in selection” option.",
                       table: "TextFind")
        }
    }
}
