//
//  OrderedSet.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-03-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2018 1024jp
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

struct OrderedSet<Element: Hashable>: RandomAccessCollection, Hashable {
    
    typealias Index = Array<Element>.Index
    
    private var elements: [Element] = []
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init() { }
    
    
    init<S: Sequence>(_ elements: S) where S.Element == Element {
        
        self.append(contentsOf: elements)
    }
    
    
    
    // MARK: Collection Methods
    
    /// return the element at the specified position.
    subscript(_ index: Index) -> Element {
        
        return self.elements[index]
    }
    
    
    var startIndex: Index {
        
        return self.elements.startIndex
    }
    
    
    var endIndex: Index {
        
        return self.elements.endIndex
    }
    
    
    func index(after index: Index) -> Index {
        
        return self.elements.index(after: index)
    }
    
    
    
    // MARK: Methods
    
    var array: [Element] {
        
        return self.elements
    }
    
    
    var set: Set<Element> {
        
        return Set(self.elements)
    }
    
    
    /// return a new set with the elements that are common to both this set and the given sequence.
    func intersection<S: Sequence>(_ other: S) -> OrderedSet<Element> where S.Element == Element {
        
        return OrderedSet(self.elements.filter { other.contains($0) })
    }
    
    
    
    // MARK: Mutating Methods
    
    /// insert the given element in the set if it is not already present.
    mutating func append(_ element: Element) {
        
        guard !self.elements.contains(element) else { return }
        
        self.elements.append(element)
    }
    
    
    /// insert the given elements in the set only which it is not already present.
    mutating func append<S: Sequence>(contentsOf elements: S) where S.Element == Element {
        
        for element in elements {
            self.append(element)
        }
    }
    
    
    /// insert the given element at the desired position.
    mutating func insert(_ element: Element, at index: Index) {
        
        guard !self.elements.contains(element) else { return }
        
        self.elements.insert(element, at: index)
    }
    
    
    /// remove the elements of the set that aren’t also in the given sequence.
    mutating func formIntersection<S: Sequence>(_ other: S) where S.Element == Element {
        
        self.elements.removeAll { !other.contains($0) }
    }
    
    
    /// remove the the element at the position from the set.
    mutating func remove(at index: Index) {
        
        self.elements.remove(at: index)
    }
    
    
    /// remove the specified element from the set.
    mutating func remove(_ element: Element) {
        
        guard let index = self.index(of: element) else { return }
        
        self.remove(at: index)
    }
    
}
