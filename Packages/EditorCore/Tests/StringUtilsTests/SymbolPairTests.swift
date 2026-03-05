//
//  SymbolPairTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-08-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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

struct SymbolPairTests {
    
    @Test func findIndex() {
        
        let string = "if < foo < 🐕 > > else < >"
        let pair = SymbolPair("<", ">")
        
        #expect(string.indexOfSymbolPair(endIndex: string.index(14), pair: pair) == string.index(3))
        #expect(string.indexOfSymbolPair(beginIndex: string.index(4), pair: pair) == string.index(15))
        #expect(string.indexOfSymbolPair(endIndex: string.index(2), pair: pair) == nil)
        #expect(string.indexOfSymbolPair(beginIndex: string.index(2), pair: .ltgt) == nil)
        
        #expect(string.indexOfSymbolPair(endIndex: string.index(14), pair: pair, until: string.index(15)) == nil)
        #expect(string.indexOfSymbolPair(beginIndex: string.index(4), pair: pair, until: string.index(2)) == nil)
    }
    
    
    @Test func samePair() {
        
        let string = "if ' foo ' 🐕 ' ' else ' '"
        let pair = SymbolPair("'", "'")
        
        #expect(string.indexOfSymbolPair(endIndex: string.index(14), pair: pair) == string.index(13))
        #expect(string.indexOfSymbolPair(beginIndex: string.index(4), pair: pair) == string.index(9))
        #expect(string.indexOfSymbolPair(endIndex: string.index(2), pair: pair) == nil)
        #expect(string.indexOfSymbolPair(beginIndex: string.index(2), pair: pair) == string.index(3))
    }
    
    
    @Test func scan() {
        
        let string = "def { foo {} | { bar } } "
        let pairs = SymbolPair.braces
        
        #expect(string.rangeOfEnclosingSymbolPair(at: string.range(1..<2), candidates: pairs) == nil)
        #expect(string.rangeOfEnclosingSymbolPair(at: string.range(24..<24), candidates: pairs) == nil)
        
        #expect(string.rangeOfEnclosingSymbolPair(at: string.range(13..<14), candidates: pairs) == string.range(4..<24))  // = |
        
        #expect(string.rangeOfEnclosingSymbolPair(at: string.range(11..<11), candidates: pairs) == string.range(10..<12))  // = {}
    }
    
    
    @Test func scanWithEscape() {
        
        let pairs = SymbolPair.braces
        
        let string1 = #"foo (\() )"#
        #expect(string1.rangeOfEnclosingSymbolPair(at: string1.range(7..<7), candidates: pairs) == string1.range(4..<8))
        
        let string2 = #"foo (\\() )"#
        #expect(string2.rangeOfEnclosingSymbolPair(at: string2.range(8..<8), candidates: pairs) == string2.range(7..<9))
        
        let string3 = #"foo (\\\() )"#
        #expect(string3.rangeOfEnclosingSymbolPair(at: string3.range(9..<9), candidates: pairs) == string3.range(4..<10))
        
        let string4 = #"foo \(\) (bar)"#
        #expect(string4.rangeOfEnclosingSymbolPair(at: string4.range(10..<10), candidates: pairs) == string4.range(9..<14))
    }
    
    
    @Test func pairIndex() {
        
        let string = "()"
        let begin: SymbolPair.PairIndex = .begin(string.startIndex)
        let end: SymbolPair.PairIndex = .end(string.index(1))
        
        #expect(begin.index == string.startIndex)
        #expect(end.index == string.index(1))
    }
    
    
    @Test func rangeOfSymbolPair() {
        
        let string = "(a[b]c)"
        let index = string.index(0)
        let range = string.rangeOfSymbolPair(at: index, candidates: SymbolPair.braces)
        
        #expect(range == string.index(0)...string.index(6))
        
        let endIndex = string.index(6)
        let endRange = string.rangeOfSymbolPair(at: endIndex, candidates: SymbolPair.braces)
        
        #expect(endRange == string.index(0)...string.index(6))
    }
    
    
    @Test func rangeOfSymbolPairWithoutBackslashEscaping() {
        
        let string = #"foo \(bar\) baz"#
        let beginIndex = try! #require(string.firstIndex(of: "("))
        
        let defaultRange = string.rangeOfSymbolPair(at: beginIndex, candidates: SymbolPair.braces)
        let unescapedRange = string.rangeOfSymbolPair(at: beginIndex, candidates: SymbolPair.braces, escapeRule: .none)
        
        #expect(defaultRange == nil)
        #expect(unescapedRange == string.index(5)...string.index(10))
    }
    
    
    @Test func rangeOfSymbolPairWithDoubleDelimiterEscaping() {
        
        let string = "'a''b'"
        let quotes = SymbolPair.quotes
        
        let openingRange = string.rangeOfSymbolPair(at: string.index(0), candidates: quotes, escapeRule: .doubleDelimiter)
        let closingRange = string.rangeOfSymbolPair(at: string.index(5), candidates: quotes, escapeRule: .doubleDelimiter)
        let escapedRange = string.rangeOfSymbolPair(at: string.index(2), candidates: quotes, escapeRule: .doubleDelimiter)
        
        #expect(openingRange == string.index(0)...string.index(5))
        #expect(closingRange == string.index(0)...string.index(5))
        #expect(escapedRange == nil)
    }
    
    
    @Test func samePairBackslashVsNone() {
        
        let string = "'a\\'b' 'c'"
        let quotes = SymbolPair.quotes
        
        let backslashRange = string.rangeOfSymbolPair(at: string.index(0), candidates: quotes, escapeRule: .backslash)
        let noneRange = string.rangeOfSymbolPair(at: string.index(0), candidates: quotes, escapeRule: .none)
        
        #expect(backslashRange == string.index(0)...string.index(5))
        #expect(noneRange == string.index(0)...string.index(3))
    }
    
    
    @Test func ignorePair() {
        
        let string = "( [ ( ] )"
        let pair = SymbolPair("(", ")")
        let brackets = SymbolPair("[", "]")
        
        let endIndex = string.indexOfSymbolPair(beginIndex: string.index(0), pair: pair)
        let ignoredEndIndex = string.indexOfSymbolPair(beginIndex: string.index(0), pair: pair, ignoring: brackets)
        
        #expect(endIndex == nil)
        #expect(ignoredEndIndex == string.index(8))
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
