//
//  RegexParseMode.swift
//  RegexHighlighting
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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

public enum RegexParseMode: Equatable, Sendable {
    
    case search
    case replacement(unescapes: Bool)
}


extension RegexParseMode {
    
    /// Validates a string as a regular expression pattern in the receiver's parse mode.
    ///
    /// - Parameters:
    ///   - pattern: The string to validate.
    /// - Returns: `true` if the string is valid or no validation is required.
    func validate(pattern: String) -> Bool {
        
        switch self {
            case .search:
                (try? NSRegularExpression(pattern: pattern)) != nil
            case .replacement:
                true
        }
    }
}
