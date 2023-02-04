//
//  Snippet.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-27.
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

import Foundation.NSString

struct Snippet: Identifiable, Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case name
        case shortcut
        case format
    }
    
    let id = UUID()
    
    var name: String
    var shortcut: Shortcut?
    var format: String = ""
}


extension Snippet {
    
    init?(dictionary: [String: String]) {
        
        guard let name = dictionary[CodingKeys.name.stringValue] else { return nil }
        
        self.name = name
        if let keySpecChar = dictionary[CodingKeys.shortcut.stringValue] {
            self.shortcut = Shortcut(keySpecChars: keySpecChar)
        }
        self.format = dictionary[CodingKeys.format.stringValue] ?? ""
    }
    
    
    var dictionary: [String: String] {
        
        var dictionary = [CodingKeys.name: self.name]
        dictionary[.shortcut] = self.shortcut?.keySpecChars
        dictionary[.format] = self.format
        
        return dictionary.mapKeys(\.stringValue)
    }
}


extension Snippet {
    
    enum Variable: String, TokenRepresentable {
        
        static let prefix = "<<<"
        static let suffix = ">>>"
        
        case cursor = "CURSOR"
        
        
        var description: String {
            
            switch self {
                case .cursor:
                    return "The insertion point after inserting the snippet."
            }
        }
    }
    
    
    /// String to insert.
    var string: String {
        
        self.tokenRanges(for: .cursor)
            .reversed()
            .reduce(self.format) { ($0 as NSString).replacingCharacters(in: $1, with: "") }
    }
    
    
    /// The selected ranges in snippet string.
    var selections: [NSRange] {
        
        self.tokenRanges(for: .cursor)
            .enumerated()
            .map { $0.element.location - $0.offset * $0.element.length }
            .map { NSRange(location: $0, length: 0) }
    }
    
    
    /// Return a copy of the receiver by inserting the given ident to every new line.
    ///
    /// - Parameter indent: The indent string to insert.
    /// - Returns: An indented snippet.
    func indented(with indent: String) -> Self {
        
        guard !indent.isEmpty else { return self }
        
        let format = self.format.replacingOccurrences(of: "(?<=\\R)", with: indent, options: .regularExpression)
        
        return Snippet(name: self.name, shortcut: self.shortcut, format: format)
    }
    
    
    
    // MARK: Private Methods
    
    private func tokenRanges(for variable: Variable) -> [NSRange] {
        
        (self.format as NSString).ranges(of: variable.token)
    }
}
