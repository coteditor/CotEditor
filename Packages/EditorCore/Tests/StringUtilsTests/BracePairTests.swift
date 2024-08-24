//
//  BracePairTests.swift
//  StringUtilsTests
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

import Testing
@testable import StringUtils

struct BracePairTests {
    
    @Test func findIndex() {
        
        let string = "if < foo < 🐕 > > else < >"
        let pair = BracePair("<", ">")
        
        #expect(string.indexOfBracePair(endIndex: string.index(14), pair: pair) == string.index(3))
        #expect(string.indexOfBracePair(beginIndex: string.index(4), pair: pair) == string.index(15))
        #expect(string.indexOfBracePair(endIndex: string.index(2), pair: pair) == nil)
        #expect(string.indexOfBracePair(beginIndex: string.index(2), pair: .ltgt) == nil)
        
        #expect(string.indexOfBracePair(endIndex: string.index(14), pair: pair, until: string.index(15)) == nil)
        #expect(string.indexOfBracePair(beginIndex: string.index(4), pair: pair, until: string.index(2)) == nil)
    }
    
    
    @Test func samePair() {
        
        let string = "if ' foo ' 🐕 ' ' else ' '"
        let pair = BracePair("'", "'")
        
        #expect(string.indexOfBracePair(endIndex: string.index(14), pair: pair) == string.index(13))
        #expect(string.indexOfBracePair(beginIndex: string.index(4), pair: pair) == string.index(9))
        #expect(string.indexOfBracePair(endIndex: string.index(2), pair: pair) == nil)
        #expect(string.indexOfBracePair(beginIndex: string.index(2), pair: pair) == string.index(3))
    }
    
    
    @Test func scan() {
        
        let string = "def { foo {} | { bar } } "
        let pairs = BracePair.braces
        
        #expect(string.rangeOfEnclosingBracePair(at: string.range(1..<2), candidates: pairs) == nil)
        #expect(string.rangeOfEnclosingBracePair(at: string.range(24..<24), candidates: pairs) == nil)
        
        #expect(string.rangeOfEnclosingBracePair(at: string.range(13..<14), candidates: pairs) == string.range(4..<24))  // = |
        
        #expect(string.rangeOfEnclosingBracePair(at: string.range(11..<11), candidates: pairs) == string.range(10..<12))  // = {}
    }
    
    
    @Test func scanWithEscape() {
        
        let pairs = BracePair.braces
        
        let string1 = #"foo (\() )"#
        #expect(string1.rangeOfEnclosingBracePair(at: string1.range(7..<7), candidates: pairs) == string1.range(4..<8))
        
        let string2 = #"foo (\\() )"#
        #expect(string2.rangeOfEnclosingBracePair(at: string2.range(8..<8), candidates: pairs) == string2.range(7..<9))
        
        let string3 = #"foo (\\\() )"#
        #expect(string3.rangeOfEnclosingBracePair(at: string3.range(9..<9), candidates: pairs) == string3.range(4..<10))
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
