//
//  Collection+BinarySearch.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

extension Collection {
    
    /// Find the index of the element first greater than or equal to the compared value by binary search.
    ///
    /// - Parameters:
    ///   - range: The range to find in.
    ///   - predicate: A closure that takes an element as its argument and returns a Boolean value that indicates whether the passed element represents a match.
    /// - Returns: The index.
    func binarySearchedFirstIndex(in range: Range<Index>? = nil, where predicate: (Element) throws -> Bool) rethrows -> Index? {
        
        let range = range ?? self.startIndex..<self.endIndex
        
        assert(range.lowerBound >= self.startIndex)
        assert(range.upperBound <= self.endIndex)
        
        guard !range.isEmpty else { return range.upperBound < self.endIndex ? range.upperBound : nil }
        
        let middleIndex = self.index(range.lowerBound, offsetBy: self.distance(from: range.lowerBound, to: range.upperBound) / 2)
        let middleValue = self[middleIndex]
        
        let nextRange = try predicate(middleValue)
            ? range.lowerBound..<middleIndex
            : self.index(after: middleIndex)..<range.upperBound
        
        return try self.binarySearchedFirstIndex(in: nextRange, where: predicate)
    }
}
