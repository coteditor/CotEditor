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
//  © 2015-2024 1024jp
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

import Foundation
import Testing
@testable import CotEditor

struct StringExtensionsTests {
    
    /// Tests if the U+FEFF omitting bug on Swift 5 still exists.
    @Test(.bug("https://bugs.swift.org/browse/SR-10896")) func feff() {
        
        let bom = "\u{feff}"
        
        // -> Some of these test cases must fail if the bug fixed.
        #expect(bom.count == 1)
        #expect(("\(bom)abc").count == 4)
        #expect(NSString(string: bom).length == 0)  // correct: 1
        #expect(NSString(string: "\(bom)\(bom)").length == 1)  // correct: 2
        #expect(NSString(string: "\(bom)abc").length == 3)  // correct: 4
        #expect(NSString(string: "a\(bom)bc").length == 4)
        
        let string = "\(bom)abc"
        #expect(string.immutable != string)  // -> This test must fail if the bug fixed.
        
        // Implicit NSString cast is fixed.
        // -> However, still crashes when `string.immutable.enumerateSubstrings(in:)`
        let middleIndex = string.index(string.startIndex, offsetBy: 2)
        string.enumerateSubstrings(in: middleIndex..<string.endIndex, options: .byLines) { (_, _, _, _) in }
    }
    
    
    @Test func escapeCharacter() {
        
        let string = "a\\a\\\\aa"
        
        #expect(!string.isCharacterEscaped(at: 0))
        #expect(string.isCharacterEscaped(at: 2))
        #expect(!string.isCharacterEscaped(at: 5))
    }
    
    
    @Test func unescape() {
        
        #expect(#"\\"#.unescaped == "\\")
        #expect(#"\'"#.unescaped == "\'")
        #expect(#"\""#.unescaped == "\"")
        #expect(#"a\n   "#.unescaped == "a\n   ")
        #expect(#"a\\n  "#.unescaped == "a\\n  ")
        #expect(#"a\\\n "#.unescaped == "a\\\n ")
        #expect(#"a\\\\n"#.unescaped == "a\\\\n")
        #expect(#"\\\\\t"#.unescaped == "\\\\\t")
        #expect(#"\\foo\\\\\0bar\\"#.unescaped == "\\foo\\\\\u{0}bar\\")
        #expect(#"\\\\\\\\foo"#.unescaped == "\\\\\\\\foo")
        #expect(#"foo: \r\n1"#.unescaped == "foo: \r\n1")
    }
    
    
    @Test func countComposedCharacters() {
        
        // make sure that `String.count` counts characters as I want
        #expect("foo".count == 3)
        #expect("\r\n".count == 1)
        #expect("😀🇯🇵a".count == 3)
        #expect("😀🏻".count == 1)
        #expect("👍🏻".count == 1)
        
        // single regional indicator
        #expect("🇦 ".count == 2)
    }
    
    
    @Test func countWords() {
        
        #expect("Clarus says moof!".numberOfWords == 3)
        #expect("plain-text".numberOfWords == 2)
        #expect("!".numberOfWords == 0)
        #expect("".numberOfWords == 0)
    }
    
    
    @Test func countLines() {
        
        #expect("".numberOfLines == 0)
        #expect("a".numberOfLines == 1)
        #expect("\n".numberOfLines == 1)
        #expect("\n\n".numberOfLines == 2)
        #expect("\u{feff}".numberOfLines == 1)
        #expect("ab\r\ncd".numberOfLines == 2)
        
        let testString = "a\nb c\n\n"
        #expect(testString.numberOfLines == 3)
        #expect(testString.numberOfLines(in: NSRange(0..<0)) == 0)   // ""
        #expect(testString.numberOfLines(in: NSRange(0..<1)) == 1)   // "a"
        #expect(testString.numberOfLines(in: NSRange(0..<2)) == 1)   // "a\n"
        #expect(testString.numberOfLines(in: NSRange(0..<6)) == 2)   // "a\nb c\n"
        #expect(testString.numberOfLines(in: NSRange(0..<7)) == 3)   // "a\nb c\n\n"
        
        #expect(testString.numberOfLines(in: NSRange(0..<0), includesLastBreak: true) == 0)   // ""
        #expect(testString.numberOfLines(in: NSRange(0..<1), includesLastBreak: true) == 1)   // "a"
        #expect(testString.numberOfLines(in: NSRange(0..<2), includesLastBreak: true) == 2)   // "a\n"
        #expect(testString.numberOfLines(in: NSRange(0..<6), includesLastBreak: true) == 3)   // "a\nb c\n"
        #expect(testString.numberOfLines(in: NSRange(0..<7), includesLastBreak: true) == 4)   // "a\nb c\n\n"
        
        #expect(testString.lineNumber(at: 0) == 1)
        #expect(testString.lineNumber(at: 1) == 1)
        #expect(testString.lineNumber(at: 2) == 2)
        #expect(testString.lineNumber(at: 5) == 2)
        #expect(testString.lineNumber(at: 6) == 3)
        #expect(testString.lineNumber(at: 7) == 4)
        
        let nsString = testString as NSString
        #expect(nsString.lineNumber(at: 0) == testString.lineNumber(at: 0))
        #expect(nsString.lineNumber(at: 1) == testString.lineNumber(at: 1))
        #expect(nsString.lineNumber(at: 2) == testString.lineNumber(at: 2))
        #expect(nsString.lineNumber(at: 5) == testString.lineNumber(at: 5))
        #expect(nsString.lineNumber(at: 6) == testString.lineNumber(at: 6))
        #expect(nsString.lineNumber(at: 7) == testString.lineNumber(at: 7))
        
        #expect("\u{FEFF}".numberOfLines(in: NSRange(0..<1)) == 1)  // "\u{FEFF}"
        #expect("\u{FEFF}\nb".numberOfLines(in: NSRange(0..<3)) == 2)  // "\u{FEFF}\nb"
        #expect("a\u{FEFF}\nb".numberOfLines(in: NSRange(1..<4)) == 2)  // "\u{FEFF}\nb"
        #expect("a\u{FEFF}\u{FEFF}\nb".numberOfLines(in: NSRange(1..<5)) == 2)  // "\u{FEFF}\nb"
        
        #expect("a\u{FEFF}\nb".numberOfLines == 2)
        #expect("\u{FEFF}\nb".numberOfLines == 2)
        #expect("\u{FEFF}0000000000000000".numberOfLines == 1)
        
        let bomString = "\u{FEFF}\nb"
        let range = bomString.startIndex..<bomString.index(bomString.startIndex, offsetBy: 2)
        #expect(bomString.numberOfLines(in: [range, range]) == 1)  // "\u{FEFF}\n"
    }
    
    
    @Test func countColumns() {
        
        let string = "aaa \r\n🐱 "
        
        #expect(string.columnNumber(at: string.index(string.startIndex, offsetBy: 3)) == 3)
        #expect(string.columnNumber(at: string.index(string.startIndex, offsetBy: 4)) == 4)
        #expect(string.columnNumber(at: string.index(string.startIndex, offsetBy: 5)) == 0)
        #expect(string.columnNumber(at: string.index(string.startIndex, offsetBy: 6)) == 1)
        #expect(string.columnNumber(at: string.index(string.startIndex, offsetBy: 7)) == 2)
    }
    
    
    @Test func countCharactersWithOptions() {
        
        var options = CharacterCountOptions()
        
        let string = "aaa \t 🐱\n\r\n c"
        
        #expect(string.count(options: options) == string.count)
        options.ignoresNewlines = true
        #expect(string.count(options: options) == 9)
        options.ignoresWhitespaces = true
        #expect(string.count(options: options) == 5)
        options.ignoresNewlines = false
        options.ignoresWhitespaces = true
        #expect(string.count(options: options) == 7)
        
        // test .treatsConsecutiveWhitespaceAsSingle
        options = .init()
        options.treatsConsecutiveWhitespaceAsSingle = true
        #expect(string.count(options: options) == 7)
        options.ignoresNewlines = true
        #expect(string.count(options: options) == 7)
        options.treatsConsecutiveWhitespaceAsSingle = false
        options.ignoresNewlines = true
        options.ignoresWhitespaces = true
        #expect(string.count(options: options) == 5)
        
        // test other units
        options = .init()
        options.unit = .unicodeScalar
        #expect(string.count(options: options) == 12)
        options.unit = .utf16
        #expect(string.count(options: options) == 13)
        
        // test normalization
        let aUmlaut = "Ä"
        options = .init()
        options.unit = .unicodeScalar
        #expect(aUmlaut.count(options: options) == 2)
        options.normalizationForm = .nfc
        #expect(aUmlaut.count(options: options) == 1)
    }
    
    
    @Test func countBytes() {
        
        let string = "abc犬牛"
        var options = CharacterCountOptions(unit: .byte)
        
        options.encoding = .utf8
        #expect(string.count(options: options) == 9)
        
        options.encoding = .shiftJIS
        #expect(string.count(options: options) == 7)
        
        options.encoding = .ascii
        #expect(string.count(options: options) == nil)
        
        options.encoding = .nonLossyASCII
        #expect(string.count(options: options) == 15)
    }
    
    
    @Test func codingCases() {
        
        #expect("AbcDefg Hij".snakecased == "abc_defg hij")
        #expect("abcDefg Hij".snakecased == "abc_defg hij")
        #expect("_abcDefg Hij".snakecased == "_abc_defg hij")
        #expect("AA\u{0308}".snakecased == "a_a\u{0308}")
        #expect("abÄb".snakecased == "ab_äb")
        
        #expect("abc_defg Hij".camelcased == "abcDefg hij")
        #expect("AbcDefg Hij".camelcased == "abcDefg hij")
        #expect("_abcDefg Hij".camelcased == "_abcDefg hij")
        #expect("a_a\u{0308}".camelcased == "aA\u{0308}")
        
        #expect("abc_defg Hij".pascalcased == "AbcDefg Hij")
        #expect("abcDefg Hij".pascalcased == "AbcDefg Hij")
        #expect("_abcDefg Hij".pascalcased == "_abcDefg Hij")
        #expect("a_a\u{0308}".pascalcased == "AA\u{0308}")
    }
    
    
    @Test func japaneseTransform() {
        
        let testString = "犬 イヌ いぬ Ｉｎｕ Dog 123 １２３"
        
        #expect(testString.fullwidthRoman(reverse: false) == "犬 イヌ いぬ Ｉｎｕ Ｄｏｇ １２３ １２３")
        #expect(testString.fullwidthRoman(reverse: true) == "犬 イヌ いぬ Inu Dog 123 123")
    }
    
    
    @Test func beforeIndex() {
        
        #expect(("00" as NSString).index(before: 0) == 0)
        #expect(("00" as NSString).index(before: 1) == 0)
        #expect(("00" as NSString).index(before: 2) == 1)
        #expect(("0🇦🇦00" as NSString).index(before: 1) == 0)
        #expect(("0🇦🇦00" as NSString).index(before: 2) == 1)
        #expect(("0🇦🇦00" as NSString).index(before: 5) == 1)
        #expect(("0🇦🇦00" as NSString).index(before: 6) == 5)
        
        #expect(("0\r\n0" as NSString).index(before: 3) == 1)
        #expect(("0\r\n0" as NSString).index(before: 2) == 1)
        #expect(("0\r\n0" as NSString).index(before: 1) == 0)
        #expect(("0\n" as NSString).index(before: 1) == 0)
        #expect(("0\n" as NSString).index(before: 2) == 1)
    }
    
    
    @Test func afterIndex() {
        
        #expect(("00" as NSString).index(after: 0) == 1)
        #expect(("00" as NSString).index(after: 1) == 2)
        #expect(("00" as NSString).index(after: 2) == 2)
        #expect(("0🇦🇦0" as NSString).index(after: 0) == 1)
        #expect(("0🇦🇦0" as NSString).index(after: 1) == 5)
        
        #expect(("0\r\n0" as NSString).index(after: 1) == 3)
        #expect(("0\r\n0" as NSString).index(after: 2) == 3)
        #expect(("0\r\n0" as NSString).index(after: 3) == 4)
        #expect(("0\r" as NSString).index(after: 1) == 2)
        #expect(("0\r" as NSString).index(after: 2) == 2)
        
        // composed character does not care CRLF
        #expect(("\r\n" as NSString).rangeOfComposedCharacterSequence(at: 1) == NSRange(1..<2))
    }
    
    
    @Test func lineRange() {
        
        let string = "foo\n\rbar\n\r"
        
        #expect(string.lineContentsRange(for: string.startIndex..<string.endIndex)  ==
                string.startIndex..<string.index(before: string.endIndex))
        
        #expect(string.lineRange(at: string.index(after: string.startIndex)) ==
                string.startIndex..<string.index(string.startIndex, offsetBy: 4))
        #expect(string.lineContentsRange(for: string.startIndex..<string.index(after: string.startIndex)) ==
                string.startIndex..<string.index(string.startIndex, offsetBy: 3))
        
        #expect((string as NSString).lineContentsRange(for: NSRange(..<1)) == NSRange(..<3))
        #expect((string as NSString).lineContentsRange(at: 5) == NSRange(5..<8))
        
        let emptyString = ""
        let emptyRange = emptyString.startIndex..<emptyString.endIndex
        
        #expect(emptyString.lineContentsRange(for: emptyRange) == emptyRange)
    }
    
    
    @Test func lineRanges() {
        
        #expect("foo\nbar".lineContentsRanges(for: NSRange(1..<1)) == [NSRange(1..<1)])
        #expect("foo\nbar".lineContentsRanges() == [NSRange(0..<3), NSRange(4..<7)])
        #expect("foo\nbar\n".lineContentsRanges() == [NSRange(0..<3), NSRange(4..<7)])
        #expect("foo\r\nbar".lineContentsRanges() == [NSRange(0..<3), NSRange(5..<8)])
        #expect("foo\r\r\rbar".lineContentsRanges().count == 4)
    }
    
    
    @Test func firstLineEnding() {
        
        #expect("foo\r\nbar".firstLineEnding == "\r\n")
    }
    
    
    @Test func rangeOfCharacter() {
        
        let set = CharacterSet(charactersIn: "._")
        let string = "abc.d🐕f_ghij" as NSString
        
        #expect(string.substring(with: string.rangeOfCharacter(until: set, at: 0)) == "abc")
        #expect(string.substring(with: string.rangeOfCharacter(until: set, at: 4)) == "d🐕f")
        #expect(string.substring(with: string.rangeOfCharacter(until: set, at: string.length - 1)) == "ghij")
    }
    
    
    @Test func composedCharacterSequence() {
        
        let blackDog = "🐕‍⬛"  // 4
        #expect(blackDog.lowerBoundOfComposedCharacterSequence(2, offsetBy: 1) == 0)
        
        let abcDog = "🐕‍⬛abc"  // 4 1 1 1
        #expect(abcDog.lowerBoundOfComposedCharacterSequence(6, offsetBy: 1) == "🐕‍⬛a".utf16.count)
        #expect(abcDog.lowerBoundOfComposedCharacterSequence(5, offsetBy: 1) == "🐕‍⬛".utf16.count)
        
        let dogDog = "🐕‍⬛🐕"  // 4 2
        #expect(dogDog.lowerBoundOfComposedCharacterSequence(5, offsetBy: 1) == 0)
        #expect(dogDog.lowerBoundOfComposedCharacterSequence(6, offsetBy: 1) == "🐕‍⬛".utf16.count)
        #expect(dogDog.lowerBoundOfComposedCharacterSequence(6, offsetBy: 0) == "🐕‍⬛🐕".utf16.count)
        
        let string = "🐕🏴‍☠️🇯🇵🧑‍💻"  // 2 5 4 5
        #expect(string.lowerBoundOfComposedCharacterSequence(9, offsetBy: 3) == 0)
        #expect(string.lowerBoundOfComposedCharacterSequence(9, offsetBy: 2) == 0)
        #expect(string.lowerBoundOfComposedCharacterSequence(9, offsetBy: 1) == "🐕".utf16.count)
        #expect(string.lowerBoundOfComposedCharacterSequence(9, offsetBy: 0) == "🐕🏴‍☠️".utf16.count)
        
        let abc = "abc"
        #expect(abc.lowerBoundOfComposedCharacterSequence(1, offsetBy: 2) == 0)
        #expect(abc.lowerBoundOfComposedCharacterSequence(1, offsetBy: 1) == 0)
        #expect(abc.lowerBoundOfComposedCharacterSequence(1, offsetBy: 0) == 1)
    }
    
    
    @Test func normalizeUnicode() {
        
        #expect("É \t 神 ㍑ ＡＢC".precomposedStringWithCompatibilityMappingWithCasefold == "é \t 神 リットル abc")
        #expect("\u{1f71} \u{03b1}\u{0301}".precomposedStringWithHFSPlusMapping == "\u{1f71} \u{03ac}")
        #expect("\u{1f71}".precomposedStringWithHFSPlusMapping == "\u{1f71}")  // test single char
        #expect("\u{1f71}".decomposedStringWithHFSPlusMapping == "\u{03b1}\u{0301}")
    }
    
    
    @Test func trimWhitespace() throws {
        
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
        #expect(trimmed == expectedTrimmed)
        
        let trimmedIgnoringEmptyLines = try string.trim(ranges: string.rangesOfTrailingWhitespace(ignoresEmptyLines: true))
        let expectedTrimmedIgnoringEmptyLines =  """
            
            abc def
                \t
            white space ->
            abc
            """
        #expect(trimmedIgnoringEmptyLines == expectedTrimmedIgnoringEmptyLines)
    }
    
    
    @Test func abbreviatedMatch() throws {
        
        let string = "The fox jumps over the lazy dogcow."
        
        #expect(string.abbreviatedMatch(with: "quick") == nil)
        
        let dogcow = try #require(string.abbreviatedMatch(with: "dogcow"))
        #expect(dogcow.score == 6)
        #expect(dogcow.ranges.count == 6)
        #expect(dogcow.remaining.isEmpty)
        
        let ow = try #require(string.abbreviatedMatch(with: "ow"))
        #expect(ow.score == 29)
        #expect(ow.ranges.count == 2)
        #expect(ow.remaining.isEmpty)
        
        let lazyTanuki = try #require(string.abbreviatedMatch(with: "lazy tanuki"))
        #expect(lazyTanuki.score == 5)
        #expect(lazyTanuki.ranges.count == 5)
        #expect(lazyTanuki.remaining == "tanuki")
        
        #expect(string.abbreviatedMatchedRanges(with: "lazy tanuki") == nil)
        #expect(string.abbreviatedMatchedRanges(with: "lazy tanuki", incomplete: true)?.count == 5)
        
        #expect(string.abbreviatedMatchedRanges(with: "lazy w")?.count == 6)
        #expect(string.abbreviatedMatchedRanges(with: "lazy w", incomplete: true)?.count == 6)
    }
}



private extension String {
    
    func trim(ranges: [NSRange]) throws -> String {
        
        try ranges.reversed()
            .map { try #require(Range($0, in: self)) }
            .reduce(self) { $0.replacingCharacters(in: $1, with: "") }
    }
}
