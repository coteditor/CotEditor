//
//  String+Escaping.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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

public import Foundation

public extension String {
    
    /// Unescaped version of the string by unescaping the characters with backslashes.
    ///
    /// This method does not support Unicode scalar escape (`\u{n}`).
    var unescaped: String {
        
        self.replacing(/\\([0tnr"'\\])/) { match in
            // -> According to the Swift documentation, these are the all combinations with backslash.
            //    cf. https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html#ID295
            switch match.1 {
                case "0": "\0"  // null character
                case "t": "\t"  // horizontal tab
                case "n": "\n"  // line feed
                case "r": "\r"  // carriage return
                case "\"": "\""  // double quotation mark
                case "'": "'"  // single quotation mark
                case "\\": "\\"  // backslash
                default: fatalError()
            }
        }
    }
}


private let maxEscapesCheckLength = 8

public extension StringProtocol {
    
    /// Checks if character at the index is escaped with the given character.
    ///
    /// - Parameters:
    ///   - index: The index of the character to check.
    ///   - character: The escape character.
    /// - Returns: `true` when the character at the given index is escaped.
    func isEscaped(at index: Index, by character: Character = "\\") -> Bool {
        
        let count = self[..<index].suffix(maxEscapesCheckLength)
            .reversed()
            .prefix { $0 == character }
            .count
        
        return !count.isMultiple(of: 2)
    }
}


public extension NSString {
    
    /// Checks if character at the location is escaped with the given character.
    ///
    /// - Parameters:
    ///   - location: The UTF16-based location of the character to check.
    ///   - escapeCharacter: The escape character.
    /// - Returns: `true` when the character at the given index is escaped.
    final func isEscaped(at location: Int, by escapeCharacter: Character = "\\") -> Bool {
        
        assert(escapeCharacter.utf16.count == 1)
        
        guard let codeUnit = escapeCharacter.utf16.first else { return false }
        
        let lowerBound = max(location - maxEscapesCheckLength, 0)
        let count = (lowerBound..<location)
            .reversed()
            .prefix { self.character(at: $0) == codeUnit }
            .count
        
        return !count.isMultiple(of: 2)
    }
}
