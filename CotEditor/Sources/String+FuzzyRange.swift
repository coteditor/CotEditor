//
//  String+FuzzyRange.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2018 1024jp
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

extension String {
    
    /// Convert location/length allowing negative values to valid NSRange.
    ///
    /// - Note:
    ///   Negative location accesses elements from the end of element counting backwards.
    ///   For example, `location == -1` is the last character.
    ///
    ///   Likewise, a negative length can be used to select rest elements except the last one element.
    ///   e.g. `location: 3`, `length: -1` where string has 10 lines.
    ///   -> element 3 to 9 (NSRange(3, 6)) will be retruned
    ///
    /// - Parameters:
    ///   - location: Index of the first character.
    ///   - length: Length of the range.
    /// - Returns: A character range, or `nil` if the given values are out of range.
    func range(location: Int, length: Int) -> NSRange? {
        
        let wholeLength = self.utf16.count
        let newLocation = (location >= 0) ? location : (wholeLength + location)
        let newLength = (length >= 0) ? length : (wholeLength - newLocation + length)
        
        guard newLocation >= 0, newLength >= 0 else { return nil }
        
        return NSRange(newLocation..<min(newLocation + newLength, wholeLength))
    }
    
    
    /// Return character range for line location/length allowing negative values.
    ///
    /// - Note: The last new line character will be included.
    ///
    /// - Parameters:
    ///   - location: 1-based index of the first line in range. Passing 0 to the location will return `nil`.
    ///   - length: Number of lines to include.
    /// - Returns: A character range, or `nil` if the given values are out of range.
    func rangeForLine(location: Int, length: Int) -> NSRange? {
        
        let regex = try! NSRegularExpression(pattern: "^.*(?:\\R|\\z)", options: .anchorsMatchLines)
        let lineRanges = regex.matches(in: self, range: self.nsRange).map { $0.range }
        let count = lineRanges.count

        guard location != 0 else { return NSRange(location: 0, length: 0) }
        guard location <= count else { return NSRange(location: self.utf16.count, length: 0) }
        
        let newLocation = (location > 0) ? location - 1 : (count + location)  // 1-based to 0-based
        let newLength: Int = {
            switch length {
            case .min..<0:
                return count - newLocation + length - 1
            case 0:
                return 0
            default:
                return length - 1
            }
        }()
        
        guard
            let firstLineRange = lineRanges[safe: newLocation],
            let lastLineRange = lineRanges[safe: newLocation + newLength]
            else { return nil }
        
        return NSRange(firstLineRange.lowerBound..<lastLineRange.upperBound)
    }
    
}
