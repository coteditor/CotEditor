//
//  String+Case.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-05-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2025 1024jp
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

import Foundation.NSRegularExpression

public extension String {
    
    /// Straightens all curly quotes.
    var straighteningQuotes: String {
        
        self.replacing(/[‘’‚‛]/, with: "'")   // U+2018..201B
            .replacing(/[“”„‟]/, with: "\"")  // U+201C..201F
    }
    
    
    /// The string transformed all camel- and pascal-case words to snake-case.
    var snakecased: String {
        
        self.ranges(pattern: #"(?<=\w)(?=\p{uppercase})"#)
            .reversed()
            .reduce(into: self.lowercased()) { (string, range) in
                string.replaceSubrange(range, with: "_")
            }
    }
    
    
    /// The string transformed all snake- and pascal-case words to camel-case.
    var camelcased: String {
        
        self.ranges(pattern: #"(?<=\w)(?:\p{uppercase}|_\w)"#)
            .reversed()
            .reduce(into: self.lowercased()) { (string, range) in
                string.replaceSubrange(range, with: string[range].last!.uppercased())
            }
    }
    
    
    /// The string transformed all snake- and camel-case words to pascal-case.
    var pascalcased: String {
        
        self.ranges(pattern: #"(?:\b|(?<=\w)_)\w"#)
            .reversed()
            .reduce(into: self) { (string, range) in
                string.replaceSubrange(range, with: string[range].last!.uppercased())
            }
    }
    
    
    // MARK: Private Methods
    
    /// Returns the ranges matching the given regular expression pattern.
    ///
    /// - Parameter pattern: The regular expression pattern.
    /// - Returns: The ranges of matched.
    private func ranges(pattern: String) -> [Range<Index>] {
        
        (try! NSRegularExpression(pattern: pattern))
            .matches(in: self, range: NSRange(..<self.utf16.count))
            .map(\.range)
            .map { String.Index(utf16Offset: $0.lowerBound, in: self)..<String.Index(utf16Offset: $0.upperBound, in: self) }
    }
}
