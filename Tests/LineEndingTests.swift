/*
 
 LineEndingTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-11-09.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import XCTest
@testable import CotEditor

class LineEndingTests: XCTestCase {
    
    func testLineEnding() {
        
        XCTAssertEqual(LineEnding.LF.rawValue, "\n")
        XCTAssertEqual(LineEnding.CRLF.rawValue, "\r\n")
        XCTAssertEqual(LineEnding.paragraphSeparator.rawValue, "\u{2029}")
    }
    
    
    func testName() {
        
        XCTAssertEqual(LineEnding.LF.name, "LF")
        XCTAssertEqual(LineEnding.CRLF.name, "CR/LF")
        XCTAssertEqual(LineEnding.paragraphSeparator.name, "PS")
    }
    
    
    func testDetection() {
        
        XCTAssertNil("".detectedLineEnding)
        XCTAssertNil("a".detectedLineEnding)
        XCTAssertEqual("\n".detectedLineEnding, LineEnding.LF)
        XCTAssertEqual("\r".detectedLineEnding, LineEnding.CR)
        XCTAssertEqual("\r\n".detectedLineEnding, LineEnding.CRLF)
        XCTAssertEqual("foo\r\nbar\nbuz\u{2029}moin".detectedLineEnding, LineEnding.CRLF)  // just check the first new line
    }
    
    
    func testReplacement() {
        
        XCTAssertEqual("foo\nbar".removingLineEndings, "foobar")
        XCTAssertEqual("foo\r\nbar".replacingLineEndings(with: .CR), "foo\rbar")
    }
    
    
    func testRangeConversion() {
        
        let lfToCrlfRange = "a\nb\nc".convert(from: .LF, to: .CRLF, range: NSRange(location: 2, length: 2))
        XCTAssertEqual(lfToCrlfRange.location, 3)
        XCTAssertEqual(lfToCrlfRange.length, 3)
        
        let implicitConvertedRange = "a\r\nb\r\nc".convert(to: .LF, range: NSRange(location: 3, length: 3))
        XCTAssertEqual(implicitConvertedRange.location, 2)
        XCTAssertEqual(implicitConvertedRange.length, 2)
    }

}
