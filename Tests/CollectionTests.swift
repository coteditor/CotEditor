//
//  CollectionTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2024 1024jp
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

import Testing
@testable import CotEditor

struct CollectionTests {
    
    @Test func appendUnique() {
        
        var array = [0, 1, 2, 3, 4]
        
        array.appendUnique(0, maximum: 5)
        #expect(array == [1, 2, 3, 4, 0])
        
        array.appendUnique(6, maximum: 5)
        #expect(array == [2, 3, 4, 0, 6])
        
        array.appendUnique(7, maximum: 6)
        #expect(array == [2, 3, 4, 0, 6, 7])
        
        array.appendUnique(6, maximum: 3)
        #expect(array == [0, 7, 6])
    }
    
    
    @Test func countPrefix() {
        
        #expect([1, 2, 0, -1, 3].countPrefix(while: { $0 > 0 }) == 2)
        #expect([0, 1, 2, 0, -1].countPrefix(while: { $0 > 0 }) == 0)
        #expect([1, 2, 3, 4, 5].countPrefix(while: { $0 > 0 }) == 5)
    }
    
    
    @Test func compareCount() {
        
        #expect("".compareCount(with: 0) == .equal)
        #expect("".compareCount(with: 1) == .less)
        
        #expect("a".compareCount(with: 1) == .equal)
        #expect("🐕".compareCount(with: 1) == .equal)
        #expect("🐕‍🦺".compareCount(with: 1) == .equal)
        
        #expect("🐶🐱".compareCount(with: 3) == .less)
        #expect("🐶🐱".compareCount(with: 2) == .equal)
        #expect("🐶🐱".compareCount(with: 1) == .greater)
    }
    
    
    @Test func mapKeys() {
        
        let dict = [1: 1, 2: 2, 3: 3]
        let mapped = dict.mapKeys { String($0 * 10) }
        
        #expect(mapped == ["10": 1, "20": 2, "30": 3])
    }
    
    
    @Test func rawRepresentable() {
        
        enum TestKey: String {
            case dog, cat, cow
        }
        var dict = ["dog": "🐶", "cat": "🐱"]
        
        #expect(dict[TestKey.dog] == dict[TestKey.dog.rawValue])
        #expect(dict[TestKey.cow] == nil)
        
        dict[TestKey.cow] = "🐮"
        #expect(dict[TestKey.cow] == "🐮")
    }
    
    
    @Test(arguments: 0..<10) func sort(index: Int) {
        
        var array: [Int] = (0..<10).map { _ in .random(in: 0..<100) }
        let sorted = array.sorted { $0 < $1 }
        
        #expect(array.sorted() == sorted)
        
        array.sort()
        #expect(array == sorted)
    }
    
    
    @Test(arguments: 0..<10) func binarySearch(index: Int) {
        
        let array = (0..<20).map { _ in Int.random(in: 0..<100) }.sorted()
        
        for _ in 0..<10 {
            let index = Int.random(in: 0..<100)
            #expect(array.binarySearchedFirstIndex(where: { $0 > index }) ==
                    array.firstIndex(where: { $0 > index }))
        }
    }
}
