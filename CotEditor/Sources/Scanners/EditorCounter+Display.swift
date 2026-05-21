//
//  EditorCounter+Display.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-21.
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

import Foundation

enum CountType: CaseIterable {
    
    case lines
    case characters
    case words
    case location
    case line
    case column
    
    static let countCases: [Self] = [.lines, .characters, .words]
    static let positionCases: [Self] = [.location, .line, .column]
    
    
    /// The counter type corresponding to the count type.
    var counterTypes: EditorCounter.Types {
        
        switch self {
            case .lines: .lines
            case .characters: .characters
            case .words: .words
            case .location: .location
            case .line: .line
            case .column: .column
        }
    }
    
    
    /// The localized label for the count type.
    var label: String {
        
        switch self {
            case .lines:
                String(localized: "CountType.lines.label", defaultValue: "Lines", table: "Document")
            case .characters:
                String(localized: "CountType.characters.label", defaultValue: "Characters", table: "Document")
            case .words:
                String(localized: "CountType.words.label", defaultValue: "Words", table: "Document")
            case .location:
                String(localized: "CountType.location.label", defaultValue: "Location", table: "Document")
            case .line:
                String(localized: "CountType.line.label", defaultValue: "Line", table: "Document")
            case .column:
                String(localized: "CountType.column.label", defaultValue: "Column", table: "Document")
        }
    }
}


extension EditorCounter.Result {
    
    /// Returns the formatted value for the given count type.
    ///
    /// - Parameters:
    ///   - type: The count type to format.
    ///   - forAccessibility: Whether to return the value in a form suitable for accessibility output.
    /// - Returns: The formatted value, or `nil` if the value is not available.
    func formattedValue(type: CountType, forAccessibility: Bool = false) -> String? {
        
        switch type {
            case .characters: self.characters.formatted(forAccessibility: forAccessibility)
            case .lines: self.lines.formatted(forAccessibility: forAccessibility)
            case .words: self.words.formatted(forAccessibility: forAccessibility)
            case .location: self.location?.formatted()
            case .line: self.line?.formatted()
            case .column: self.column?.formatted()
        }
    }
}


private extension EditorCounter.Count {
    
    /// Returns the formatted count value.
    ///
    /// - Parameter forAccessibility: Whether to return the value in a form suitable for accessibility output.
    /// - Returns: The formatted count value, or `nil` if the entire count is not available.
    func formatted(forAccessibility: Bool) -> String? {
        
        if let entire, self.selected > 0 {
            "\(entire.formatted()) (\(forAccessibility ? String(localized: "\(self.selected) selected") : self.selected.formatted()))"
        } else {
            self.entire?.formatted()
        }
    }
}
