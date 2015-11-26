/*

StringExtensionsTests.swift
Tests

CotEditor
http://coteditor.com

Created by 1024jp on 2015-11-09.

------------------------------------------------------------------------------

© 2015 1024jp

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
    
    override func setUp() {
        super.setUp()
    }
    
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testComposedCharactersCount() {
        XCTAssertEqual("foo".numberOfComposedCharacters(), 3)
        XCTAssertEqual("😀🇯🇵".numberOfComposedCharacters(), 2)
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
    
    
    func testUnicodeNormalization() {
        XCTAssertEqual("é 神 ㍑".precomposedStringWithCompatibilityMappingWithCasefold(), "é 神 リットル")
        XCTAssertEqual("é 神 ㍑".decomposedStringWithHFSPlusMapping(), "é 神 ㍑")
    }
    
}
