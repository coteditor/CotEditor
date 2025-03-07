//
//  String+LineRange.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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

public extension String {
    
    /// The first appeared line ending character.
    var firstLineEnding: Character? {
        
        self.firstMatch(of: /\R/)?.output.first
    }
}


public extension StringProtocol {
    
    /// Returns the range of the line containing a given index.
    ///
    /// - Parameter index: The character index within the receiver.
    /// - Returns: The character range of the line.
    func lineRange(at index: Index) -> Range<Index> {
        
        self.lineRange(for: index..<index)
    }
    
    
    /// Returns the range of the line containing a given index.
    ///
    /// - Parameter index: The character index within the receiver.
    /// - Returns: The character range of the line contents.
    func lineContentsRange(at index: Index) -> Range<Index> {
        
        self.lineContentsRange(for: index..<index)
    }
    
    
    /// Returns line range excluding last line ending character if exists.
    ///
    /// - Parameter range: A range within the receiver.
    /// - Returns: The range of characters representing the line or lines containing a given range.
    func lineContentsRange(for range: Range<Index>) -> Range<Index> {
        
        var start = self.startIndex
        var end = self.startIndex
        var contentsEnd = self.startIndex
        self.getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: range)
        
        return start..<contentsEnd
    }
    
    
    /// Returns the index of the first character of the line touched by the given index.
    ///
    /// - Note: Unlike NSString's one, this method does not have the performance advantage.
    ///
    /// - Parameters:
    ///   - index: The index of character for finding the line start.
    /// - Returns: The character index of the nearest line start.
    func lineStartIndex(at index: Index) -> Index {
        
        var start = self.startIndex
        var end = self.startIndex
        var contentsEnd = self.startIndex
        self.getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: index..<index)
        
        return start
    }
    
    
    /// Returns the index of the last character before the line ending of the line touched by the given index.
    ///
    /// - Note: Unlike NSString's one, this method does not have the performance advantage.
    ///
    /// - Parameters:
    ///   - index: The index of character for finding the line contents end.
    /// - Returns: The character index of the nearest line contents end.
    func lineContentsEndIndex(at index: Index) -> Index {
        
        var start = self.startIndex
        var end = self.startIndex
        var contentsEnd = self.startIndex
        self.getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: index..<index)
        
        return contentsEnd
    }
}


// MARK: NSRange based

public extension String {
    
    /// Divides the given range into logical line contents ranges.
    ///
    /// - Parameter range: The range to divide or `nil`.
    /// - Returns: Logical line ranges.
    func lineContentsRanges(for range: NSRange? = nil) -> [NSRange] {
        
        let range = range ?? NSRange(..<self.utf16.count)
        let regex = try! NSRegularExpression(pattern: "^.*", options: [.anchorsMatchLines])
        
        return regex.matches(in: self, range: range).map(\.range)
    }
}
