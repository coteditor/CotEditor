//
//  SortPattern.swift
//  LineSort
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-01-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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
import StringUtils

public enum SortPatternError: Error {
    
    case emptyPattern
    case invalidRegularExpressionPattern
}


public protocol SortPattern: Equatable, Sendable {
    
    func sortKey(for line: String) -> String?
    func range(for line: String) -> Range<String.Index>?
    func validate() throws(SortPatternError)
}


extension SortPattern {
    
    /// Sorts given lines with the receiver's pattern.
    ///
    /// - Parameters:
    ///   - string: The string to sort.
    ///   - options: Compare options for sort.
    ///   - baseLineEnding: The line ending to add when a line without one moves before a line-ending slot.
    /// - Returns: Sorted string.
    public func sort(_ string: String, options: SortOptions = SortOptions(), baseLineEnding: String? = nil) -> String {
        
        var lines = string.logicalLines(in: string.range)
        let includesTrailingLineEnding = (lines.last?.lineEnding != nil)
        
        guard
            lines.count > 1,
            let baseLineEnding = baseLineEnding ?? lines.compactMap(\.lineEnding).first
        else { return string }
        
        let firstLine = options.keepsFirstLine ? lines.removeFirst() : nil
        
        lines = lines
            .map { line in (line: line, key: self.sortKey(for: line.contents).map { (string: $0, number: options.parse($0)) }) }
            .sorted {
                switch ($0.key, $1.key) {
                    case let (.some(lhs), .some(rhs)):
                        // -> swap keys instead of reversing the result to keep lines with the same key and those without a key in their original order
                        let (key0, key1) = options.descending ? (rhs, lhs) : (lhs, rhs)
                        
                        // sort items by evaluating values as numbers
                        // -> This code still ignores numbers in the middle of keys.
                        if let number0 = key0.number,
                           let number1 = key1.number,
                           number0 != number1
                        {
                            return number0 < number1
                        }
                        return key0.string.compare(key1.string, options: options.compareOptions, locale: options.usedLocale) == .orderedAscending
                        
                    case (.none, .some):
                        return false
                        
                    case (.some, .none):
                        return true
                        
                    case (.none, .none):
                        return false
                }
            }
            .map(\.line)
        
        if let firstLine {
            lines.insert(firstLine, at: 0)
        }
        
        return lines.joined(baseLineEnding: baseLineEnding, includingTrailingLineEnding: includesTrailingLineEnding)
    }
}
