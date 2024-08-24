//
//  StringCountingTests.swift
//  StringUtilsTests
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
@testable import StringUtils

struct StringCountingTests {
    
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
}
