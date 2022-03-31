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
//  © 2015-2022 1024jp
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
    
    
    func testDetection() {
        
        XCTAssertNil("".detectedLineEnding)
        XCTAssertNil("a".detectedLineEnding)
        XCTAssertEqual("\n".detectedLineEnding, .lf)
        XCTAssertEqual("\r".detectedLineEnding, .cr)
        XCTAssertEqual("\r\n".detectedLineEnding, .crlf)
        XCTAssertEqual("\u{85}".detectedLineEnding, .nel)
        XCTAssertEqual("abc\u{2029}def".detectedLineEnding, .paragraphSeparator)
        XCTAssertEqual("\rfoo\r\nbar\nbuz\u{2029}moin\r\n".detectedLineEnding, .crlf)  // most used new line must be detected
    
        let bom = "\u{feff}"
        let string = "\(bom)\r\n"
        XCTAssertEqual(string.count, 2)
        XCTAssertEqual(string.immutable.count, 1)
        XCTAssertEqual(string.detectedLineEnding, .crlf)
    }
    
    
    func testCount() {
        
        XCTAssertEqual("".countExceptLineEnding, 0)
        XCTAssertEqual("foo\nbar".countExceptLineEnding, 6)
        XCTAssertEqual("\u{feff}".countExceptLineEnding, 1)
        XCTAssertEqual("\u{feff}a".countExceptLineEnding, 2)
    }
    
    
    func testLineEndingRanges() {
        
        let string = "\rfoo\r\nbar \n \nb \n\r uz\u{2029}moin\r\n"
        let expected: [LineEnding: [NSRange]] = [
            .lf: [NSRange(location: 10, length: 1),
                  NSRange(location: 12, length: 1),
                  NSRange(location: 15, length: 1)],
            .cr: [NSRange(location: 0, length: 1),
                  NSRange(location: 16, length: 1)],
            .crlf: [NSRange(location: 4, length: 2),
                    NSRange(location: 25, length: 2)],
            .paragraphSeparator: [NSRange(location: 20, length: 1)],
        ]
        
        XCTAssertNil("".lineEndingRanges())
        XCTAssertNil("abc".lineEndingRanges())
        XCTAssertEqual(string.lineEndingRanges(), expected)
        
        let expectedPartly: [LineEnding: [NSRange]] = [
            .lf: [NSRange(location: 10, length: 1),
                  NSRange(location: 12, length: 1)],
            .cr: [NSRange(location: 0, length: 1)],
            .crlf: [NSRange(location: 4, length: 2)],
        ]
        XCTAssertEqual(string.lineEndingRanges(maximum: 2), expectedPartly)
    }
    
    
    func testReplacement() {
        
        XCTAssertEqual("foo\r\nbar\n".replacingLineEndings(with: .cr), "foo\rbar\r")
        XCTAssertEqual("foo\r\nbar\n".replacingLineEndings([.lf], with: .cr), "foo\r\nbar\r")
    }
    
}
