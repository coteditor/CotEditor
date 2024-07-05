//
//  LineSortTests.swift
//  LineSortTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-01-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2024 1024jp
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
@testable import LineSort

struct LineSortTests {
    
    private let lines = """
            dog, 🐕, 2, イヌ
            cat, 🐈, 1, ねこ
            cow, 🐄, 3, ｳｼ
            """
    
    
    @Test func csvSort() {
        
        var pattern = CSVSortPattern()
        pattern.column = 3
        
        let result = """
            cat, 🐈, 1, ねこ
            dog, 🐕, 2, イヌ
            cow, 🐄, 3, ｳｼ
            """
        
        #expect(pattern.sort(self.lines) == result)
        #expect(pattern.sort("").isEmpty)
        #expect(throws: Never.self) { try pattern.validate() }
        #expect(pattern.range(for: "dog, 🐕,   , イヌ") == nil)
    }
    
    
    @Test func regexSort() throws {
        
        var pattern = RegularExpressionSortPattern()
        pattern.searchPattern = ", ([0-9]),"
        
        let result = """
            cat, 🐈, 1, ねこ
            dog, 🐕, 2, イヌ
            cow, 🐄, 3, ｳｼ
            """
        
        #expect(pattern.sort(self.lines) == result)
        
        pattern.usesCaptureGroup = true
        pattern.group = 1
        #expect(pattern.sort(self.lines) == result)
        #expect(pattern.sort("").isEmpty)
        #expect(throws: Never.self) { try pattern.validate() }
        
        pattern.searchPattern = "\\"
        #expect(throws: SortPatternError.invalidRegularExpressionPattern) { try pattern.validate() }
        
        pattern.searchPattern = "(a)(b)c"
        try pattern.validate()
        #expect(pattern.numberOfCaptureGroups == 2)
    }
    
    
    @Test func fuzzySort() {
        
        var pattern = CSVSortPattern()
        pattern.column = 4
        
        var options = SortOptions()
        options.isLocalized = true
        
        let result = """
            dog, 🐕, 2, イヌ
            cow, 🐄, 3, ｳｼ
            cat, 🐈, 1, ねこ
            """
        
        #expect(pattern.sort(self.lines, options: options) == result)
        #expect(pattern.sort("").isEmpty)
        #expect(throws: Never.self) { try pattern.validate() }
    }
    
    
    @Test func numericSort() {
        
        let pattern = EntireLineSortPattern()
        let numbers = """
            3
            12
            1
            """
        
        var options = SortOptions()
        
        options.numeric = false
        #expect(pattern.sort(numbers, options: options) == "1\n12\n3")
        
        options.numeric = true
        #expect(pattern.sort(numbers, options: options) == "1\n3\n12")
        
        options.descending = true
        #expect(pattern.sort(numbers, options: options) == "12\n3\n1")
        
        options.descending = false
        options.keepsFirstLine = true
        #expect(pattern.sort(numbers, options: options) == "3\n1\n12")
    }
    
    
    @Test func targetRange() throws {
        
        let string = "dog"
        #expect(EntireLineSortPattern().range(for: string) == string.startIndex..<string.endIndex)
        #expect(CSVSortPattern().range(for: string) == string.startIndex..<string.endIndex)
        #expect(RegularExpressionSortPattern().range(for: string) == nil)
        
        #expect(CSVSortPattern().range(for: "") == Range(NSRange(0..<0), in: ""))
        
        let csvString = " dog  , dog cow "
        var pattern = CSVSortPattern()
        pattern.column = 2
        #expect(pattern.range(for: csvString) == Range(NSRange(8..<15), in: csvString))
        
        let tsvString = "a\tb"
        pattern.column = 1
        let range = try #require(pattern.range(for: tsvString))
        #expect(pattern.sortKey(for: tsvString) == tsvString)
        #expect(NSRange(range, in: tsvString) == NSRange(0..<3))
    }
    
    
    @Test func parseNumber() throws {
        
        var options = SortOptions()
        
        options.locale = .init(identifier: "en")
        #expect(options.isLocalized)
        #expect(options.numeric)
        #expect(options.parse("0") == 0)
        #expect(options.parse("10 000") == 10000)
        #expect(options.parse("-1000.1 m/s") == -1000.1)
        #expect(options.parse("-1000,1 m/s") == -1000)
        #expect(options.parse("+1,000") == 1000)
        #expect(options.parse("dog 10") == nil)
        
        options.locale = .init(identifier: "de")
        #expect(options.numeric)
        #expect(options.parse("0") == 0)
        #expect(options.parse("10 000") == 10000)
        #expect(options.parse("-1000.1 m/s") == -1000)
        #expect(options.parse("-1000,1 m/s") == -1000.1)
        #expect(options.parse("+1,000") == 1)
        #expect(options.parse("dog 10") == nil)
        
        options.numeric = false
        #expect(options.parse("0") == nil)
        #expect(options.parse("10 000") == nil)
        #expect(options.parse("-1000.1 m/s") == nil)
        #expect(options.parse("-1000,1 m/s") == nil)
        #expect(options.parse("+1,000") == nil)
        #expect(options.parse("dog 10") == nil)
    }
}
