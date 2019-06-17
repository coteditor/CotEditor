//
//  Collection+Diff.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-08-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2019 1024jp
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
import Differ

extension String {
    
    /// Calculate equivalent ranges in the receiver to the given ranges in the given string using Differ.
    ///
    /// - Parameters:
    ///   - ranges: The original ranges to be based on.
    ///   - string: The string to compare with the receiver.
    /// - Returns: The equivalent ranges to the given ranges.
    func equivalentRanges(to ranges: [NSRange], in other: String) -> [NSRange] {
        
        // -> Use UTF16View instead of Character due to performance issue
        let diff = other.utf16.diff(self.utf16)
        
        return ranges.map { NSRange(diff.move($0.lowerBound)..<diff.move($0.upperBound)) }
    }
    
}



// MARK: -

private extension Diff {
    
    func move(_ index: Int) -> Int {
        
        return self
            .prefix { $0.offset < index }
            .reduce(into: index) {
                switch $1 {
                case .insert: $0 += 1
                case .delete: $0 -= 1
                }
            }
    }
    
}


private extension Diff.Element {
    
    var offset: Int {
        
        switch self {
        case .insert(let offset), .delete(let offset): return offset
        }
    }
    
}
