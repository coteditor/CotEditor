//
//  NSStringTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2026 1024jp
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
@testable import StringUtils

struct NSStringTests {
    
    /// Tests if the U+FEFF omitting bug on Swift 5 still exists.
    @Test(.bug("https://bugs.swift.org/browse/SR-10896"))
    func immutable() {
        
        #expect("abc".immutable == "abc")
        
        let bom = "\u{feff}"
        let string = "\(bom)abc"
        withKnownIssue {
            #expect(string.immutable == string)
        }
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
    
    
    @Test func safeEndingRange() {
        
        let crlf = "ba\r\n" as NSString
        // empty ranges
        #expect(crlf.safeEndingRange(for: NSRange(2..<2)) == NSRange(2..<2))
        #expect(crlf.safeEndingRange(for: NSRange(3..<3)) == NSRange(2..<2))
        // one length ranges
        #expect(crlf.safeEndingRange(for: NSRange(1..<2)) == NSRange(1..<2))
        #expect(crlf.safeEndingRange(for: NSRange(1..<3)) == NSRange(1..<2))
        #expect(crlf.safeEndingRange(for: NSRange(1..<4)) == NSRange(1..<4))
        #expect(crlf.safeEndingRange(for: NSRange(1..<5)) == NSRange(1..<5))
        #expect(crlf.safeEndingRange(for: NSRange(2..<2)) == NSRange(2..<2))
        #expect(crlf.safeEndingRange(for: NSRange(2..<3)) == NSRange(2..<2))
        #expect(crlf.safeEndingRange(for: NSRange(2..<4)) == NSRange(2..<4))
        #expect(crlf.safeEndingRange(for: .notFound) == .notFound)
        
        let cr = "a\ra" as NSString
        #expect(cr.safeEndingRange(for: NSRange(0..<1)) == NSRange(0..<1))
        #expect(cr.safeEndingRange(for: NSRange(0..<2)) == NSRange(0..<2))
        #expect(cr.safeEndingRange(for: NSRange(0..<3)) == NSRange(0..<3))
        
        let lf = "a\na" as NSString
        #expect(lf.safeEndingRange(for: NSRange(0..<1)) == NSRange(0..<1))
        #expect(lf.safeEndingRange(for: NSRange(0..<2)) == NSRange(0..<2))
        #expect(lf.safeEndingRange(for: NSRange(0..<3)) == NSRange(0..<3))
        
        let empty = "" as NSString
        #expect(empty.safeEndingRange(for: NSRange(0..<0)) == NSRange(0..<0))
        #expect(empty.safeEndingRange(for: NSRange(0..<1)) == NSRange(0..<1))
        
        #expect("\r\n".safeEndingRange(for: NSRange(0..<1)) == NSRange(0..<0))
        #expect("\r\n".safeEndingRange(for: NSRange(1..<2)) == NSRange(1..<2))
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
    
    
    @Test func nsRangeAndLength() {
        
        let string = "a🐕"
        #expect(string.length == string.utf16.count)
        #expect(string.nsRange == NSRange(location: 0, length: string.utf16.count))
        
        let substring = string.dropFirst()
        #expect(substring.length == substring.utf16.count)
        #expect(substring.nsRange == NSRange(location: 0, length: substring.utf16.count))
    }
    
    
    @Test func nsStringRange() {
        
        let string = "abc" as NSString
        #expect(string.range == NSRange(0..<3))
    }
    
    
    @Test func rangesOfString() {
        
        let string = "ababa" as NSString
        #expect(string.ranges(of: "aba") == [NSRange(0..<3)])
        
        let string2 = "aAaA" as NSString
        #expect(string2.ranges(of: "aa", options: .caseInsensitive) == [NSRange(0..<2), NSRange(2..<4)])
        #expect(string2.ranges(of: "aa", options: .caseInsensitive, range: NSRange(1..<4)) == [NSRange(1..<3)])
    }
    
    
    @Test func nsStringLineRanges() {
        
        let string = "aa\nbb\ncc\n" as NSString
        let ranges = [NSRange(location: 1, length: 5),
                      NSRange(location: 3, length: 2)]
        
        #expect(string.lineRanges(for: ranges) == [NSRange(0..<3), NSRange(3..<6)])
    }
    
    
    @Test(arguments: [0x000A, 0x000B, 0x000C, 0x000D, 0x0085, 0x2028, 0x2029])
    func unicharIsNewline(char: UInt16) throws {
        
        let scalar = try #require(Unicode.Scalar(char))
        
        #expect(unichar(char).isNewline)
        #expect(Character(scalar).isNewline)
    }
}
