//
//  String+Range.swift
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

/*
 Negative location accesses elements from the end of element counting backwards.
 e.g. `location == -1` is the last character / last.
 
 Likewise, negative length can be used to select rest elements except the last one element.
 e.g. `location: 3`, `length: -1` where string has 10 lines.
 -> element 3 to 9 (NSRange(3, 6)) will be retruned
 
 
 Well, this category is not so useful as you thought.
 */
extension String {
    
    /// convert location/length allowing negative value to valid NSRange.
    func range(location: Int, length: Int) -> NSRange {
        
        let wholeLength = self.utf16.count
        
        let newLocation = (location < 0) ? (wholeLength + location) : location
        var newLength = (length < 0) ? (wholeLength - newLocation + length) : length
        if newLocation < wholeLength, (newLocation + newLength) > wholeLength {
            newLength = wholeLength - newLocation
        }
        if length < 0, newLength < 0 {
            newLength = 0
        }
        
        guard newLength >= 0, newLength >= 0 else { return NSRange() }
        
        return NSRange(location: newLocation, length: newLength)
    }
    
    
    /// Return character range for line location/length allowing negative value.
    ///
    /// - Parameters:
    ///   - location: Index of the first line in range. The line location starts not with 0 but with 1.
    ///               Passing 0 to the location will return NSNotFound.
    ///   - length: Number of lines to include.
    /// - Returns: Character range, or NSRange(NSNotFound, 0) if the given values are out of range.
    ///
    /// - Note: The last line break will be included.
    func rangeForLine(location: Int, length: Int) -> NSRange? {
        
        let wholeLength = self.utf16.count
        let regex = try! NSRegularExpression(pattern: "^", options: .anchorsMatchLines)
        let matches = regex.matches(in: self, range: NSRange(location: 0, length: wholeLength))
        let count = matches.count
        
        guard !matches.isEmpty else { return nil }

        guard location != 0 else { return NSRange(location: 0, length: 0) }
        
        guard location <= count else { return NSRange(location: wholeLength, length: 0) }
        
        let newLocation = (location < 0) ? (count + location + 1) : location
        
        var newLength: Int
        if length < 0 {
            newLength = count - newLocation + length + 1
        } else if length == 0 {
            newLength = 1
        } else {
            newLength = length
        }
        if newLocation < count, (newLocation + newLength - 1) > count {
            newLength = count - newLength + 1
        }
        if length < 0, newLength < 0 {
            newLength = 1
        }
        
        guard newLocation > 0, newLength > 0 else { return nil }
        
        let match = matches[newLocation - 1]
        var range = match.range
        var tmpRange = range
        
        for _ in 1...newLength {
            guard NSMaxRange(tmpRange) <= wholeLength else { break }
            
            range = (self as NSString).lineRange(for: tmpRange)
            tmpRange.length = range.length + 1
        }
        if wholeLength < NSMaxRange(range) {
            range.length = wholeLength - range.location
        }
        
        return range
    }
    
}
