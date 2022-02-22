//
//  OrderedCounterTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-02-22.
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

import XCTest
@testable import CotEditor

final class OrderedCounterTests: XCTestCase {
    
    func testOrderedCounter() throws {
        
        var counter = OrderedCounter<Int>()
        
        XCTAssertNil(counter.firstMaxElement)
        XCTAssertEqual(counter.count(0), 0)
        XCTAssertTrue(counter.isEmpty)
        XCTAssertEqual(counter.count, 0)
        
        counter.append(1)
        
        XCTAssertEqual(counter.firstMaxElement, 1)
        XCTAssertEqual(counter.count(0), 0)
        XCTAssertEqual(counter.count(1), 1)
        XCTAssertFalse(counter.isEmpty)
        XCTAssertEqual(counter.count, 1)
        
        counter.append(2)
        counter.append(2)
        counter.append(3)
        counter.append(0)
        counter.append(0)
        
        XCTAssertEqual(counter.firstMaxElement, 2)
        XCTAssertEqual(counter.count(0), 2)
        XCTAssertEqual(counter.count(1), 1)
        XCTAssertEqual(counter.count(2), 2)
        XCTAssertEqual(counter.count(3), 1)
        XCTAssertFalse(counter.isEmpty)
        XCTAssertEqual(counter.count, 6)
    }
    
}
