//
//  FormatStylesTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

final class FormatStylesTests: XCTestCase {
    
    func testRangedInteger() throws {
        
        let formatter = RangedIntegerFormatStyle(range: 1...(.max))
        
        XCTAssertEqual(formatter.format(-3), "1")
        XCTAssertEqual(try formatter.parseStrategy.parse("0"), 1)
        XCTAssertEqual(try formatter.parseStrategy.parse("1"), 1)
        XCTAssertEqual(try formatter.parseStrategy.parse("2"), 2)
        XCTAssertEqual(try formatter.parseStrategy.parse("a"), 1)
    }
    
    
    func testRangedIntegerWithDefault() throws {
        
        let formatter = RangedIntegerFormatStyle(range: -1...(.max), defaultValue: 4)
        
        XCTAssertEqual(formatter.format(-3), "-1")
        XCTAssertEqual(try formatter.parseStrategy.parse("-2"), -1)
        XCTAssertEqual(try formatter.parseStrategy.parse("-1"), -1)
        XCTAssertEqual(try formatter.parseStrategy.parse("0"), 0)
        XCTAssertEqual(try formatter.parseStrategy.parse("2"), 2)
        XCTAssertEqual(try formatter.parseStrategy.parse("a"), 4)
    }
}
