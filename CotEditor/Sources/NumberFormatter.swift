//
//  NumberFormatter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-09-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

extension NumberFormatter {
    
    /// Parse the leading part of the given string as number.
    ///
    /// - Parameter string: The string to parse.
    /// - Returns: The parsed number, or `nil` if failed.
    func leadingDouble(from string: String) -> Double? {
        
        guard let range = string.range(of: "[ \t]*-?[0-9.,]+", options: [.regularExpression, .anchored]) else { return nil }
        
        return self.number(from: String(string[range])) as? Double
    }
    
}
