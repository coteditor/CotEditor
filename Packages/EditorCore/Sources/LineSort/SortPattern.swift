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
//  © 2018-2024 1024jp
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
    /// - Returns: Sorted string.
    public func sort(_ string: String, options: SortOptions = SortOptions()) -> String {
        
        guard let lineEnding = string.firstLineEnding else { return string }
        
        var lines = string.components(separatedBy: .newlines)
        let firstLine = options.keepsFirstLine ? lines.removeFirst() : nil
        
        lines = lines
            .map { (line: $0, key: self.sortKey(for: $0)) }
            .sorted {
                switch ($0.key, $1.key) {
                    case let (.some(key0), .some(key1)):
                        // sort items by evaluating values as numbers
                        // -> This code still ignores numbers in the middle of keys.
                        if let number0 = options.parse(key0),
                           let number1 = options.parse(key1),
                           number0 != number1
                        {
                            return number0 < number1
                        }
                        return key0.compare(key1, options: options.compareOptions, locale: options.usedLocale) == .orderedAscending
                        
                    case (.none, .some):
                        return false
                        
                    case (.some, .none), (.none, .none):
                        return true
                }
            }
            .map(\.line)
        
        if options.descending {
            lines.reverse()
        }
        
        if let firstLine {
            lines.insert(firstLine, at: 0)
        }
        
        return lines.joined(separator: String(lineEnding))
    }
}
