//
//  StringExtensionsTests.swift
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

final class StringExtensionsTests: XCTestCase {
    
    /// Test if the U+FEFF omitting bug on Swift 5 still exists.
    func testFEFF() {
        
        let bom = "\u{feff}"
        
        XCTAssertEqual(bom.count, 1)
        XCTAssertEqual((bom + "abc").count, 4)
        XCTAssertEqual(NSString(string: bom).length, 0)
        XCTAssertEqual(NSString(string: bom + bom).length, 1)
        XCTAssertEqual(NSString(string: bom + "abc").length, 3)
        XCTAssertEqual(NSString(string: "a" + bom + "bc").length, 4)
    }
    
    
    func testCharacterEscape() {
        
        let string = "a\\a\\\\aa"
        
        XCTAssertFalse(string.isCharacterEscaped(at: 0))
        XCTAssertTrue(string.isCharacterEscaped(at: 2))
        XCTAssertFalse(string.isCharacterEscaped(at: 5))
    }
    
    
    func testUnescaping() {
        
        XCTAssertEqual("foo\\\\\\nbar".unescaped, "foo\\\\\nbar")
        XCTAssertEqual("\\foo\\\\\\0bar\\".unescaped, "\\foo\\\\\u{0}bar\\")
        XCTAssertEqual("\\\\\\\\foo".unescaped, "\\\\\\\\foo")
    }
    
    
    func testComposedCharactersCount() {
        
        // make sure that `Stirng.count` counts characters as I want
        XCTAssertEqual("foo".count, 3)
        XCTAssertEqual("\r\n".count, 1)
        XCTAssertEqual("😀🇯🇵a".count, 3)
        XCTAssertEqual("😀🏻".count, 1)
        XCTAssertEqual("👍🏻".count, 1)
        
        // single regional indicator
        XCTAssertEqual("🇦 ".count, 2)
    }
    
    
    func testWordsCount() {
        
        XCTAssertEqual("Clarus says moof!".numberOfWords, 3)
        XCTAssertEqual("plain-text".numberOfWords, 2)
        XCTAssertEqual("!".numberOfWords, 0)
        XCTAssertEqual("".numberOfWords, 0)
    }
    
    
    func testLinesCount() {
        
        XCTAssertEqual("".numberOfLines, 0)
        XCTAssertEqual("a".numberOfLines, 1)
        XCTAssertEqual("\n".numberOfLines, 1)
        XCTAssertEqual("\n\n".numberOfLines, 2)
        XCTAssertEqual("\u{feff}".numberOfLines, 1)
        XCTAssertEqual("ab\r\ncd".numberOfLines, 2)
        
        let testString = "a\nb c\n\n"
        XCTAssertEqual(testString.numberOfLines, 3)
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<0), includingLastLineEnding: true), 0)   // ""
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<1), includingLastLineEnding: true), 1)   // "a"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<2), includingLastLineEnding: true), 2)   // "a\n"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<2), includingLastLineEnding: false), 1)  // "a\n"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<6), includingLastLineEnding: true), 3)   // "a\nb c\n"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<7), includingLastLineEnding: true), 4)   // "a\nb c\n\n"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(2..<4), includingLastLineEnding: false), 1)  // "b c\n"
        
        XCTAssertEqual(testString.lineNumber(at: 0), 1)
        XCTAssertEqual(testString.lineNumber(at: 1), 1)
        XCTAssertEqual(testString.lineNumber(at: 2), 2)
        XCTAssertEqual(testString.lineNumber(at: 5), 2)
        XCTAssertEqual(testString.lineNumber(at: 6), 3)
        XCTAssertEqual(testString.lineNumber(at: 7), 4)
        
        XCTAssertEqual("\u{FEFF}".numberOfLines(in: NSRange(0..<1), includingLastLineEnding: false), 1)  // "\u{FEFF}"
        XCTAssertEqual("\u{FEFF}\nb".numberOfLines(in: NSRange(0..<3), includingLastLineEnding: false), 2)  // "\u{FEFF}\nb"
        XCTAssertEqual("a\u{FEFF}\nb".numberOfLines(in: NSRange(1..<4), includingLastLineEnding: false), 2)  // "\u{FEFF}\nb"
        XCTAssertEqual("a\u{FEFF}\u{FEFF}\nb".numberOfLines(in: NSRange(1..<5), includingLastLineEnding: false), 2)  // "\u{FEFF}\nb"
        
        XCTAssertEqual("a\u{FEFF}\nb".numberOfLines, 2)
        XCTAssertEqual("\u{FEFF}\nb".numberOfLines, 2)
        XCTAssertEqual("\u{FEFF}0000000000000000".numberOfLines, 1)
    }
    
    
    func testProgrammingCases() {
        
        XCTAssertEqual("AbcDefg Hij".snakecased, "abc_defg hij")
        XCTAssertEqual("abcDefg Hij".snakecased, "abc_defg hij")
        XCTAssertEqual("_abcDefg Hij".snakecased, "_abc_defg hij")
        
        XCTAssertEqual("abc_defg Hij".camelcased, "abcDefg hij")
        XCTAssertEqual("AbcDefg Hij".camelcased, "abcDefg hij")
        XCTAssertEqual("_abcDefg Hij".camelcased, "_abcDefg hij")
        
        XCTAssertEqual("abc_defg Hij".pascalcased, "AbcDefg Hij")
        XCTAssertEqual("abcDefg Hij".pascalcased, "AbcDefg Hij")
        XCTAssertEqual("_abcDefg Hij".pascalcased, "_abcDefg Hij")
    }
    
    
    func testJapaneseTransform() {
        
        let testString = "犬 イヌ いぬ Ｉｎｕ Dog 123 １２３"
        
        XCTAssertEqual(testString.fullWidthRoman, "犬 イヌ いぬ Ｉｎｕ Ｄｏｇ １２３ １２３")
        XCTAssertEqual(testString.halfWidthRoman, "犬 イヌ いぬ Inu Dog 123 123")
    }
    
    
    func testRange() {
        
        let string = "0123456789"
        
        XCTAssertEqual(string.range(location: 2, length: 2), NSRange(location: 2, length: 2))
        XCTAssertEqual(string.range(location: -1, length: 1), NSRange(location: 9, length: 1))
        XCTAssertEqual(string.range(location: 3, length: -2), NSRange(location: 3, length: "45678".utf16.count))
    }
        
        
    func testRangeForLine() {
        
        let string = "1\r\n2\r\n3\r\n4"  // 1 based
        var range: NSRange
        
        range = string.rangeForLine(location: 1, length: 2)!
        XCTAssertEqual((string as NSString).substring(with: range), "1\r\n2\r\n")
        
        range = string.rangeForLine(location: 4, length: 1)!
        XCTAssertEqual((string as NSString).substring(with: range), "4")
        
        range = string.rangeForLine(location: 3, length: 0)!
        XCTAssertEqual((string as NSString).substring(with: range), "3\r\n")

        range = string.rangeForLine(location: -1, length: 1)!
        XCTAssertEqual((string as NSString).substring(with: range), "4")

        range = string.rangeForLine(location: -2, length: 1)!
        XCTAssertEqual((string as NSString).substring(with: range), "3\r\n")

        range = string.rangeForLine(location: 2, length: -2)!
        XCTAssertEqual((string as NSString).substring(with: range), "2\r\n")
    }
    
    
    func testLineRange() {
        
        let string = "foo\n\rbar\n\r"
        
        XCTAssertEqual(string.lineContentsRange(for: string.startIndex..<string.endIndex),
                       string.startIndex..<string.index(before: string.endIndex))
        
        XCTAssertEqual(string.lineRange(at: string.index(after: string.startIndex)),
                       string.startIndex..<string.index(string.startIndex, offsetBy: 4))
        XCTAssertEqual(string.lineContentsRange(for: string.startIndex..<string.index(after: string.startIndex)),
                       string.startIndex..<string.index(string.startIndex, offsetBy: 3))
        
        XCTAssertEqual((string as NSString).lineContentsRange(for: NSRange(..<1)), NSRange(..<3))
        XCTAssertEqual((string as NSString).lineContentsRange(at: 5), NSRange(5..<8))
        
        let emptyString = ""
        let emptyRange = emptyString.startIndex..<emptyString.endIndex
        
        XCTAssertEqual(emptyString.lineContentsRange(for: emptyRange), emptyRange)
    }
    
    
    func testLineRanges() {

        XCTAssertEqual("foo\nbar".lineContentsRanges(for: NSRange(1..<1)), [NSRange(1..<1)])
        XCTAssertEqual("foo\nbar".lineContentsRanges(), [NSRange(0..<3), NSRange(4..<7)])
        XCTAssertEqual("foo\nbar\n".lineContentsRanges(), [NSRange(0..<3), NSRange(4..<7)])
        XCTAssertEqual("foo\r\nbar".lineContentsRanges(), [NSRange(0..<3), NSRange(5..<8)])
        XCTAssertEqual("foo\r\r\rbar".lineContentsRanges().count, 4)
    }
    
    
    func testRangeOfCharacter() {
        
        let set = CharacterSet(charactersIn: "._")
        let string = "abc.d🐕f_ghij" as NSString
        
        XCTAssertEqual(string.substring(with: string.rangeOfCharacter(until: set, at: 0)), "abc")
        XCTAssertEqual(string.substring(with: string.rangeOfCharacter(until: set, at: 4)), "d🐕f")
        XCTAssertEqual(string.substring(with: string.rangeOfCharacter(until: set, at: string.length - 1)), "ghij")
    }
    
    
    func testUnicodeNormalization() {
        
        XCTAssertEqual("É \t 神 ㍑ ＡＢC".precomposedStringWithCompatibilityMappingWithCasefold, "é \t 神 リットル abc")
        XCTAssertEqual("\u{1f71} \u{03b1}\u{0301}".precomposedStringWithHFSPlusMapping, "\u{1f71} \u{03ac}")
        XCTAssertEqual("\u{1f71}".precomposedStringWithHFSPlusMapping, "\u{1f71}")  // test single char
        XCTAssertEqual("\u{1f71}".decomposedStringWithHFSPlusMapping, "\u{03b1}\u{0301}")
    }
    
    
    func testWhitespaceTriming() {
        
        let string = """
            
            abc def
                \t
            white space -> \t
            abc
            """
        
        let trimmed = string.trim(ranges: string.rangesOfTrailingWhitespace(ignoresEmptyLines: false))
        let expectedTrimmed = """
            
            abc def
            
            white space ->
            abc
            """
        XCTAssertEqual(trimmed, expectedTrimmed)
        
        let trimmedIgnoringEmptyLines = string.trim(ranges: string.rangesOfTrailingWhitespace(ignoresEmptyLines: true))
        let expectedTrimmedIgnoringEmptyLines =  """
            
            abc def
                \t
            white space ->
            abc
            """
        XCTAssertEqual(trimmedIgnoringEmptyLines, expectedTrimmedIgnoringEmptyLines)
    }

}



private extension String {
    
    func trim(ranges: [NSRange]) -> String {
        
        return ranges.reversed()
            .map { Range($0, in: self)! }
            .reduce(self) { $0.replacingCharacters(in: $1, with: "") }
    }
}
