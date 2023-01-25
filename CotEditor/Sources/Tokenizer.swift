//
//  Tokenizer.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-28.
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

import Foundation.NSRegularExpression

protocol TokenRepresentable: CaseIterable {
    
    static var prefix: String { get }
    static var suffix: String { get }
    
    var token: String { get }
    var description: String { get }
    var localizedDescription: String { get }
}


extension TokenRepresentable where Self: RawRepresentable, Self.RawValue == String {
    
    var token: String {
        
        Self.prefix + self.rawValue + Self.suffix
    }
    
    
    var localizedDescription: String {
        
        self.description.localized
    }
    
    
    static var tokenizer: Tokenizer {
        
        Tokenizer(tokens: Self.allCases.map(\.rawValue), prefix: Self.prefix, suffix: Self.suffix)
    }
}



// MARK: -

final class Tokenizer: Sendable {
    
    let tokens: [String]
    let prefix: String
    let suffix: String
    
    private let regex: NSRegularExpression
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(tokens: [String], prefix: String, suffix: String) {
        
        assert(tokens.allSatisfy({ !$0.isEmpty && $0 == NSRegularExpression.escapedPattern(for: $0) }))
        
        self.tokens = tokens
        self.prefix = prefix
        self.suffix = suffix
        
        let prefixPattern = NSRegularExpression.escapedPattern(for: prefix)
        let suffixPattern = NSRegularExpression.escapedPattern(for: suffix)
        let pattern = prefixPattern + "(" + tokens.joined(separator: "|") + ")" + suffixPattern
        
        self.regex = try! NSRegularExpression(pattern: pattern)
    }
    
    
    
    // MARK: Public Methods
    
    /// Tokenize given string.
    ///
    /// - Parameters:
    ///   - string: The string.
    ///   - range: Range to find tokens.
    ///   - block: The block enumerates the matches of the tokens in the string.
    ///   - token: Found token.
    ///   - range: Range of token including prefix and suffix.
    ///   - keywordRange: Range of keyword.
    func tokenize(_ string: String, range: NSRange? = nil, block: (_ token: String, _ range: NSRange, _ keywordRange: NSRange) -> Void) {
        
        self.regex.enumerateMatches(in: string, range: range ?? string.nsRange) { (match, _, _) in
            
            guard let match else { return }
            
            let token = (string as NSString).substring(with: match.range(at: 1))
            
            block(token, match.range, match.range(at: 1))
        }
    }
}
