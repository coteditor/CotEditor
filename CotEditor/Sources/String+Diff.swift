//
//  String+Diff.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-08-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2022 1024jp
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

import struct Foundation.NSRange

extension StringProtocol {
    
    /// Calculate equivalent ranges in the receiver to the given ranges in the given string using DifferenceKit.
    ///
    /// - Parameters:
    ///   - ranges: The original ranges to be based on.
    ///   - string: The string to compare with the receiver.
    /// - Returns: The equivalent ranges to the given ranges.
    func equivalentRanges(to ranges: [NSRange], in other: Self) -> [NSRange] {
        
        // -> Use UTF16View instead of Character due to a performance issue.
        let diff = self.utf16.difference(from: other.utf16)
        
        guard !diff.isEmpty else { return ranges }
        
        return ranges
            .map { (diff.move($0.lowerBound), diff.move($0.upperBound)) }
            .filter { $0 <= $1 }
            .map { NSRange($0..<$1) }
    }
}



// MARK: -

private extension CollectionDifference {
    
    func move(_ index: Int) -> Int {
        
        let insertionCount = self.insertions.countPrefix { $0.offset < index }
        let removalCount = self.removals.countPrefix { $0.offset < index }
        
        return index + insertionCount - removalCount
    }
}


private extension CollectionDifference.Change {
    
    var offset: Int {
        
        switch self {
            case .insert(let offset, _, _), .remove(let offset, _, _):
                return offset
        }
    }
}
