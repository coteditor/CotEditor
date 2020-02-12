//
//  LineRangeCacheable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

protocol LineRangeCacheable: AnyObject {
    
    var string: String { get }
    var lineStartIndexes: IndexSet { get set }
    var firstLineUncoundedIndex: Int { get set }
    
    // This method must be invoked every time when the receiver's `.string` is updated.
    func invalidateLineRanges(from index: Int)
}


extension LineRangeCacheable {
    
    // MARK: Public Methods
    
    /// Return the 1-based line number at the given character index.
    ///
    /// - Parameter index: The character index.
    /// - Returns: The 1-based line number.
    func lineNumber(at index: Int) -> Int {
        
        assert(index <= self.string.length)
        
        self.ensureLineRanges(upTo: index)
        
        return self.lineStartIndexes.count(in: ...index) + 1
    }
    
    
    /// Return the range of the line touched by the given index.
    ///
    /// Because this method count up all the line ranges up to the given index when not cached yet,
    /// there is a large perormance disadbantage when just a single line range is needed.
    ///
    /// - Parameter index: The character index.
    /// - Returns: The characer range of the line.
    func lineRange(at index: Int) -> NSRange {
        
        assert(index <= self.string.length)
        
        self.ensureLineRanges(upTo: index)
        
        let lowerBound = self.lineStartIndexes.integerLessThanOrEqualTo(index) ?? 0
        let upperBound = self.lineStartIndexes.integerGreaterThan(index) ?? self.string.length
        
        return NSRange(location: lowerBound, length: upperBound - lowerBound)
    }
    
    
    /// Return the index of the first character of the line touched by the given index.
    ///
    /// Because this method count up all the line ranges up to the given index when not cached yet,
    /// there is a large perormance disadbantage when just a single line start index is needed.
    ///
    /// - Parameters:
    ///   - index: The index of character for finding the line start.
    /// - Returns: The character index of the nearest line start.
    func lineStartIndex(at index: Int) -> Int {
        
        assert(index <= self.string.length)
        
        self.ensureLineRanges(upTo: index)
        
        return self.lineStartIndexes.integerLessThanOrEqualTo(index) ?? 0
    }
    
    
    /// Invalidate the line range cache.
    ///
    /// This method must be invoked every time when the receiver's `.string` is updated.
    ///
    /// - Parameter index: The first character index where modificated.
    func invalidateLineRanges(from index: Int) {
        
        self.lineStartIndexes.remove(integersIn: (index + 1)..<Int.max)
        self.firstLineUncoundedIndex = self.lineStartIndexes.last ?? 0
    }
    
    
    // MARK: Private Methods
    
    /// Calculate and cache line ranges up to the line that contains the given character index, if it has not already done so.
    ///
    /// - Parameter endIndex: The character index where needs the line number.
    private func ensureLineRanges(upTo endIndex: Int) {
        
        assert(endIndex <= self.string.length)
        assert(!self.lineStartIndexes.contains(self.firstLineUncoundedIndex + 1))
        
        guard
            endIndex >= self.firstLineUncoundedIndex,
            !self.string.isEmpty
            else { return }
        
        let string = self.string as NSString
        
        var index = self.firstLineUncoundedIndex
        while index <= min(endIndex, string.length - 1) {
            string.getLineStart(nil, end: &index, contentsEnd: nil, for: NSRange(location: index, length: 0))
            
            guard index != string.length || string.character(at: index - 1).isNewline else { break }
            
            self.lineStartIndexes.insert(index)
        }
        self.firstLineUncoundedIndex = index
    }
    
}
