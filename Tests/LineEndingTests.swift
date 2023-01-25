//
//  LineEndingTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2023 1024jp
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

final class LineEndingTests: XCTestCase {
    
    func testLineEnding() {
        
        XCTAssertEqual(LineEnding.lf.rawValue, "\n")
        XCTAssertEqual(LineEnding.crlf.rawValue, "\r\n")
        XCTAssertEqual(LineEnding.paragraphSeparator.rawValue, "\u{2029}")
    }
    
    
    func testName() {
        
        XCTAssertEqual(LineEnding.lf.name, "LF")
        XCTAssertEqual(LineEnding.crlf.name, "CRLF")
        XCTAssertEqual(LineEnding.paragraphSeparator.name, "PS")
    }
    
    
    func testLineEndingRanges() {
        
        let string = "\rfoo\r\nbar \n \nb \n\r uz\u{2029}moin\r\n"
        let expected: [ValueRange<LineEnding>] = [
            .init(value: .cr, location: 0),
            .init(value: .crlf, location: 4),
            .init(value: .lf, location: 10),
            .init(value: .lf, location: 12),
            .init(value: .lf, location: 15),
            .init(value: .cr, location: 16),
            .init(value: .paragraphSeparator, location: 20),
            .init(value: .crlf, location: 25),
        ]
        
        XCTAssert("".lineEndingRanges().isEmpty)
        XCTAssert("abc".lineEndingRanges().isEmpty)
        XCTAssertEqual(string.lineEndingRanges(), expected)
    }
    
    
    func testReplacement() {
        
        XCTAssertEqual("foo\r\nbar\n".replacingLineEndings(with: .cr), "foo\rbar\r")
        XCTAssertEqual("foo\r\nbar\n".replacingLineEndings([.lf], with: .cr), "foo\r\nbar\r")
    }
}



private extension ValueRange where Value == LineEnding {
    
    init(value: LineEnding, location: Int) {
        
        self.init(value: value, range: NSRange(location: location, length: value.length))
    }
}
