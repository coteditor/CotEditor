//
//  CodeUnit.swift
//  EditorCore
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-10-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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

extension UTF32.CodeUnit {
    
    /// The standard hexadecimal representation of the code unit.
    var codePoint: String {
        
        String(self, radix: 16, uppercase: true)
            .leftPadding(toLength: 4, withPad: "0")
    }
}


extension UTF16.CodeUnit {
    
    /// The standard hexadecimal representation of the code unit.
    var codePoint: String {
        
        String(self, radix: 16, uppercase: true)
            .leftPadding(toLength: 4, withPad: "0")
    }
}


private extension String {
    
    /// Returns a new string padded on the left to at least the specified length.
    ///
    /// - Parameters:
    ///   - length: The minimum length of the resulting string.
    ///   - character: The character to use for left padding.
    /// - Returns: The left-padded string, or the original string if no padding is needed.
    func leftPadding(toLength length: Int, withPad character: Character) -> String {
        
        if self.count < length {
            String(repeating: character, count: length - self.count) + self
        } else {
            self
        }
    }
}
