//
//  KeySortable.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-14.
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

import Foundation

protocol KeySortable {
    
    func compare(with other: Self, key: String) -> ComparisonResult
}



extension MutableCollection where Self: RandomAccessCollection, Element: KeySortable {
    
    /// Sort the receiver using NSSortDescriptor.
    ///
    /// - Parameter descriptors: The description how to sort.
    mutating func sort(using descriptors: [NSSortDescriptor]) {
        
        guard !descriptors.isEmpty, self.compareCount(with: 1) == .greater else { return }
        
        self.sort {
            for descriptor in descriptors {
                guard let identifier = descriptor.key else { continue }
                
                switch $0.compare(with: $1, key: identifier) {
                    case .orderedAscending: return descriptor.ascending
                    case .orderedDescending: return !descriptor.ascending
                    case .orderedSame: continue
                }
            }
            
            return false
        }
    }
    
}


extension Sequence where Element: KeySortable {
    
    /// Return the sorted elements of the receiver by sorting using NSSortDescriptor.
    ///
    /// - Parameter descriptors: The description how to sort.
    /// - Returns: The sorted result.
    func sorted(using descriptors: [NSSortDescriptor]) -> [Element] {
        
        guard !descriptors.isEmpty, self.compareCount(with: 1) == .greater else { return Array(self) }
        
        return self.sorted {
            for descriptor in descriptors {
                guard let identifier = descriptor.key else { continue }
                
                switch $0.compare(with: $1, key: identifier) {
                    case .orderedAscending: return descriptor.ascending
                    case .orderedDescending: return !descriptor.ascending
                    case .orderedSame: continue
                }
            }
            
            return false
        }
    }
    
}


extension Comparable {
    
    /// Compare the receiver with the given value.
    ///
    /// - Parameter other: The value to compare with.
    /// - Returns: The result of comparison.
    func compare(_ other: Self) -> ComparisonResult {
        
        if self > other {
            return .orderedAscending
        } else if self < other {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
    
}
