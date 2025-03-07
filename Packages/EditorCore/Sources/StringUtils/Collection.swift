//
//  Collection.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-19.
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

// MARK: Unique

public extension Sequence where Element: Equatable {
    
    /// An array consists of unique elements of receiver by keeping ordering.
    var uniqued: [Element] {
        
        self.reduce(into: []) { (unique, element) in
            guard !unique.contains(element) else { return }
            
            unique.append(element)
        }
    }
}


public extension Array where Element: Equatable {
    
    /// Removes duplicated elements by keeping ordering.
    mutating func unique() {
        
        self = self.uniqued
    }
}


// MARK: Count

public enum QuantityComparisonResult {
    
    case less, equal, greater
}


public extension Sequence {
    
    /// Performance efficient way to compare the number of elements with the given number.
    ///
    /// - Note: This method takes advantage especially when counting elements is heavy (such as String count) and the number to compare is small.
    ///
    /// - Parameter number: The number of elements to test.
    /// - Returns: The result whether the number of the elements in the receiver is less than, equal, or more than the given number.
    func compareCount(with number: Int) -> QuantityComparisonResult {
        
        assert(number >= 0, "The count number to compare should be a natural number.")
        
        guard number >= 0 else { return .greater }
        
        var count = 0
        for _ in self {
            count += 1
            if count > number { return .greater }
        }
        
        return (count == number) ? .equal : .less
    }
}
