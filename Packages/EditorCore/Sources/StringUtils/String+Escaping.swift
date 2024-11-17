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
//  © 2016-2024 1024jp
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

public extension String {
    
    /// Unescaped version of the string by unescaping the characters with backslashes.
    var unescaped: String {
        
        // -> According to the Swift documentation, these are the all combinations with backslash.
        //    cf. https://docs.swift.org/swift-book/LanguageGuide/StringsAndCharacters.html#ID295
        let entities = [
            #"0"#: "\0",  // null character
            #"t"#: "\t",  // horizontal tab
            #"n"#: "\n",  // line feed
            #"r"#: "\r",  // carriage return
            #"""#: "\"",  // double quotation mark
            #"'"#: "\'",  // single quotation mark
            #"\"#: "\\",  // backslash
        ]
        
        return self.replacing(/\\([0tnr"'\\])/) { entities[String($0.1)]! }
    }
}


private let maxEscapesCheckLength = 8

public extension StringProtocol {
    
    /// Checks if character at the index is escaped with backslash.
    ///
    /// - Parameter index: The index of the character to check.
    /// - Returns: `true` when the character at the given index is escaped.
    func isEscaped(at index: Index) -> Bool {
        
        let escapes = self[..<index].suffix(maxEscapesCheckLength).reversed().prefix { $0 == "\\" }
        
        return !escapes.count.isMultiple(of: 2)
    }
    
    
    /// Checks if character at the location in UTF16 is escaped with backslash.
    ///
    /// - Parameter location: The UTF16-based location of the character to check.
    /// - Returns: `true` when the character at the given index is escaped.
    func isEscaped(at location: Int) -> Bool {
        
        let escape = 0x005C
        let index = UTF16View.Index(utf16Offset: location, in: self)
        let escapes = self.utf16[..<index].suffix(maxEscapesCheckLength).reversed().prefix { $0 == escape }
        
        return !escapes.count.isMultiple(of: 2)
    }
}
