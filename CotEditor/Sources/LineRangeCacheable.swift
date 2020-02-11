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
}


extension LineRangeCacheable {
    
    // MARK: Public Methods
    
    /// The 1-based line number at the given character index.
    ///
    /// - Parameter index: The character index within the receiver.
    func lineNumber(at index: Int) -> Int {
        
        assert(index <= self.string.length)
        
        guard index > 0 else { return 1 }
        
        if index >= self.firstLineUncoundedIndex {
            self.parseLineNumber(upto: index)
        }
        
        return self.lineStartIndexes.count(in: ...index) + 1
    }
    
    
    /// Range of the line containing a given index.
    ///
    /// - Parameter index: The character index within the receiver.
    /// - Returns: The characer range of the line.
    func lineRange(at index: Int) -> NSRange {
        
        assert(index <= self.string.length)
        
        if index >= self.firstLineUncoundedIndex {
            self.parseLineNumber(upto: index)
        }
        
        let lowerBound = self.lineStartIndexes.integerLessThanOrEqualTo(index) ?? 0
        let upperBound = self.lineStartIndexes.integerGreaterThan(index) ?? self.string.length
        
        return NSRange(lowerBound..<upperBound)
    }
    
    
    /// Invalidate line number cache.
    ///
    /// This method must be invoked every time when the string is updated.
    ///
    /// - Parameter index: The first character index where modificated.
    func invalidateLineNumbers(from index: Int) {
        
        self.lineStartIndexes.remove(integersIn: index..<(Int.max))
        self.firstLineUncoundedIndex = self.lineStartIndexes.last ?? 0
    }
    
    
    // MARK: Private Methods
    
    /// Calculate line numbers upto the line that contains the given character index.
    ///
    /// - Parameter endIndex: The character index where needs the line number.
    private func parseLineNumber(upto endIndex: Int) {
        
        assert(!self.lineStartIndexes.contains(self.firstLineUncoundedIndex + 1))
        
        guard !self.string.isEmpty else { return }
        
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
