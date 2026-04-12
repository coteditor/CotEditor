//
//  Collection+BinarySearch.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2026 1024jp
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

public extension RandomAccessCollection {
    
    /// Returns the start index of the partition of a collection that matches the given predicate.
    ///
    /// This method uses binary search to find the returned index.
    /// The collection must already be partitioned according to the predicate.
    /// That is, there should be an index `i` where for every element in
    /// `collection[..<i]` the predicate is `false`, and for every element in
    /// `collection[i...]` the predicate is `true`.
    ///
    /// When `range` is supplied, the same partitioning requirement applies within that range.
    /// If no element satisfies `predicate`, this method returns `endIndex`.
    ///
    /// - Parameters:
    ///   - range: The range to search in.
    ///   - predicate: A predicate that partitions the collection.
    /// - Returns: The index of the first element for which `predicate` returns `true`, or `endIndex`.
    func partitioningIndex<E: Error>(in range: Range<Index>? = nil, where predicate: (Element) throws(E) -> Bool) throws(E) -> Index {
        
        let range = range ?? self.startIndex..<self.endIndex
        
        assert(range.lowerBound >= self.startIndex)
        assert(range.upperBound <= self.endIndex)
        
        var lowerBound = range.lowerBound
        var upperBound = range.upperBound
        
        while lowerBound < upperBound {
            let middleIndex = self.index(lowerBound, offsetBy: self.distance(from: lowerBound, to: upperBound) / 2)
            
            if try predicate(self[middleIndex]) {
                upperBound = middleIndex
            } else {
                lowerBound = self.index(after: middleIndex)
            }
        }
        
        return lowerBound
    }
}
