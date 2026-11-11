//
//  StringProtocol+Spacing.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-11-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

extension StringProtocol {
    
    /// The string with each run of whitespace replaced with a single space.
    var collapsingWhitespace: String {
        
        var result = ""
        result.reserveCapacity(self.utf8.count)
        var isAfterWhitespace = false
        
        for character in self {
            if character.isWhitespace {
                if !isAfterWhitespace {
                    result.append(" ")
                }
                isAfterWhitespace = true
            } else {
                result.append(character)
                isAfterWhitespace = false
            }
        }
        
        return result
    }
    
    
    /// Returns the clause with normalized spacing.
    ///
    /// Each run of whitespace becomes a single space, except after `openings` and before `closings`, where it is removed,
    /// and each comma becomes `, ` without whitespace before it.
    ///
    /// - Parameters:
    ///   - openings: The characters after which whitespace is removed.
    ///   - closings: The characters before which whitespace is removed.
    ///   - trailingCommaClosings: The characters before which a comma is removed.
    /// - Returns: The normalized clause.
    func normalizingClauseSpacing(openings: Set<Character>, closings: Set<Character>, trailingCommaClosings: Set<Character> = []) -> String {
        
        var result = ""
        result.reserveCapacity(self.utf8.count)
        var isAfterOpening = false
        var hasSpace = false
        var hasComma = false
        
        for character in self {
            if character.isWhitespace {
                hasSpace = true
                continue
            }
            
            if character == "," {
                if hasComma {
                    result += ", "
                }
                hasComma = true
                hasSpace = false
                continue
            }
            
            if hasComma {
                if !trailingCommaClosings.contains(character) {
                    result += ", "
                }
            } else if hasSpace, !isAfterOpening, !closings.contains(character) {
                result += " "
            }
            result.append(character)
            isAfterOpening = openings.contains(character)
            hasSpace = false
            hasComma = false
        }
        
        if hasComma {
            result += ", "
        } else if hasSpace, !isAfterOpening {
            result += " "
        }
        
        return result
    }
}
