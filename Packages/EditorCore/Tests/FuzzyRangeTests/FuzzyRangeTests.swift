//
//  FuzzyRangeTests.swift
//  FuzzyRangeTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-01-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2024 1024jp
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

import Foundation
import Testing
@testable import FuzzyRange

struct FuzzyRangeTests {
    
    @Test func fuzzyCharacterRange() {
        
        let string = "0123456789"
        
        #expect(string.range(in: FuzzyRange(location: 2, length: 2)) == NSRange(location: 2, length: 2))
        #expect(string.range(in: FuzzyRange(location: -1, length: 0)) == NSRange(location: 10, length: 0))
        #expect(string.range(in: FuzzyRange(location: -2, length: 1)) == NSRange(location: 9, length: 1))
        #expect(string.range(in: FuzzyRange(location: 3, length: -1)) == NSRange(3..<9))
        #expect(string.range(in: FuzzyRange(location: 3, length: -2)) == NSRange(location: 3, length: "45678".utf16.count))
        
        // grapheme cluster count
        #expect("black 🐈‍⬛ cat".range(in: FuzzyRange(location: 6, length: 2)) == NSRange(location: 6, length: 5))
    }
    
    
    @Test func fuzzyLineRange() throws {
        
        let string = "1\r\n2\r\n3\r\n4"  // 1 based
        var range: NSRange
        
        range = try #require(string.rangeForLine(in: FuzzyRange(location: 1, length: 2)))
        #expect((string as NSString).substring(with: range) == "1\r\n2\r\n")
        
        range = try #require(string.rangeForLine(in: FuzzyRange(location: 4, length: 1)))
        #expect((string as NSString).substring(with: range) == "4")
        
        range = try #require(string.rangeForLine(in: FuzzyRange(location: 3, length: 0)))
        #expect((string as NSString).substring(with: range) == "3\r\n")
        
        range = try #require(string.rangeForLine(in: FuzzyRange(location: -1, length: 1)))
        #expect((string as NSString).substring(with: range) == "4")
        
        range = try #require(string.rangeForLine(in: FuzzyRange(location: -2, length: 1)))
        #expect((string as NSString).substring(with: range) == "3\r\n")
        
        range = try #require(string.rangeForLine(in: FuzzyRange(location: 2, length: -2)))
        #expect((string as NSString).substring(with: range) == "2\r\n")
        
        range = try #require("1\n".rangeForLine(in: FuzzyRange(location: -1, length: 0)))
        #expect(range == NSRange(location: 2, length: 0))
        
        range = try #require(string.rangeForLine(in: FuzzyRange(location: 1, length: 2), includingLineEnding: false))
        #expect((string as NSString).substring(with: range) == "1\r\n2")
    }
    
    
    @Test func formatFuzzyRange() {
        
        #expect(FuzzyRange(location: 0, length: 0).formatted() == "0")
        #expect(FuzzyRange(location: 1, length: 0).formatted() == "1")
        #expect(FuzzyRange(location: 1, length: 1).formatted() == "1")
        #expect(FuzzyRange(location: 1, length: 2).formatted() == "1:2")
        #expect(FuzzyRange(location: -1, length: 0).formatted() == "-1")
        #expect(FuzzyRange(location: -1, length: -1).formatted() == "-1:-1")
    }
    
    
    @Test func parseFuzzyRange() throws {
        
        let parser = FuzzyRangeParseStrategy()
        
        #expect(try parser.parse("0") == FuzzyRange(location: 0, length: 0))
        #expect(try parser.parse("1") == FuzzyRange(location: 1, length: 0))
        #expect(try parser.parse("1:2") == FuzzyRange(location: 1, length: 2))
        #expect(try parser.parse("-1") == FuzzyRange(location: -1, length: 0))
        #expect(try parser.parse("-1:-1") == FuzzyRange(location: -1, length: -1))
        
        #expect(throws: FuzzyRangeParseStrategy.ParseError.invalidValue) { try parser.parse("") }
        #expect(throws: FuzzyRangeParseStrategy.ParseError.invalidValue) { try parser.parse("abc") }
        #expect(throws: FuzzyRangeParseStrategy.ParseError.invalidValue) { try parser.parse("1:a") }
        #expect(throws: FuzzyRangeParseStrategy.ParseError.invalidValue) { try parser.parse("1:1:1") }
    }
    
    
    @Test func fuzzyLocation() throws {
        
        let string = "1\r\n2\r\n3\r\n456\n567"  // 1 based
        
        #expect(try string.fuzzyLocation(line: 0) == 0)
        #expect(try string.fuzzyLocation(line: 0, column: 1) == 1)
        
        #expect(try string.fuzzyLocation(line: 1) == 0)
        #expect(try string.fuzzyLocation(line: 2) == 3)
        #expect(try string.fuzzyLocation(line: 4) == 9)
        #expect(try string.fuzzyLocation(line: 5) == 13)
        #expect(try string.fuzzyLocation(line: -1) == 13)
        #expect(try string.fuzzyLocation(line: -2) == 9)
        #expect(try string.fuzzyLocation(line: -5) == 0)
        #expect(throws: FuzzyLocationError.invalidLine(-6)) { try string.fuzzyLocation(line: -6) }
        
        // line with a line ending
        #expect(try string.fuzzyLocation(line: 4, column: 0) == 9)
        #expect(try string.fuzzyLocation(line: 4, column: 1) == 10)
        #expect(try string.fuzzyLocation(line: 4, column: 3) == 12)
        #expect(throws: FuzzyLocationError.invalidColumn(4)) { try string.fuzzyLocation(line: 4, column: 4) }
        #expect(try string.fuzzyLocation(line: 4, column: -1) == 12)
        #expect(try string.fuzzyLocation(line: 4, column: -2) == 11)
        
        // line without any line endings (the last line)
        #expect(try string.fuzzyLocation(line: 5, column: 0) == 13)
        #expect(try string.fuzzyLocation(line: 5, column: 1) == 14)
        #expect(try string.fuzzyLocation(line: 5, column: 3) == 16)
        #expect(throws: FuzzyLocationError.invalidColumn(4)) { try string.fuzzyLocation(line: 5, column: 4) }
        #expect(try string.fuzzyLocation(line: 5, column: -1) == 16)
        #expect(try string.fuzzyLocation(line: 5, column: -2) == 15)
    }
}
