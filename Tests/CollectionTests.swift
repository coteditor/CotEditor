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
//  © 2017-2019 1024jp
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

class CollectionTests: XCTestCase {
    
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
    
}
