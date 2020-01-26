//
//  FuzzyRangeTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-01-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

final class FuzzyRangeTests: XCTestCase {
    
    func testFuzzyCharacterRange() {
        
        let string = "0123456789"
        
        XCTAssertEqual(string.range(in: FuzzyRange(location: 2, length: 2)), NSRange(location: 2, length: 2))
        XCTAssertEqual(string.range(in: FuzzyRange(location: -1, length: 1)), NSRange(location: 9, length: 1))
        XCTAssertEqual(string.range(in: FuzzyRange(location: 3, length: -1)), NSRange(3..<9))
        XCTAssertEqual(string.range(in: FuzzyRange(location: 3, length: -2)), NSRange(location: 3, length: "45678".utf16.count))
    }
        
        
    func testFuzzyLineRange() {
        
        let string = "1\r\n2\r\n3\r\n4"  // 1 based
        var range: NSRange
        
        range = string.rangeForLine(in: FuzzyRange(location: 1, length: 2))!
        XCTAssertEqual((string as NSString).substring(with: range), "1\r\n2\r\n")
        
        range = string.rangeForLine(in: FuzzyRange(location: 4, length: 1))!
        XCTAssertEqual((string as NSString).substring(with: range), "4")
        
        range = string.rangeForLine(in: FuzzyRange(location: 3, length: 0))!
        XCTAssertEqual((string as NSString).substring(with: range), "3\r\n")

        range = string.rangeForLine(in: FuzzyRange(location: -1, length: 1))!
        XCTAssertEqual((string as NSString).substring(with: range), "4")

        range = string.rangeForLine(in: FuzzyRange(location: -2, length: 1))!
        XCTAssertEqual((string as NSString).substring(with: range), "3\r\n")

        range = string.rangeForLine(in: FuzzyRange(location: 2, length: -2))!
        XCTAssertEqual((string as NSString).substring(with: range), "2\r\n")
    }
    
    
    func testFuzzyRangeString() {
        
        XCTAssertEqual(FuzzyRange(location: 0, length: 0).string, "0")
        XCTAssertEqual(FuzzyRange(location: 1, length: 0).string, "1")
        XCTAssertEqual(FuzzyRange(location: 1, length: 1).string, "1")
        XCTAssertEqual(FuzzyRange(location: 1, length: 2).string, "1:2")
        XCTAssertEqual(FuzzyRange(location: -1, length: 0).string, "-1")
        XCTAssertEqual(FuzzyRange(location: -1, length: -1).string, "-1:-1")
        
        XCTAssertEqual(FuzzyRange(string: "0")!, FuzzyRange(location: 0, length: 0))
        XCTAssertEqual(FuzzyRange(string: "1")!, FuzzyRange(location: 1, length: 0))
        XCTAssertEqual(FuzzyRange(string: "1:2")!, FuzzyRange(location: 1, length: 2))
        XCTAssertEqual(FuzzyRange(string: "-1")!, FuzzyRange(location: -1, length: 0))
        XCTAssertEqual(FuzzyRange(string: "-1:-1")!, FuzzyRange(location: -1, length: -1))
        XCTAssertNil(FuzzyRange(string: ""))
        XCTAssertNil(FuzzyRange(string: "abc"))
        XCTAssertNil(FuzzyRange(string: "1:a"))
        XCTAssertNil(FuzzyRange(string: "1:1:1"))
    }

}
