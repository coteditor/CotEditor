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
//  © 2015-2019 1024jp
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

class LineEndingTests: XCTestCase {
    
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
        XCTAssertEqual("\n".detectedLineEnding, LineEnding.lf)
        XCTAssertEqual("\r".detectedLineEnding, LineEnding.cr)
        XCTAssertEqual("\r\n".detectedLineEnding, LineEnding.crlf)
        XCTAssertEqual("foo\r\nbar\nbuz\u{2029}moin".detectedLineEnding, LineEnding.crlf)  // just check the first new line
    }
    
    
    func testCount() {
        
        XCTAssertEqual("foo\nbar".countExceptLineEnding, 6)
        XCTAssertEqual("\u{feff}".countExceptLineEnding, 1)
    }
    
    
    func testReplacement() {
        
        XCTAssertEqual("foo\r\nbar".replacingLineEndings(with: .cr), "foo\rbar")
    }
    
    
    func testRangeConversion() {
        
        let lfToCrlfRange = "a\nb\nc".convert(range: NSRange(location: 2, length: 2), from: .lf, to: .crlf)
        XCTAssertEqual(lfToCrlfRange.location, 3)
        XCTAssertEqual(lfToCrlfRange.length, 3)
        
        let implicitConvertedRange = "a\r\nb\r\nc".convert(range: NSRange(location: 3, length: 3), to: .lf)
        XCTAssertEqual(implicitConvertedRange.location, 2)
        XCTAssertEqual(implicitConvertedRange.length, 2)
    }

}
