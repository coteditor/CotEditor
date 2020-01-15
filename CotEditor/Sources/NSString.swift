//
//  String+NSRange.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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
    
    /// Whole range in NSRange
    var nsRange: NSRange {
        
        return NSRange(..<(self as NSString).length)
    }
    
    
    var length: Int {
        
        return self.utf16.count
    }
    
}



extension NSRange {
    
    static let notFound = NSRange(location: NSNotFound, length: 0)
    
    
    /// A Boolean value indicating whether the range contains no elements.
    var isEmpty: Bool {
        
        return (self.length == 0)
    }
    
    
    /// Check if the given index is in the receiver or touchs to one of the receiver's bounds.
    ///
    /// - Parameter index: The index to test.
    func touches(_ index: Int) -> Bool {
        
        return self.lowerBound <= index && index <= self.upperBound
    }
    
    
    
    /// Check if the two ranges overlap or touch each other.
    ///
    /// - Parameter range: The range to test.
    /// - Note: Unlike Swift.Range's `overlaps(_:)`, this method returns `true` when a range length is 0.
    func touches(_ range: NSRange) -> Bool {
        
        if self.location == NSNotFound { return false }
        if range.location == NSNotFound { return false }
        if self.upperBound < range.lowerBound { return false }
        if range.upperBound < self.lowerBound { return false }
        
        return true
    }
    
    
    /// Return a copied NSRange but whose location is shifted toward the given `offset`.
    ///
    /// - Parameter offset: The offset to shift.
    /// - Returns: A new NSRange.
    func shifted(offset: Int) -> NSRange {
        
        return NSRange(location: self.location + offset, length: self.length)
    }
    
}



extension NSString {
    
    /// Whole range in NSRange
    var range: NSRange {
        
        return NSRange(..<self.length)
    }
    
    
    /// Return NSRange-based character index where just before the given character index
    /// by taking grapheme clusters into account.
    ///
    /// - Parameter location: NSRange-based character index to refer.
    /// - Returns: NSRange-based character index just before the given `location`,
    ///            or `0` when the given `location` is the first.
    func index(before location: Int) -> Int {
        
        guard location > 0 else { return 0 }
        
        let range = NSRange(location: location - 1, length: 0)
        
        return self.rangeOfComposedCharacterSequences(for: range).lowerBound
    }
    
    
    /// Return NSRange-based character index where just after the given character index
    /// by taking grapheme clusters into account.
    ///
    /// - Parameter location: NSRange-based character index to refer.
    /// - Returns: NSRange-based character index just before the given `location`,
    ///            or `location` when the given `location` is the last.
    func index(after location: Int) -> Int {
        
        guard location < self.length else { return self.length }
        
        let range = NSRange(location: location + 1, length: 0)
        
        return self.rangeOfComposedCharacterSequences(for: range).lowerBound
    }
    
    
    /// Find and return ranges of passed-in substring with the given range of receiver.
    ///
    /// - Parameters:
    ///   - searchString: The string for which to search.
    ///   - options: A mask specifying search options.
    ///   - searchRange: The range with in the receiver for which to search for aString.
    /// - Returns: An array of NSRange in the receiver of `searchString` within `searchRange`.
    func ranges(of searchString: String, options: NSString.CompareOptions = .literal, range searchRange: NSRange? = nil) -> [NSRange] {
        
        let searchRange = searchRange ?? self.range
        var ranges = [NSRange]()
        
        var location = searchRange.location
        while location != NSNotFound {
            let range = self.range(of: searchString, options: options, range: NSRange(location..<searchRange.upperBound))
            location = range.upperBound
            
            guard range.location != NSNotFound else { break }
            
            ranges.append(range)
        }
        
        return ranges
    }
    
    
    /// line range containing a given location
    func lineRange(at location: Int) -> NSRange {
        
        return self.lineRange(for: NSRange(location..<location))
    }
    
    
    /// line range containing a given location
    func lineContentsRange(at location: Int) -> NSRange {
        
        return self.lineContentsRange(for: NSRange(location..<location))
    }
    
    
    /// Return line range excluding last line ending character if exists.
    ///
    /// - Parameters:
    ///   - range: A range within the receiver.
    /// - Returns: The range of characters representing the line or lines containing a given range.
    func lineContentsRange(for range: NSRange) -> NSRange {
        
        var start = 0
        var contentsEnd = 0
        self.getLineStart(&start, end: nil, contentsEnd: &contentsEnd, for: range)
        
        return NSRange(start..<contentsEnd)
    }
    
    
    /// Calculate line-by-line ranges that given ranges include.
    ///
    /// - Parameters:
    ///   - ranges: Ranges to include.
    ///   - includingLastEmptyLine: Whether the last empty line sould be included; otherwise, return value can be empty.
    /// - Returns: Array of ranges of each indivisual line.
    func lineRanges(for ranges: [NSRange], includingLastEmptyLine: Bool = false) -> [NSRange] {
        
        guard !ranges.isEmpty else { return [] }
        
        if includingLastEmptyLine,
            ranges == [NSRange(location: self.length, length: 0)],
            (self.length == 0 || self.character(at: self.length - 1) == "\n".utf16.first) {
            return ranges
        }
        
        var lineRanges = OrderedSet<NSRange>()
        
        // get line ranges to process
        for range in ranges {
            let linesRange = self.lineRange(for: range)
            
            // store each line to process
            self.enumerateSubstrings(in: linesRange, options: [.byLines, .substringNotRequired]) { (_, _, enclosingRange, _) in
                
                lineRanges.append(enclosingRange)
            }
        }
        
        return lineRanges.array
    }
    
    
    /// Find the widest character range that contains the given `index` and not contains given character set.
    ///
    /// - Parameters:
    ///   - set: The character set to end expanding range.
    ///   - index: The index of character to be contained to the result range. `index` must be within `range`.
    ///   - range: The range in which to search. `range` must not exceed the bounds of the receiver.
    /// - Returns: The found character range.
    func rangeOfCharacter(until set: CharacterSet, at index: Int, range: NSRange? = nil) -> NSRange {
        
        let range = range ?? NSRange(..<self.length)
        
        assert(range.contains(index))
        
        let lowerDelimiterRange = self.rangeOfCharacter(from: set, options: .backwards, range: NSRange(range.lowerBound..<index))
        let lowerBound = (lowerDelimiterRange != .notFound) ? lowerDelimiterRange.upperBound : range.lowerBound
        
        let upperDelimiterRange = self.rangeOfCharacter(from: set, range: NSRange(index..<range.upperBound))
        let upperBound = (upperDelimiterRange != .notFound) ? upperDelimiterRange.lowerBound : range.upperBound
        
        return NSRange(lowerBound..<upperBound)
    }
    
}
