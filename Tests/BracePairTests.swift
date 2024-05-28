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
//  © 2016-2024 1024jp
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
    
    
    func testScanner() {
        
        let string = "def { foo {} | { bar } } "
        let pairs = BracePair.braces
        
        XCTAssertNil(string.rangeOfEnclosingBracePair(at: string.range(1..<2), candidates: pairs))
        XCTAssertNil(string.rangeOfEnclosingBracePair(at: string.range(24..<24), candidates: pairs))
        
        XCTAssertEqual(string.rangeOfEnclosingBracePair(at: string.range(13..<14), candidates: pairs),  // = |
                       string.range(4..<24))
        
        XCTAssertEqual(string.rangeOfEnclosingBracePair(at: string.range(11..<11), candidates: pairs),  // = {}
                       string.range(10..<12))
    }
    
    
    func testScannerWithEscape() {
        
        let pairs = BracePair.braces
        
        let string1 = #"foo (\() )"#
        XCTAssertEqual(string1.rangeOfEnclosingBracePair(at: string1.range(7..<7), candidates: pairs),
                       string1.range(4..<8))
        
        let string2 = #"foo (\\() )"#
        XCTAssertEqual(string2.rangeOfEnclosingBracePair(at: string2.range(8..<8), candidates: pairs),
                       string2.range(7..<9))
        
        let string3 = #"foo (\\\() )"#
        XCTAssertEqual(string3.rangeOfEnclosingBracePair(at: string3.range(9..<9), candidates: pairs),
                       string3.range(4..<10))
    }
}


private extension String {
    
    func index(_ index: Int) -> Index {
        
        self.index(self.startIndex, offsetBy: index)
    }
    
    
    func range(_ range: Range<Int>) -> Range<Index> {
        
        self.index(range.lowerBound)..<self.index(range.upperBound)
    }
}
