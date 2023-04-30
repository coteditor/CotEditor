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

final class StringExtensionsTests: XCTestCase {
    
    /// Test if the U+FEFF omitting bug on Swift 5 still exists.
    ///
    /// - Bug: <https://bugs.swift.org/browse/SR-10896>
    func testFEFF() {
        
        let bom = "\u{feff}"
        
        // -> Some of these test cases must fail if the bug fixed.
        XCTAssertEqual(bom.count, 1)
        XCTAssertEqual(("\(bom)abc").count, 4)
        XCTAssertEqual(NSString(string: bom).length, 0)  // correct: 1
        XCTAssertEqual(NSString(string: "\(bom)\(bom)").length, 1)  // correct: 2
        XCTAssertEqual(NSString(string: "\(bom)abc").length, 3)  // correct: 4
        XCTAssertEqual(NSString(string: "a\(bom)bc").length, 4)
        
        let string = "\(bom)abc"
        XCTAssertNotEqual(string.immutable, string)  // -> This test must fail if the bug fixed.
        
        // Implicit NSString cast is fixed.
        // -> However, still crashes when `string.immutable.enumerateSubstrings(in:)`
        let middleIndex = string.index(string.startIndex, offsetBy: 2)
        string.enumerateSubstrings(in: middleIndex..<string.endIndex, options: .byLines) { (_, _, _, _) in }
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
        XCTAssertEqual(#"foo：\n\n1"#.unescaped, "foo：\n\n1")
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
        XCTAssertEqual("\n".numberOfLines, 2)
        XCTAssertEqual("\n\n".numberOfLines, 3)
        XCTAssertEqual("\u{feff}".numberOfLines, 1)
        XCTAssertEqual("ab\r\ncd".numberOfLines, 2)
        
        let testString = "a\nb c\n\n"
        XCTAssertEqual(testString.numberOfLines, 4)
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<0)), 0)   // ""
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<1)), 1)   // "a"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<2)), 2)   // "a\n"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<6)), 3)   // "a\nb c\n"
        XCTAssertEqual(testString.numberOfLines(in: NSRange(0..<7)), 4)   // "a\nb c\n\n"
        
        XCTAssertEqual(testString.lineNumber(at: 0), 1)
        XCTAssertEqual(testString.lineNumber(at: 1), 1)
        XCTAssertEqual(testString.lineNumber(at: 2), 2)
        XCTAssertEqual(testString.lineNumber(at: 5), 2)
        XCTAssertEqual(testString.lineNumber(at: 6), 3)
        XCTAssertEqual(testString.lineNumber(at: 7), 4)
        
        let nsString = testString as NSString
        XCTAssertEqual(nsString.lineNumber(at: 0), testString.lineNumber(at: 0))
        XCTAssertEqual(nsString.lineNumber(at: 1), testString.lineNumber(at: 1))
        XCTAssertEqual(nsString.lineNumber(at: 2), testString.lineNumber(at: 2))
        XCTAssertEqual(nsString.lineNumber(at: 5), testString.lineNumber(at: 5))
        XCTAssertEqual(nsString.lineNumber(at: 6), testString.lineNumber(at: 6))
        XCTAssertEqual(nsString.lineNumber(at: 7), testString.lineNumber(at: 7))
        
        XCTAssertEqual("\u{FEFF}".numberOfLines(in: NSRange(0..<1)), 1)  // "\u{FEFF}"
        XCTAssertEqual("\u{FEFF}\nb".numberOfLines(in: NSRange(0..<3)), 2)  // "\u{FEFF}\nb"
        XCTAssertEqual("a\u{FEFF}\nb".numberOfLines(in: NSRange(1..<4)), 2)  // "\u{FEFF}\nb"
        XCTAssertEqual("a\u{FEFF}\u{FEFF}\nb".numberOfLines(in: NSRange(1..<5)), 2)  // "\u{FEFF}\nb"
        
        XCTAssertEqual("a\u{FEFF}\nb".numberOfLines, 2)
        XCTAssertEqual("\u{FEFF}\nb".numberOfLines, 2)
        XCTAssertEqual("\u{FEFF}0000000000000000".numberOfLines, 1)
        
        let bomString = "\u{FEFF}\nb"
        let range = bomString.startIndex..<bomString.index(bomString.startIndex, offsetBy: 2)
        XCTAssertEqual(bomString.numberOfLines(in: [range, range]), 2)  // "\u{FEFF}\nb"
    }
    
    
    func testColumnCOunt() {
        
        let string = "aaa \r\n🐱 "
        
        XCTAssertEqual(string.columnNumber(at: string.index(string.startIndex, offsetBy: 3)), 3)
        XCTAssertEqual(string.columnNumber(at: string.index(string.startIndex, offsetBy: 4)), 4)
        XCTAssertEqual(string.columnNumber(at: string.index(string.startIndex, offsetBy: 5)), 0)
        XCTAssertEqual(string.columnNumber(at: string.index(string.startIndex, offsetBy: 6)), 1)
        XCTAssertEqual(string.columnNumber(at: string.index(string.startIndex, offsetBy: 7)), 2)
    }
    
    
    func testCharacterCountOptions() {
        
        var options = CharacterCountOptions()
        
        let string = "aaa \t 🐱\n\r\n c"
        
        XCTAssertEqual(string.count(options: options), string.count)
        options.ignoresNewlines = true
        XCTAssertEqual(string.count(options: options), 9)
        options.ignoresWhitespaces = true
        XCTAssertEqual(string.count(options: options), 5)
        options.ignoresNewlines = false
        options.ignoresWhitespaces = true
        XCTAssertEqual(string.count(options: options), 7)
        
        // test .treatsConsecutiveWhitespaceAsSingle
        options = .init()
        options.treatsConsecutiveWhitespaceAsSingle = true
        XCTAssertEqual(string.count(options: options), 7)
        options.ignoresNewlines = true
        XCTAssertEqual(string.count(options: options), 7)
        options.treatsConsecutiveWhitespaceAsSingle = false
        options.ignoresNewlines = true
        options.ignoresWhitespaces = true
        XCTAssertEqual(string.count(options: options), 5)
        
        // test other units
        options = .init()
        options.unit = .unicodeScalar
        XCTAssertEqual(string.count(options: options), 12)
        options.unit = .utf16
        XCTAssertEqual(string.count(options: options), 13)
        
        // test normailzation
        let aUmlaut = "Ä"
        options = .init()
        options.unit = .unicodeScalar
        XCTAssertEqual(aUmlaut.count(options: options), 2)
        options.normalizationForm = .nfc
        XCTAssertEqual(aUmlaut.count(options: options), 1)
    }
    
    
    func testByteCountOptions() {
        
        let string = "abc犬牛"
        var options = CharacterCountOptions(unit: .byte)
        
        options.encoding = .utf8
        XCTAssertEqual(string.count(options: options), 9)
        
        options.encoding = .shiftJIS
        XCTAssertEqual(string.count(options: options), 7)
        
        options.encoding = .ascii
        XCTAssertNil(string.count(options: options))
        
        options.encoding = .nonLossyASCII
        XCTAssertEqual(string.count(options: options), 15)
    }
    
    
    func testProgrammingCases() {
        
        XCTAssertEqual("AbcDefg Hij".snakecased, "abc_defg hij")
        XCTAssertEqual("abcDefg Hij".snakecased, "abc_defg hij")
        XCTAssertEqual("_abcDefg Hij".snakecased, "_abc_defg hij")
        XCTAssertEqual("AA\u{0308}".snakecased, "a_a\u{0308}")
        XCTAssertEqual("abÄb".snakecased, "ab_äb")
        
        XCTAssertEqual("abc_defg Hij".camelcased, "abcDefg hij")
        XCTAssertEqual("AbcDefg Hij".camelcased, "abcDefg hij")
        XCTAssertEqual("_abcDefg Hij".camelcased, "_abcDefg hij")
        XCTAssertEqual("a_a\u{0308}".camelcased, "aA\u{0308}")
        
        XCTAssertEqual("abc_defg Hij".pascalcased, "AbcDefg Hij")
        XCTAssertEqual("abcDefg Hij".pascalcased, "AbcDefg Hij")
        XCTAssertEqual("_abcDefg Hij".pascalcased, "_abcDefg Hij")
        XCTAssertEqual("a_a\u{0308}".pascalcased, "AA\u{0308}")
    }
    
    
    func testJapaneseTransform() {
        
        let testString = "犬 イヌ いぬ Ｉｎｕ Dog 123 １２３"
        
        XCTAssertEqual(testString.fullwidthRoman(reverse: false), "犬 イヌ いぬ Ｉｎｕ Ｄｏｇ １２３ １２３")
        XCTAssertEqual(testString.fullwidthRoman(reverse: true), "犬 イヌ いぬ Inu Dog 123 123")
    }
    
    
    func testBeforeIndex() {
        
        XCTAssertEqual(("00" as NSString).index(before: 0), 0)
        XCTAssertEqual(("00" as NSString).index(before: 1), 0)
        XCTAssertEqual(("00" as NSString).index(before: 2), 1)
        XCTAssertEqual(("0🇦🇦00" as NSString).index(before: 1), 0)
        XCTAssertEqual(("0🇦🇦00" as NSString).index(before: 2), 1)
        XCTAssertEqual(("0🇦🇦00" as NSString).index(before: 5), 1)
        XCTAssertEqual(("0🇦🇦00" as NSString).index(before: 6), 5)
        
        XCTAssertEqual(("0\r\n0" as NSString).index(before: 3), 1)
        XCTAssertEqual(("0\r\n0" as NSString).index(before: 2), 1)
        XCTAssertEqual(("0\r\n0" as NSString).index(before: 1), 0)
        XCTAssertEqual(("0\n" as NSString).index(before: 1), 0)
        XCTAssertEqual(("0\n" as NSString).index(before: 2), 1)
    }
    
    
    func testAfterIndex() {
        
        XCTAssertEqual(("00" as NSString).index(after: 0), 1)
        XCTAssertEqual(("00" as NSString).index(after: 1), 2)
        XCTAssertEqual(("00" as NSString).index(after: 2), 2)
        XCTAssertEqual(("0🇦🇦0" as NSString).index(after: 0), 1)
        XCTAssertEqual(("0🇦🇦0" as NSString).index(after: 1), 5)
        
        XCTAssertEqual(("0\r\n0" as NSString).index(after: 1), 3)
        XCTAssertEqual(("0\r\n0" as NSString).index(after: 2), 3)
        XCTAssertEqual(("0\r\n0" as NSString).index(after: 3), 4)
        XCTAssertEqual(("0\r" as NSString).index(after: 1), 2)
        XCTAssertEqual(("0\r" as NSString).index(after: 2), 2)
        
        // composed character does not care CRLF
        XCTAssertEqual(("\r\n" as NSString).rangeOfComposedCharacterSequence(at: 1), NSRange(1..<2))
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
    
    
    func testFirstLineEnding() {
        
        XCTAssertEqual("foo\r\nbar".firstLineEnding, "\r\n")
    }
    
    
    func testRangeOfCharacter() {
        
        let set = CharacterSet(charactersIn: "._")
        let string = "abc.d🐕f_ghij" as NSString
        
        XCTAssertEqual(string.substring(with: string.rangeOfCharacter(until: set, at: 0)), "abc")
        XCTAssertEqual(string.substring(with: string.rangeOfCharacter(until: set, at: 4)), "d🐕f")
        XCTAssertEqual(string.substring(with: string.rangeOfCharacter(until: set, at: string.length - 1)), "ghij")
    }
    
    
    func testComposedCharacterSequence() {
        
        let blackDog = "🐕‍⬛"  // 4
        XCTAssertEqual(blackDog.lowerBoundOfComposedCharacterSequence(2, offsetBy: 1), 0)
        
        let abcDog = "🐕‍⬛abc"  // 4 1 1 1
        XCTAssertEqual(abcDog.lowerBoundOfComposedCharacterSequence(6, offsetBy: 1), "🐕‍⬛a".utf16.count)
        XCTAssertEqual(abcDog.lowerBoundOfComposedCharacterSequence(5, offsetBy: 1), "🐕‍⬛".utf16.count)
        
        let dogDog = "🐕‍⬛🐕"  // 4 2
        XCTAssertEqual(dogDog.lowerBoundOfComposedCharacterSequence(5, offsetBy: 1), 0)
        XCTAssertEqual(dogDog.lowerBoundOfComposedCharacterSequence(6, offsetBy: 1), "🐕‍⬛".utf16.count)
        XCTAssertEqual(dogDog.lowerBoundOfComposedCharacterSequence(6, offsetBy: 0), "🐕‍⬛🐕".utf16.count)
        
        let string = "🐕🏴‍☠️🇯🇵🧑‍💻"  // 2 5 4 5
        XCTAssertEqual(string.lowerBoundOfComposedCharacterSequence(9, offsetBy: 3), 0)
        XCTAssertEqual(string.lowerBoundOfComposedCharacterSequence(9, offsetBy: 2), 0)
        XCTAssertEqual(string.lowerBoundOfComposedCharacterSequence(9, offsetBy: 1), "🐕".utf16.count)
        XCTAssertEqual(string.lowerBoundOfComposedCharacterSequence(9, offsetBy: 0), "🐕🏴‍☠️".utf16.count)
        
        let abc = "abc"
        XCTAssertEqual(abc.lowerBoundOfComposedCharacterSequence(1, offsetBy: 2), 0)
        XCTAssertEqual(abc.lowerBoundOfComposedCharacterSequence(1, offsetBy: 1), 0)
        XCTAssertEqual(abc.lowerBoundOfComposedCharacterSequence(1, offsetBy: 0), 1)
    }
    
    
    func testUnicodeNormalization() {
        
        XCTAssertEqual("É \t 神 ㍑ ＡＢC".precomposedStringWithCompatibilityMappingWithCasefold, "é \t 神 リットル abc")
        XCTAssertEqual("\u{1f71} \u{03b1}\u{0301}".precomposedStringWithHFSPlusMapping, "\u{1f71} \u{03ac}")
        XCTAssertEqual("\u{1f71}".precomposedStringWithHFSPlusMapping, "\u{1f71}")  // test single char
        XCTAssertEqual("\u{1f71}".decomposedStringWithHFSPlusMapping, "\u{03b1}\u{0301}")
    }
    
    
    func testWhitespaceTriming() throws {
        
        let string = """
            
            abc def
                \t
            white space -> \t
            abc
            """
        
        let trimmed = try string.trim(ranges: string.rangesOfTrailingWhitespace(ignoresEmptyLines: false))
        let expectedTrimmed = """
            
            abc def
            
            white space ->
            abc
            """
        XCTAssertEqual(trimmed, expectedTrimmed)
        
        let trimmedIgnoringEmptyLines = try string.trim(ranges: string.rangesOfTrailingWhitespace(ignoresEmptyLines: true))
        let expectedTrimmedIgnoringEmptyLines =  """
            
            abc def
                \t
            white space ->
            abc
            """
        XCTAssertEqual(trimmedIgnoringEmptyLines, expectedTrimmedIgnoringEmptyLines)
    }
    
    
    func testAbbreviatedMatch() {
        
        let string = "The fox jumps over the lazy dogcow."
        
        XCTAssertNil(string.abbreviatedMatch(with: "quick"))
        
        XCTAssertEqual(string.abbreviatedMatch(with: "dogcow")?.score, 6)
        XCTAssertEqual(string.abbreviatedMatch(with: "dogcow")?.ranges.count, 6)
        
        XCTAssertEqual(string.abbreviatedMatch(with: "ow")?.score, 29)
        XCTAssertEqual(string.abbreviatedMatch(with: "ow")?.ranges.count, 2)
    }
}



private extension String {
    
    func trim(ranges: [NSRange]) throws -> String {
        
        try ranges.reversed()
            .map { try XCTUnwrap(Range($0, in: self)) }
            .reduce(self) { $0.replacingCharacters(in: $1, with: "") }
    }
}
