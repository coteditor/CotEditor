//
//  StringCollectionTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-19.
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

class StringCollectionTests: XCTestCase {
    
    func testAvailableNameCreation() {
        
        let names = ["foo", "foo 3", "foo copy 3", "foo 4", "foo 7"]
        let copy = "copy"
        
        XCTAssertEqual(names.createAvailableName(for: "foo"), "foo 2")
        XCTAssertEqual(names.createAvailableName(for: "foo 3"), "foo 5")
        
        XCTAssertEqual(names.createAvailableName(for: "foo", suffix: copy), "foo copy")
        XCTAssertEqual(names.createAvailableName(for: "foo 3", suffix: copy), "foo 3 copy")
        XCTAssertEqual(names.createAvailableName(for: "foo copy 3", suffix: copy), "foo copy 4")
    }
    
    
    func testRangeDiff() {
        
        let string1 = "family 👨‍👨‍👦 with 🐕"
        let string2 = "family 👨‍👨‍👦 and 🐕"
        
        XCTAssertEqual(string2.equivalentRanges(to: [NSRange(7..<15)], in: string1), [NSRange(7..<15)])  //  👨‍👨‍👦
        XCTAssertEqual(string2.equivalentRanges(to: [NSRange(16..<20)], in: string1), [NSRange(16..<19)])  // with
        XCTAssertEqual(string2.equivalentRanges(to: [NSRange(16..<18)], in: string1), [NSRange(16..<16)])  // wi
        XCTAssertEqual(string2.equivalentRanges(to: [NSRange(21..<23)], in: string1), [NSRange(20..<22)])  // 🐕
        XCTAssertEqual("".equivalentRanges(to: [NSRange(16..<20)], in: string1), [NSRange(0..<0)])  // with
        
        XCTAssertEqual(string1.equivalentRanges(to: [NSRange(0..<0)], in: string2), [NSRange(0..<0)])
        XCTAssertEqual(string1.equivalentRanges(to: [NSRange(16..<19)], in: string2), [NSRange(16..<19)])  // and
        XCTAssertEqual(string1.equivalentRanges(to: [NSRange(16..<20)], in: string2), [NSRange(16..<21)])  // and_
    }
    
}
