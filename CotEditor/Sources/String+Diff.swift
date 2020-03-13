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
//  © 2018-2020 1024jp
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
import DifferenceKit

extension StringProtocol {
    
    /// Calculate equivalent ranges in the receiver to the given ranges in the given string using DifferenceKit.
    ///
    /// - Parameters:
    ///   - ranges: The original ranges to be based on.
    ///   - string: The string to compare with the receiver.
    /// - Returns: The equivalent ranges to the given ranges.
    func equivalentRanges(to ranges: [NSRange], in other: Self) -> [NSRange] {
        
        // -> Use UTF16View instead of Character due to performance issue
        let diff = StagedChangeset(source: Array(other.utf16), target: Array(self.utf16))
        
        return ranges.map { NSRange(diff.move($0.lowerBound)..<diff.move($0.upperBound)) }
    }
    
}



// MARK: -

extension String.UTF16View.Element: Differentiable { }

private extension StagedChangeset {
    
    func move(_ index: Int) -> Int {
        
        let insertionCount = self.flatMap { $0.elementInserted }
            .countPrefix { $0.element < index }
        let removalCount = self.flatMap { $0.elementDeleted }
            .countPrefix { $0.element < index }
        
        return index + insertionCount - removalCount
    }
    
}
