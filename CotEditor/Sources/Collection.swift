//
//  Collection.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-27.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

extension RangeReplaceableCollection where Element: Equatable {
    
    /// Remove first collection element that is equal to the given `element`.
    ///
    /// - Parameter element: The element to be removed.
    /// - Returns: The index of the removed element, or `nil` if not contains.
    @discardableResult
    mutating func removeFirst(_ element: Element) -> Index? {
        
        guard let index = self.firstIndex(of: element) else { return nil }
        
        self.remove(at: index)
        
        return index
    }
    
}



extension Collection {

    /// Return the element at the specified index only if it is within bounds, otherwise nil.
    ///
    /// - Parameter index: The position of the element to obtain.
    subscript(safe index: Index) -> Element? {
        
        return self.indices.contains(index) ? self[index] : nil
    }
    
    
    /// Split receiver into buffer sized chunks.
    ///
    /// - Parameter length: The buffer size to split.
    /// - Returns: Split subsequences.
    func components(length: Int) -> [SubSequence] {
        
        return stride(from: 0, to: self.count, by: length).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            
            return self[start..<end]
        }
    }
    
}



extension Sequence where Element: Equatable {
    
    /// An array consists of unique elements of receiver keeping ordering.
    var unique: [Element] {
        
        return self.reduce(into: []) { (unique, element) in
            guard !unique.contains(element) else { return }
            
            unique.append(element)
        }
    }
    
}



extension Dictionary {
    
    /// Return a new dictionary containing the keys transformed by the given closure with the values of this dictionary.
    ///
    /// - Parameter transform: A closure that transforms a key. Every transformed key must be unique.
    /// - Returns: A dictionary containing transformed keys and the values of this dictionary.
    func mapKeys<T>(transform: (Key) throws -> T) rethrows -> [T: Value] {
        
        let keysWithValues = try self.map { (key, value) -> (T, Value) in
             (try transform(key), value)
        }
        
        return [T: Value](uniqueKeysWithValues: keysWithValues)
    }
    
}



// MARK: - Sort

extension Sequence {
        
    /// Return the elements of the sequence, sorted using the value that the given key path refers as the comparison between elements.
    ///
    /// - Parameter keyPath: The key path to the value to compare.
    /// - Returns: A sorted array of the sequence’s elements.
    func sorted<Value: Comparable>(_ keyPath: KeyPath<Element, Value>) -> [Element] {
        
        return self.sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
    
}


extension MutableCollection where Self: RandomAccessCollection {
    
    /// Sort the collection in place, using the value that the given key path refers as the comparison between elements.
    ///
    /// - Parameter keyPath: The key path to the value to compare.
    mutating func sort<Value: Comparable>(_ keyPath: KeyPath<Element, Value>) {
        
        self.sort { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
    
}



// MARK: - Count

enum QuantityComparisonResult {
    
    case less, equal, greater
}


extension Sequence {
    
    /// Count up elements that satisfy the given predicate.
    ///
    /// - Parameters:
    ///    - predicate: A closure that takes an element of the sequence as its argument
    ///                 and returns a Boolean value indicating whether the element should be counted.
    /// - Returns: The number of elements that satisfies the given predicate.
    func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        
        return try self.reduce(0) { try predicate($1) ? $0 + 1 : $0 }
    }
    
    
    /// Count up elements by enumerating collection until a element shows up that doesn't satisfy the given predicate.
    ///
    /// - Parameters:
    ///    - predicate: A closure that takes an element of the sequence as its argument
    ///                 and returns a Boolean value indicating whether the element should be counted.
    /// - Returns: The number of elements that satisfies the given predicate and are sequentially from the first index.
    func countPrefix(while predicate: (Element) throws -> Bool) rethrows -> Int {
        
        return try self.lazy.prefix(while: predicate).count
    }
    
    
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
