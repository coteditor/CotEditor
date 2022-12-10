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
//  © 2016-2022 1024jp
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

final class BracePairTests: XCTestCase {
    
    func testIndexFind() {
        
        let string = "if < foo < 🐕 > > else < >"
        let pair = BracePair("<", ">")
        
        XCTAssertEqual(string.indexOfBracePair(endIndex: string.index(14), pair: pair), string.index(3))
        XCTAssertEqual(string.indexOfBracePair(beginIndex: string.index(4), pair: pair), string.index(15))
        XCTAssertNil(string.indexOfBracePair(endIndex: string.index(2), pair: pair))
        XCTAssertNil(string.indexOfBracePair(beginIndex: string.index(2), pair: .ltgt))
        
        XCTAssertNil(string.indexOfBracePair(endIndex: string.index(14), pair: pair, until: string.index(15)))
        XCTAssertNil(string.indexOfBracePair(beginIndex: string.index(4), pair: pair, until: string.index(2)))
    }
    
    
    func testSamePair() {
        
        let string = "if ' foo ' 🐕 ' ' else ' '"
        let pair = BracePair("'", "'")
        
        XCTAssertEqual(string.indexOfBracePair(endIndex: string.index(14), pair: pair), string.index(13))
        XCTAssertEqual(string.indexOfBracePair(beginIndex: string.index(4), pair: pair), string.index(9))
        XCTAssertNil(string.indexOfBracePair(endIndex: string.index(2), pair: pair))
        XCTAssertEqual(string.indexOfBracePair(beginIndex: string.index(2), pair: pair), string.index(3))
    }
    
}


private extension String {
    
    func index(_ index: Int) -> Index {
        
        self.index(self.startIndex, offsetBy: index)
    }
    
}
