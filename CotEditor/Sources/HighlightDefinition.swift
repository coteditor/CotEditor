//
//  HighlightDefinition.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-05-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2023 1024jp
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

struct HighlightDefinition: Equatable {
    
    enum `Error`: Swift.Error {
        
        case invalidFormat
    }
    
    
    var beginString: String = ""
    var endString: String?
    var isRegularExpression: Bool = false
    var ignoreCase: Bool = false
    
    var description: String?
    
    
    
    init(dictionary: [String: Any]) throws {
        
        guard let beginString = dictionary[SyntaxDefinitionKey.beginString] as? String else { throw Error.invalidFormat }
        
        self.beginString = beginString
        if let endString = dictionary[SyntaxDefinitionKey.endString] as? String, !endString.isEmpty {
            self.endString = endString
        }
        self.isRegularExpression = (dictionary[SyntaxDefinitionKey.regularExpression] as? Bool) ?? false
        self.ignoreCase = (dictionary[SyntaxDefinitionKey.ignoreCase] as? Bool) ?? false
    }
    
    
    /// create a regex type definition from simple words by considering non-word characters around words
    init(words: [String], ignoreCase: Bool) {
        
        assert(!words.isEmpty)
        
        let escapedWords = words.sorted().reversed().map(NSRegularExpression.escapedPattern(for:))  // reverse to precede longer word
        let rawBoundary = String(Set(words.joined() + "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_").sorted())
            .replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        let boundary = NSRegularExpression.escapedPattern(for: rawBoundary)
        let pattern = "(?<![" + boundary + "])" + "(?:" + escapedWords.joined(separator: "|") + ")" + "(?![" + boundary + "])"
        
        self.beginString = pattern
        self.endString = nil
        self.isRegularExpression = true
        self.ignoreCase = ignoreCase
    }
}
