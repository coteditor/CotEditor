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
    
    let id = UUID()
    
    var name: String
    var shortcut: Shortcut?
    var format: String = ""
}


extension Snippet {
    
    private enum CodingKeys: String, CodingKey {
        
        case name
        case shortcut
        case format
    }
    
    
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
        
        return dictionary.mapKeys(\.rawValue)
    }
}


extension Snippet {
    
    enum Variable: String, TokenRepresentable {
        
        static let prefix = "<<<"
        static let suffix = ">>>"
        
        case cursor = "CURSOR"
        case selection = "SELECTION"
        
        
        var description: String {
            
            switch self {
                case .cursor:
                    return "The insertion point after inserting the snippet."
                case .selection:
                    return "The selected text."
            }
        }
    }
    
    
    /// Return strings to insert.
    ///
    /// - Parameters:
    ///   - string: The whole content string where to insert the snippet.
    ///   - ranges: The current selected ranges.
    /// - Returns: Strings to insert and the content-based selected ranges.
    func insertions(for string: String, ranges: [NSRange]) -> (strings: [String], selectedRanges: [NSRange]?) {
        
        var offset = 0
        let insertions = ranges.map { (range) in
            let selectedString = (string as NSString).substring(with: range)
            let indent = string.rangeOfIndent(at: range.location)
                .flatMap { (string as NSString).substring(with: $0) } ?? ""
            
            let insertion = self.insertion(selectedString: selectedString, indent: indent)
            let selectedRanges = insertion.selectedRanges.map { $0.shifted(by: range.location + offset) }
            offset += insertion.string.length - range.length
            
            return (string: insertion.string, ranges: selectedRanges)
        }
        let selectedRanges = insertions.flatMap(\.ranges)
        
        return (insertions.map(\.string), selectedRanges.isEmpty ? nil : selectedRanges)
    }
    
    
    /// Return a string to insert.
    ///
    /// - Parameters:
    ///   - selectedString: The selected string.
    ///   - indent: The indent string to insert.
    /// - Returns: A string to insert and the snippet-based selected ranges.
    func insertion(selectedString: String, indent: String = "") -> (string: String, selectedRanges: [NSRange]) {
        
        assert(indent.allSatisfy(\.isWhitespace))
        
        let format = self.format
            .replacingOccurrences(of: "(?<=\\R)", with: indent, options: .regularExpression)  // indent
            .replacingOccurrences(of: Variable.selection.token, with: selectedString)  // selection
        
        let cursors = (format as NSString).ranges(of: Variable.cursor.token)
        let ranges = cursors
                .enumerated()
                .map { $0.element.location - $0.offset * $0.element.length }
                .map { NSRange(location: $0, length: 0) }
        
        let text = format.replacingOccurrences(of: Variable.cursor.token, with: "")
        
        return (text, ranges)
    }
}
