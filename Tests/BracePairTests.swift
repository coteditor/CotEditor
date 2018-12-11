//
//  BracePairTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-08-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2018 1024jp
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

class BracePairTests: XCTestCase {
    
    func testIndexFind() {
        
        let string = "if < foo < 🐕 > > else < >"
        let pair = BracePair("<", ">")
        let start = string.startIndex
        
        XCTAssertEqual(string.indexOfBracePair(endIndex: string.index(start, offsetBy: 14), pair: pair), string.index(start, offsetBy: 3))
        XCTAssertEqual(string.indexOfBracePair(beginIndex: string.index(start, offsetBy: 4), pair: pair), string.index(start, offsetBy: 15))
        XCTAssertNil(string.indexOfBracePair(endIndex: string.index(start, offsetBy: 2), pair: pair))
        XCTAssertNil(string.indexOfBracePair(beginIndex: string.index(start, offsetBy: 2), pair: .ltgt))
    }
    
    
    func testSamePair() {
        
        let string = "if ' foo ' 🐕 ' ' else ' '"
        let pair = BracePair("'", "'")
        let start = string.startIndex
        
        XCTAssertEqual(string.indexOfBracePair(endIndex: string.index(start, offsetBy: 14), pair: pair), string.index(start, offsetBy: 13))
        XCTAssertEqual(string.indexOfBracePair(beginIndex: string.index(start, offsetBy: 4), pair: pair), string.index(start, offsetBy: 9))
        XCTAssertNil(string.indexOfBracePair(endIndex: string.index(start, offsetBy: 2), pair: pair))
        XCTAssertEqual(string.indexOfBracePair(beginIndex: string.index(start, offsetBy: 2), pair: pair), string.index(start, offsetBy: 3))
    }

}
