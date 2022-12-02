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
//  © 2017-2022 1024jp
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

import XCTest
@testable import CotEditor

final class CollectionTests: XCTestCase {
    
    func testAppendUnique() {
        
        var array = [0, 1, 2, 3, 4]
        
        array.appendUnique(0, maximum: 5)
        XCTAssertEqual(array, [1, 2, 3, 4, 0])
        
        array.appendUnique(6, maximum: 5)
        XCTAssertEqual(array, [2, 3, 4, 0, 6])
        
        array.appendUnique(7, maximum: 6)
        XCTAssertEqual(array, [2, 3, 4, 0, 6, 7])
        
        array.appendUnique(6, maximum: 3)
        XCTAssertEqual(array, [0, 7, 6])
    }
    
    
    func testCount() {
        
        XCTAssertEqual([1, 2, 0, -1, 3].count(where: { $0 > 0 }), 3)
        XCTAssertEqual([0, 1, 2, 0, -1].count(where: { $0 > 0 }), 2)
        XCTAssertEqual([1, 2, 3, 4, 5].count(where: { $0 > 0 }), 5)
        
        XCTAssertEqual([1, 2, 0, -1, 3].countPrefix(while: { $0 > 0 }), 2)
        XCTAssertEqual([0, 1, 2, 0, -1].countPrefix(while: { $0 > 0 }), 0)
        XCTAssertEqual([1, 2, 3, 4, 5].countPrefix(while: { $0 > 0 }), 5)
    }
    
    
    func testCountComparison() {
        
        XCTAssertEqual("".compareCount(with: 0), .equal)
        XCTAssertEqual("".compareCount(with: 1), .less)
        
        XCTAssertEqual("a".compareCount(with: 1), .equal)
        XCTAssertEqual("🐕".compareCount(with: 1), .equal)
        XCTAssertEqual("🐕‍🦺".compareCount(with: 1), .equal)
        
        XCTAssertEqual("🐶🐱".compareCount(with: 3), .less)
        XCTAssertEqual("🐶🐱".compareCount(with: 2), .equal)
        XCTAssertEqual("🐶🐱".compareCount(with: 1), .greater)
    }
    
    
    func testKeyMapping() {
        
        let dict = [1: 1, 2: 2, 3: 3]
        let mapped = dict.mapKeys { String($0 * 10) }
        
        XCTAssertEqual(mapped, ["10": 1, "20": 2, "30": 3])
    }
    
    
    func testRawRepresentable() {
        
        enum TestKey: String {
            case dog, cat, cow
        }
        var dict = ["dog": "🐶", "cat": "🐱"]
        
        XCTAssertEqual(dict[TestKey.dog], dict[TestKey.dog.rawValue])
        XCTAssertNil(dict[TestKey.cow])
        
        dict[TestKey.cow] = "🐮"
        XCTAssertEqual(dict[TestKey.cow], "🐮")
    }
    
    
    func testSorting() {
        
        for _ in 0..<10 {
            var array: [Int] = (0..<10).map { _ in .random(in: 0..<100) }
            let sorted = array.sorted { $0 < $1 }
            
            XCTAssertEqual(array.sorted(), sorted)
            
            array.sort()
            XCTAssertEqual(array, sorted)
        }
    }
    
    
    func testBinarySearch() {
        
        for _ in 0..<10 {
            let array = (0..<20).map { _ in Int.random(in: 0..<100) }.sorted()
            
            for _ in 0..<10 {
                let index = Int.random(in: 0..<100)
                XCTAssertEqual(array.binarySearchedFirstIndex(where: { $0 > index }),
                               array.firstIndex(where: { $0 > index }))
            }
        }
    }
    
}
