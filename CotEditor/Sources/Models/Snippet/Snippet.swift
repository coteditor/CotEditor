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
//  © 2017-2026 1024jp
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
import Shortcut
import StringUtils
import TextEditing

struct Snippet: Equatable, Identifiable {
    
    let id = UUID()
    
    var name: String
    var scope: String?
    var shortcut: Shortcut?
    var format: String = ""
}


extension Snippet: Codable {
    
    private enum CodingKeys: String, CodingKey {
        
        case name
        case scope
        case shortcut
        case format
    }
    
    
    init?(dictionary: [String: String]) {
        
        guard let name = dictionary[CodingKeys.name.stringValue] else { return nil }
        
        self.name = name
        self.scope = dictionary[CodingKeys.scope.stringValue]
        self.shortcut = dictionary[CodingKeys.shortcut.stringValue].flatMap(Shortcut.init(keySpecChars:))
        self.format = dictionary[CodingKeys.format.stringValue] ?? ""
    }
    
    
    var dictionary: [String: String] {
        
        var dictionary = [CodingKeys.name: self.name]
        dictionary[.scope] = self.scope
        dictionary[.shortcut] = self.shortcut?.keySpecChars
        dictionary[.format] = self.format
        
        return dictionary.mapKeys(\.rawValue)
    }
}


extension Snippet {
    
    enum Variable: String, CaseIterable, TokenRepresentable {
        
        static let prefix = "<<<"
        static let suffix = ">>>"
        
        case selection = "SELECTION"
        case cursor = "CURSOR"
        
        
        var localizedDescription: String {
            
            switch self {
                case .selection:
                    String(localized: "Snippet.Variable.selection.description",
                           defaultValue: "The selected text.")
                case .cursor:
                    String(localized: "Snippet.Variable.cursor.description",
                           defaultValue: "The insertion point after inserting the snippet.")
            }
        }
    }
    
    
    /// Returns strings to insert.
    ///
    /// - Parameters:
    ///   - string: The whole content string where to insert the snippet.
    ///   - ranges: The current selected ranges.
    /// - Returns: An `EditingContext` containing strings to insert and selected ranges.
    func insertions(for string: String, ranges: [NSRange]) -> EditingContext {
        
        var offset = 0
        let insertions = ranges.map { range in
            let selectedString = (string as NSString).substring(with: range)
            let indent = string.rangeOfIndent(at: range.location)
                .map((string as NSString).substring(with:)) ?? ""
            
            let insertion = self.insertion(selectedString: selectedString, indent: indent)
            let selectedRanges = insertion.selectedRanges.map { $0.shifted(by: range.location + offset) }
            offset += insertion.string.length - range.length
            
            return (string: insertion.string, ranges: selectedRanges)
        }
        let selectedRanges = insertions.flatMap(\.ranges)
        
        return EditingContext(strings: insertions.map(\.string), ranges: ranges,
                              selectedRanges: selectedRanges.isEmpty ? nil : selectedRanges)
    }
    
    
    /// Returns a string to insert.
    ///
    /// - Parameters:
    ///   - selectedString: The selected string.
    ///   - indent: The indent string to insert.
    /// - Returns: A string to insert and the snippet-based selected ranges.
    func insertion(selectedString: String, indent: String = "") -> (string: String, selectedRanges: [NSRange]) {
        
        assert(indent.allSatisfy(\.isWhitespace))
        
        // split at the cursor tokens before inserting the selection,
        // so that a cursor token contained in the selection is kept as is
        let parts = self.format
            .replacing(/\R/) { $0.output + indent }  // indent
            .components(separatedBy: Variable.cursor.token)
            .map { $0.replacing(Variable.selection.token, with: selectedString) }  // selection
        
        var text = ""
        var ranges: [NSRange] = []
        for (index, part) in parts.enumerated() {
            if index > 0 {
                ranges.append(NSRange(location: (text as NSString).length, length: 0))
            }
            text += part
        }
        
        return (text, ranges)
    }
}
