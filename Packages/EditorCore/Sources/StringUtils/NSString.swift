//
//  String+NSRange.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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

public import Foundation.NSString

public extension String {
    
    /// Returns a copied string to ensure it is not a kind of NSMutableString.
    var immutable: String {
        
        NSString(string: self) as String
    }
}


public extension StringProtocol {
    
    /// The whole range, expressed as an NSRange.
    var nsRange: NSRange {
        
        NSRange(location: 0, length: self.length)
    }
    
    
    /// The length expressed in UTF-16 code units (NSRange-compatible).
    var length: Int {
        
        self.utf16.count
    }
}


public extension NSString {
    
    /// The whole range, expressed as an NSRange.
    final var range: NSRange {
        
        NSRange(location: 0, length: self.length)
    }
    
    
    /// Returns the NSRange-based character index just before the given character index by taking grapheme clusters into account.
    ///
    /// - Parameter location: The NSRange-based character index to reference.
    /// - Returns: The NSRange-based character index just before the given `location`, or `0` when `location` is the first index.
    final func index(before location: Int) -> Int {
        
        guard location > 0 else { return 0 }
        
        // avoid returning index between CRLF
        let index = location - 1
        let isCRLF = (index > 0 && self.character(at: index) == 0xA && self.character(at: index - 1) == 0xD)
        
        return self.rangeOfComposedCharacterSequence(at: isCRLF ? index - 1 : index).lowerBound
    }
    
    
    /// Returns the NSRange-based character index just after the given character index by taking grapheme clusters into account.
    ///
    /// - Parameter location: The NSRange-based character index to reference.
    /// - Returns: The NSRange-based character index just after the given `location`, or `location` when `location` is the last index.
    final func index(after location: Int) -> Int {
        
        guard location < self.length - 1 else { return self.length }
        
        // avoid returning index between CRLF
        let index = location
        let isCRLF = (self.character(at: index) == 0xD && self.character(at: index + 1) == 0xA)
        
        return self.rangeOfComposedCharacterSequence(at: isCRLF ? index + 1 : index).upperBound
    }
    
    
    /// Finds and returns ranges of passed-in substring with the given range of receiver.
    ///
    /// - Parameters:
    ///   - searchString: The string for which to search.
    ///   - options: A mask specifying search options.
    ///   - searchRange: The range within the receiver for which to search for aString.
    /// - Returns: An array of ranges where `searchString` occurs within `searchRange`.
    final func ranges(of searchString: String, options: NSString.CompareOptions = .literal, range searchRange: NSRange? = nil) -> [NSRange] {
        
        let searchRange = searchRange ?? self.range
        var ranges: [NSRange] = []
        
        var location = searchRange.location
        while location != NSNotFound {
            let range = self.range(of: searchString, options: options, range: NSRange(location..<searchRange.upperBound))
            location = range.upperBound
            
            guard range.location != NSNotFound else { break }
            
            ranges.append(range)
        }
        
        return ranges
    }
    
    
    /// Returns the line range containing the given location.
    final func lineRange(at location: Int) -> NSRange {
        
        self.lineRange(for: NSRange(location: location, length: 0))
    }
    
    
    /// Returns the line content range containing the given location.
    final func lineContentsRange(at location: Int) -> NSRange {
        
        self.lineContentsRange(for: NSRange(location: location, length: 0))
    }
    
    
    /// Returns the line range excluding the final line-ending characters, if present.
    ///
    /// - Parameters:
    ///   - range: A range within the receiver.
    /// - Returns: The range of characters representing the line(s) containing the given range.
    final func lineContentsRange(for range: NSRange) -> NSRange {
        
        var start = 0
        var contentsEnd = 0
        unsafe self.getLineStart(&start, end: nil, contentsEnd: &contentsEnd, for: range)
        
        return NSRange(location: start, length: contentsEnd - start)
    }
    
    
    /// Returns the index of the first character of the line touched by the given index.
    ///
    /// - Parameters:
    ///   - index: The character index used to find the line start.
    /// - Returns: The character index of the nearest line start.
    final func lineStartIndex(at index: Int) -> Int {
        
        var start = 0
        unsafe self.getLineStart(&start, end: nil, contentsEnd: nil, for: NSRange(location: index, length: 0))
        
        return start
    }
    
    
    /// Returns the index of the last character before the line ending for the line touched by the given index.
    ///
    /// - Parameters:
    ///   - index: The character index used to find the line contents end.
    /// - Returns: The character index of the nearest line contents end.
    final func lineContentsEndIndex(at index: Int) -> Int {
        
        var contentsEnd = 0
        unsafe self.getLineStart(nil, end: nil, contentsEnd: &contentsEnd, for: NSRange(location: index, length: 0))
        
        return contentsEnd
    }
    
    
    /// Calculates the line-by-line ranges that include the given ranges.
    ///
    /// - Parameters:
    ///   - ranges: The ranges to include.
    ///   - includingLastEmptyLine: Whether the last empty line should be included; otherwise, the return value can be empty.
    /// - Returns: An array of ranges for each individual line.
    final func lineRanges(for ranges: [NSRange], includingLastEmptyLine: Bool = false) -> [NSRange] {
        
        guard !ranges.isEmpty else { return [] }
        
        if includingLastEmptyLine,
           ranges == [NSRange(location: self.length, length: 0)],
           self.length == 0 || self.character(at: self.length - 1).isNewline
        {
            return ranges
        }
        
        let scopes = ranges
            .map { self.lineRange(for: $0) }
            .merged
        var lineRanges: [NSRange] = []
        
        for scope in scopes {
            unsafe self.enumerateSubstrings(in: scope, options: [.byLines, .substringNotRequired]) { _, _, enclosingRange, _ in
                lineRanges.append(enclosingRange)
            }
        }
        
        return lineRanges
    }
    
    
    /// Fast way to count the number of lines at the given character index (1-based).
    ///
    /// Counting in this way is significantly faster than other ways such as `enumerateSubstrings(in:options:.byLines)`,
    /// `components(separatedBy: .newlines)`, or even just counting `\n` in `.utf16`. (2020-02, Swift 5.1)
    ///
    /// - Parameter location: The NSRange-based character index.
    /// - Returns: The number of lines (1-based).
    final func lineNumber(at location: Int) -> Int {
        
        assert(location == 0 || location <= self.length)
        
        guard self.length > 0, location > 0 else { return 1 }
        
        var count = 0
        var index = 0
        while index < location {
            unsafe self.getLineStart(nil, end: &index, contentsEnd: nil, for: NSRange(location: index, length: 0))
            count += 1
        }
        
        if self.character(at: location - 1).isNewline {
            count += 1
        }
        
        return count
    }
    
    
    /// Returns a safe range that avoids ending between a CRLF line ending pair.
    ///
    /// - Parameters:
    ///   - range: The original character range in UTF-16 code units.
    /// - Returns: A range adjusted to avoid splitting a CRLF line ending, or the original range if no adjustment is needed.
    final func safeEndingRange(for range: NSRange) -> NSRange {
        
        guard
            !range.isNotFound,
            range.upperBound < self.length,
            range.upperBound > 0,
            self.character(at: range.upperBound - 1) == 0xD,  // CR
            self.character(at: range.upperBound) == 0xA       // LF
        else { return range }

        return range.isEmpty
            ? NSRange(location: range.location - 1, length: 0)
            : NSRange(location: range.location, length: range.length - 1)
    }
    
    
    /// Finds the widest character range that contains the given `index` and does not contain any characters from the given set.
    ///
    /// - Parameters:
    ///   - set: The character set to end expanding range.
    ///   - index: The character index that must be contained in the result range. The `index` must lie within `range`.
    ///   - range: The range in which to search. The `range` must not exceed the bounds of the receiver.
    /// - Returns: The found character range.
    final func rangeOfCharacter(until set: CharacterSet, at index: Int, range: NSRange? = nil) -> NSRange {
        
        let range = range ?? self.range
        
        assert(range.contains(index))
        
        let lowerDelimiterRange = self.rangeOfCharacter(from: set, options: .backwards, range: NSRange(range.lowerBound..<index))
        let lowerBound = !lowerDelimiterRange.isNotFound ? lowerDelimiterRange.upperBound : range.lowerBound
        
        let upperDelimiterRange = self.rangeOfCharacter(from: set, range: NSRange(index..<range.upperBound))
        let upperBound = !upperDelimiterRange.isNotFound ? upperDelimiterRange.lowerBound : range.upperBound
        
        return NSRange(lowerBound..<upperBound)
    }
    
    
    /// Returns the lower bound of the composed character sequence by moving the bound toward the start by the given offset in composed character sequences.
    ///
    /// - Parameters:
    ///   - index: The reference character index in UTF-16.
    ///   - offset: The number of composed character sequences to move the index.
    /// - Returns: A character index in UTF-16.
    final func lowerBoundOfComposedCharacterSequence(_ index: Int, offsetBy offset: Int) -> Int {
        
        assert((0...self.length).contains(index))
        assert(offset >= 0)
        
        if index == self.length, offset == 0 { return index }
        
        var remainingCount = (index == self.length) ? offset : offset + 1
        var boundary = index
        
        let range = NSRange(..<min(index + 1, self.length))
        let options: EnumerationOptions = [.byComposedCharacterSequences, .substringNotRequired, .reverse]
        unsafe self.enumerateSubstrings(in: range, options: options) { _, range, _, stop in
            
            boundary = range.lowerBound
            remainingCount -= 1
            
            if remainingCount <= 0 {
                unsafe stop.pointee = true
            }
        }
        
        return boundary
    }
}


public extension unichar {
    
    /// A Boolean value indicating whether this character represents a newline.
    ///
    /// cf. <https://developer.apple.com/documentation/swift/character/3127014-isnewline>
    var isNewline: Bool {
        
        switch self {
            case 0x000A, 0x000B, 0x000C, 0x000D, 0x0085, 0x2028, 0x2029: true
            default: false
        }
    }
}
