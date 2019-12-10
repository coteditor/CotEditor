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
//  © 2018 1024jp
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

    let lines = """
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
    }
    
    
    func testRegexSort() {
        
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
    }

}
