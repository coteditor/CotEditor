/*

StringExtensionsTests.swift
Tests

CotEditor
http://coteditor.com

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

class StringExtensionsTests: XCTestCase {
    
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
        XCTAssertEqual(testString.numberOfLinesInRange(NSRange(location: 0, length: 0), includingLastNewLine:true),  0)  // ""
        XCTAssertEqual(testString.numberOfLinesInRange(NSRange(location: 0, length: 1), includingLastNewLine:true),  1)  // "a"
        XCTAssertEqual(testString.numberOfLinesInRange(NSRange(location: 0, length: 2), includingLastNewLine:true),  2)  // "a\n"
        XCTAssertEqual(testString.numberOfLinesInRange(NSRange(location: 0, length: 2), includingLastNewLine:false), 1)  // "a\n"
        XCTAssertEqual(testString.numberOfLinesInRange(NSRange(location: 0, length: 6), includingLastNewLine:true),  3)  // "a\nb c\n"
        XCTAssertEqual(testString.numberOfLinesInRange(NSRange(location: 0, length: 7), includingLastNewLine:true),  4)  // "a\nb c\n\n"
        XCTAssertEqual(testString.numberOfLinesInRange(NSRange(location: 2, length: 4), includingLastNewLine:false), 1)  // "b c\n"
        
        XCTAssertEqual(testString.lineNumberAtIndex(0), 1)
        XCTAssertEqual(testString.lineNumberAtIndex(1), 1)
        XCTAssertEqual(testString.lineNumberAtIndex(2), 2)
        XCTAssertEqual(testString.lineNumberAtIndex(5), 2)
        XCTAssertEqual(testString.lineNumberAtIndex(6), 3)
        XCTAssertEqual(testString.lineNumberAtIndex(7), 4)
    }
    
    
    func testJapaneseTransform() {
        let testString = "犬 イヌ いぬ Ｉｎｕ Dog"
        
        XCTAssertEqual(testString.fullWidthRomanString(), "犬 イヌ いぬ Ｉｎｕ Ｄｏｇ")
        XCTAssertEqual(testString.halfWidthRomanString(), "犬 イヌ いぬ Inu Dog")
        XCTAssertEqual(testString.katakanaString(), "犬 イヌ イヌ Ｉｎｕ Dog")
        XCTAssertEqual(testString.hiraganaString(), "犬 いぬ いぬ Ｉｎｕ Dog")
    }
    
    
    func testNewLine() {
        // new line string
        XCTAssertEqual(NSString.newLineStringWithType(.LF), "\n")
        XCTAssertEqual(NSString.newLineStringWithType(.CRLF), "\r\n")
        XCTAssertEqual(NSString.newLineStringWithType(.ParagraphSeparator), "\u{2029}")
        
        // new line name
        XCTAssertEqual(NSString.newLineNameWithType(.LF), "LF")
        XCTAssertEqual(NSString.newLineNameWithType(.CRLF), "CR/LF")
        XCTAssertEqual(NSString.newLineNameWithType(.ParagraphSeparator), "PS")
        
        // new line detection
        XCTAssertEqual("".detectNewLineType(), CENewLineType.None)
        XCTAssertEqual("a".detectNewLineType(), CENewLineType.None)
        XCTAssertEqual("\n".detectNewLineType(), CENewLineType.LF)
        XCTAssertEqual("\r".detectNewLineType(), CENewLineType.CR)
        XCTAssertEqual("\r\n".detectNewLineType(), CENewLineType.CRLF)
        XCTAssertEqual("foo\r\nbar\nbuz\u{2029}moin".detectNewLineType(), CENewLineType.CRLF)  // just check the first new line
        
        // new line replacement
        XCTAssertEqual("foo\nbar".stringByDeletingNewLineCharacters(), "foobar")
        XCTAssertEqual("foo\r\nbar".stringByReplacingNewLineCharacersWith(.CR), "foo\rbar")
    }
    
    
    func testRange() {
        let testString = "0123456789" as NSString
        
        XCTAssertTrue(NSEqualRanges(testString.rangeForLocation(2, length: 2), NSMakeRange(2, 2)))
        XCTAssertTrue(NSEqualRanges(testString.rangeForLocation(-1, length: 1), NSMakeRange(9, 1)))
        XCTAssertTrue(NSEqualRanges(testString.rangeForLocation(3, length: -2), NSMakeRange(3, "45678".length)))
        
        
        let linesString = "1\r\n2\r\n3\r\n4" as NSString  // 1 based
        var range: NSRange
        
        range = linesString.rangeForLineLocation(1, length: 2)
        XCTAssertEqual(linesString.substringWithRange(range), "1\r\n2\r\n")
        
        range = linesString.rangeForLineLocation(-1, length: 1)
        XCTAssertEqual(linesString.substringWithRange(range), "4")
        
        range = linesString.rangeForLineLocation(-2, length: 1)
        XCTAssertEqual(linesString.substringWithRange(range), "3\r\n")
        
        range = linesString.rangeForLineLocation(2, length: -2)
        XCTAssertEqual(linesString.substringWithRange(range), "2\r\n")
    }
    
    
    func testUnicodeNormalization() {
        XCTAssertEqual("é 神 ㍑".precomposedStringWithCompatibilityMappingWithCasefold(), "é 神 リットル")
        XCTAssertEqual("é 神 ㍑".decomposedStringWithHFSPlusMapping(), "é 神 ㍑")
    }
    
}
