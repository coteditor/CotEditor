//
//  String+Match.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-09-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2024 1024jp
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

struct FilteredItem<Value: Identifiable & Sendable>: Identifiable, Sendable {
    
    enum State {
        
        case noFilter
        case filtered([Range<String.Index>])
    }
    
    var value: Value
    var state: State
    var string: String
    
    var id: Value.ID { self.value.id }
    
    
    /// Attributed string of which matched parts are styled as `.inlinePresentationIntent = .stronglyEmphasized`.
    var attributedString: AttributedString {
        
        var attributedString = AttributedString(self.string)
        
        switch self.state {
            case .noFilter:
                return attributedString
                
            case .filtered(let ranges):
                for range in ranges {
                    guard let attrRange = Range(range, in: attributedString) else { continue }
                    
                    attributedString[attrRange].inlinePresentationIntent = .stronglyEmphasized
                }
                
                return attributedString
        }
    }
}


extension Identifiable where Self: Sendable {
    
    /// Filters with given string.
    ///
    /// - Parameters:
    ///   - filter: The search string.
    ///   - keyPath: The key path to value to filter.
    /// - Returns: A FilteredItem when matched or not filtered, otherwise `nil`.
    func filter(_ filter: String, keyPath: KeyPath<Self, String>) -> FilteredItem<Self>? {
        
        if filter.isEmpty {
            FilteredItem(value: self, state: .noFilter, string: self[keyPath: keyPath])
        } else if let ranges = self[keyPath: keyPath].abbreviatedMatchedRanges(with: filter) {
            FilteredItem(value: self, state: .filtered(ranges), string: self[keyPath: keyPath])
        } else {
            nil
        }
    }
}


extension String {
    
    struct AbbreviatedMatchResult {
        
        var ranges: [Range<String.Index>]
        var remaining: String
        var score: Int
    }
    
    
    /// Searches ranges of the characters contains in the `searchString` in the `searchString` order.
    ///
    /// - Parameter searchString: The string to search.
    /// - Returns: The matched character ranges and score, or `nil` if not matched.
    func abbreviatedMatch(with searchString: String) -> AbbreviatedMatchResult? {
        
        guard let ranges = self.abbreviatedMatchedRanges(with: searchString, incomplete: true) else { return nil }
        
        let remaining = String(searchString.suffix(searchString.count - ranges.count))
        
        // just simply calculate the length...
        let score = self.distance(from: ranges.first!.lowerBound, to: ranges.last!.upperBound)
        
        return AbbreviatedMatchResult(ranges: ranges, remaining: remaining, score: score)
    }
    
    
    /// Searches ranges of the characters contains in the `searchString` in the `searchString` order.
    ///
    /// - Parameters:
    ///   - searchString: The string to search.
    ///   - incomplete: If `true`, returns the ranges up to the part found, even if not found completely.
    /// - Returns: The matched character ranges, or `nil` if not matched.
    func abbreviatedMatchedRanges(with searchString: String, incomplete: Bool = false) -> [Range<String.Index>]? {
        
        guard !searchString.isEmpty, !self.isEmpty else { return nil }
        
        var ranges: [Range<String.Index>] = []
        for character in searchString {
            let index = ranges.last?.upperBound ?? self.startIndex
            
            guard let range = self.range(of: String(character), options: .caseInsensitive, range: index..<self.endIndex) else {
                if incomplete { break } else { return nil }
            }
            
            ranges.append(range)
        }
        
        return ranges.isEmpty ? nil : ranges
    }
}
