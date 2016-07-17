/*
 
 StringExtensionsTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-11-09.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import XCTest
@testable import CotEditor

class StringExtensionsTests: XCTestCase {
    
    func testCharacterEscape() {
        let string = "a\\a\\\\aa"
        
        XCTAssertFalse(string.isCharacterEscaped(at: 0))
        XCTAssertTrue(string.isCharacterEscaped(at: 2))
        XCTAssertFalse(string.isCharacterEscaped(at: 5))
    }
    
    
    func testComposedCharactersCount() {
        XCTAssertEqual("foo".numberOfComposedCharacters(), 3)
        XCTAssertEqual("😀🇯🇵a".numberOfComposedCharacters(), 3)
        
        // single regional indicator
        XCTAssertEqual("🇦 ".numberOfComposedCharacters(), 2)
    }
    
    
    func testWordsCount() {
        XCTAssertEqual("Clarus says moof!".numberOfWords(), 3)
        XCTAssertEqual("plain-text".numberOfWords(), 2)
        XCTAssertEqual("!".numberOfWords(), 0)
        XCTAssertEqual("".numberOfWords(), 0)
    }
    
    
    func testLinesCount() {
        XCTAssertEqual("".numberOfLines(), 0)
        XCTAssertEqual("a".numberOfLines(), 1)
        XCTAssertEqual("\n".numberOfLines(), 1)
        XCTAssertEqual("\n\n".numberOfLines(), 2)
        
        let testString = "a\nb c\n\n"
        XCTAssertEqual(testString.numberOfLines(), 3)
        XCTAssertEqual(testString.numberOfLines(in: NSRange(location: 0, length: 0), includingLastNewLine:true),  0)  // ""
        XCTAssertEqual(testString.numberOfLines(in: NSRange(location: 0, length: 1), includingLastNewLine:true),  1)  // "a"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(location: 0, length: 2), includingLastNewLine:true),  2)  // "a\n"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(location: 0, length: 2), includingLastNewLine:false), 1)  // "a\n"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(location: 0, length: 6), includingLastNewLine:true),  3)  // "a\nb c\n"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(location: 0, length: 7), includingLastNewLine:true),  4)  // "a\nb c\n\n"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(location: 2, length: 4), includingLastNewLine:false), 1)  // "b c\n"
        
        XCTAssertEqual(testString.lineNumber(at: 0), 1)
        XCTAssertEqual(testString.lineNumber(at: 1), 1)
        XCTAssertEqual(testString.lineNumber(at: 2), 2)
        XCTAssertEqual(testString.lineNumber(at: 5), 2)
        XCTAssertEqual(testString.lineNumber(at: 6), 3)
        XCTAssertEqual(testString.lineNumber(at: 7), 4)
    }
    
    
    func testJapaneseTransform() {
        let testString = "犬 イヌ いぬ Ｉｎｕ Dog"
        
        XCTAssertEqual(testString.fullWidthRoman, "犬 イヌ いぬ Ｉｎｕ Ｄｏｇ")
        XCTAssertEqual(testString.halfWidthRoman, "犬 イヌ いぬ Inu Dog")
        XCTAssertEqual(testString.katakana, "犬 イヌ イヌ Ｉｎｕ Dog")
        XCTAssertEqual(testString.hiragana, "犬 いぬ いぬ Ｉｎｕ Dog")
    }
    
    
    func testNewLine() {
        // new line string
        XCTAssertEqual(NSString.newLineString(with: .LF), "\n")
        XCTAssertEqual(NSString.newLineString(with: .CRLF), "\r\n")
        XCTAssertEqual(NSString.newLineString(with: .paragraphSeparator), "\u{2029}")
        
        // new line name
        XCTAssertEqual(NSString.newLineName(with: .LF), "LF")
        XCTAssertEqual(NSString.newLineName(with: .CRLF), "CR/LF")
        XCTAssertEqual(NSString.newLineName(with: .paragraphSeparator), "PS")
        
        // new line detection
        XCTAssertEqual("".detectNewLineType(), CENewLineType.none)
        XCTAssertEqual("a".detectNewLineType(), CENewLineType.none)
        XCTAssertEqual("\n".detectNewLineType(), CENewLineType.LF)
        XCTAssertEqual("\r".detectNewLineType(), CENewLineType.CR)
        XCTAssertEqual("\r\n".detectNewLineType(), CENewLineType.CRLF)
        XCTAssertEqual("foo\r\nbar\nbuz\u{2029}moin".detectNewLineType(), CENewLineType.CRLF)  // just check the first new line
        
        // new line replacement
        XCTAssertEqual("foo\nbar".deletingNewLineCharacters(), "foobar")
        XCTAssertEqual("foo\r\nbar".replacingNewLineCharacers(with: .CR), "foo\rbar")
        
        // range conversion
        XCTAssertTrue(NSEqualRanges("a\nb\nc".convert(NSMakeRange(2, 2), from:.LF, to:.CRLF), NSMakeRange(3, 3)))
        XCTAssertTrue(NSEqualRanges("a\r\nb\r\nc".convert(NSMakeRange(3, 3), from:.none, to:.LF), NSMakeRange(2, 2)))
    }
    
    
    func testRange() {
        let testString = "0123456789" as NSString
        
        XCTAssertTrue(NSEqualRanges(testString.range(location: 2, length: 2), NSMakeRange(2, 2)))
        XCTAssertTrue(NSEqualRanges(testString.range(location: -1, length: 1), NSMakeRange(9, 1)))
        XCTAssertTrue(NSEqualRanges(testString.range(location: 3, length: -2), NSMakeRange(3, "45678".length)))
        
        
        let linesString = "1\r\n2\r\n3\r\n4" as NSString  // 1 based
        var range: NSRange
        
        range = linesString.rangeForLine(location: 1, length: 2)
        XCTAssertEqual(linesString.substring(with: range), "1\r\n2\r\n")
        
        range = linesString.rangeForLine(location: -1, length: 1)
        XCTAssertEqual(linesString.substring(with: range), "4")
        
        range = linesString.rangeForLine(location: -2, length: 1)
        XCTAssertEqual(linesString.substring(with: range), "3\r\n")
        
        range = linesString.rangeForLine(location: 2, length: -2)
        XCTAssertEqual(linesString.substring(with: range), "2\r\n")
    }
    
    
    func testUnicodeNormalization() {
        
        XCTAssertEqual("é 神 ㍑".precomposedStringWithCompatibilityMappingWithCasefold, "é 神 リットル")
        XCTAssertEqual("\u{1f71} \u{03b1}\u{0301}".precomposedStringWithHFSPlusMapping, "\u{1f71} \u{03ac}")
        XCTAssertEqual("\u{1f71}".precomposedStringWithHFSPlusMapping, "\u{1f71}")  // test single char
        XCTAssertEqual("\u{1f71}".decomposedStringWithHFSPlusMapping, "\u{03b1}\u{0301}")
    }

}
