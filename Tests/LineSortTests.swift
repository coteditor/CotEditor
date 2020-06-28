//
//  LineSortTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-01-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2020 1024jp
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

final class LineSortTests: XCTestCase {
    
    private let lines = """
            dog, 🐕, 2, イヌ
            cat, 🐈, 1, ねこ
            cow, 🐄, 3, ｳｼ
            """
    
    
    func testCSVSort() {
        
        let pattern = CSVSortPattern()
        pattern.column = 3
        
        let result = """
            cat, 🐈, 1, ねこ
            dog, 🐕, 2, イヌ
            cow, 🐄, 3, ｳｼ
            """
        
        XCTAssertEqual(pattern.sort(self.lines), result)
        XCTAssertEqual(pattern.sort(""), "")
        XCTAssertNoThrow(try pattern.validate())
    }
    
    
    func testRegexSort() throws {
        
        let pattern = RegularExpressionSortPattern()
        pattern.searchPattern = ", ([0-9]),"
        
        let result = """
            cat, 🐈, 1, ねこ
            dog, 🐕, 2, イヌ
            cow, 🐄, 3, ｳｼ
            """
        
        XCTAssertEqual(pattern.sort(self.lines), result)
        
        pattern.usesCaptureGroup = true
        pattern.group = 1
        XCTAssertEqual(pattern.sort(self.lines), result)
        XCTAssertEqual(pattern.sort(""), "")
        XCTAssertNoThrow(try pattern.validate())
        
        pattern.searchPattern = "\\"
        XCTAssertThrowsError(try pattern.validate())
        
        pattern.searchPattern = "(a)(b)c"
        try pattern.validate()
        XCTAssertEqual(pattern.numberOfCaptureGroups, 2)
    }
    
    
    func testFuzzySort() {
        
        let pattern = CSVSortPattern()
        pattern.column = 4
        
        let options = SortOptions()
        options.isLocalized = true
        
        let result = """
            dog, 🐕, 2, イヌ
            cow, 🐄, 3, ｳｼ
            cat, 🐈, 1, ねこ
            """
        
        XCTAssertEqual(pattern.sort(self.lines, options: options), result)
        XCTAssertEqual(pattern.sort(""), "")
        XCTAssertNoThrow(try pattern.validate())
    }
    
    
    func testNumericSorts() {
        
        let pattern = EntireLineSortPattern()
        let numbers = """
            3
            12
            1
            """
        
        let options = SortOptions()
        
        options.numeric = false
        XCTAssertEqual(pattern.sort(numbers, options: options), "1\n12\n3")
        
        options.numeric = true
        XCTAssertEqual(pattern.sort(numbers, options: options), "1\n3\n12")
        
        options.decending = true
        XCTAssertEqual(pattern.sort(numbers, options: options), "12\n3\n1")
        
        options.decending = false
        options.keepsFirstLine = true
        XCTAssertEqual(pattern.sort(numbers, options: options), "3\n1\n12")
    }
    
    
    func testTargetRange() {
        
        let string = "dog"
        XCTAssertEqual(EntireLineSortPattern().range(for: string), string.startIndex..<string.endIndex)
        XCTAssertEqual(CSVSortPattern().range(for: string), string.startIndex..<string.endIndex)
        XCTAssertNil(RegularExpressionSortPattern().range(for: string))
        
        XCTAssertEqual(CSVSortPattern().range(for: ""), Range(NSRange(0..<0), in: ""))
        
        let csvString = " dog  , dog cow "
        let pattern = CSVSortPattern()
        pattern.column = 2
        XCTAssertEqual(pattern.range(for: csvString), Range(NSRange(8..<15), in: csvString))
        
        let tsvString = "a\tb"
        pattern.column = 1
        XCTAssertEqual(pattern.sortKey(for: tsvString), tsvString)
        XCTAssertEqual(NSRange(pattern.range(for: tsvString)!, in: tsvString), NSRange(0..<3))
    }
    
}
