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
//  © 2017-2022 1024jp
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

struct Snippet {
    
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
    
    
    // MARK: Private Properties
    
    private let format: String
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(_ format: String) {
        
        self.format = format
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
        
        return Self(format)
    }
    
    
    
    // MARK: Private Methods
    
    private func tokenRanges(for variable: Variable) -> [NSRange] {
        
        (self.format as NSString).ranges(of: variable.token)
    }
}
