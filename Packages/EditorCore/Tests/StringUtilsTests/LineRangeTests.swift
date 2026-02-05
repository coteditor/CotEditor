//
//  LineRangeTests.swift
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

struct LineRangeTests {
    
    @Test func lineRangeAtIndex() {
        
        let string = "foo\n\rbar\n\r"
        
        #expect(string.lineRange(at: string.index(after: string.startIndex)) ==
                string.startIndex..<string.index(string.startIndex, offsetBy: 4))
    }
    
    
    @Test func lineContentsRangeForRange() {
        
        let string = "foo\n\rbar\n\r"
        let fullRange = string.startIndex..<string.endIndex
        
        #expect(string.lineContentsRange(for: fullRange) ==
                string.startIndex..<string.index(before: string.endIndex))
        #expect(string.lineContentsRange(for: string.startIndex..<string.index(after: string.startIndex)) ==
                string.startIndex..<string.index(string.startIndex, offsetBy: 3))
        
        let emptyString = ""
        let emptyRange = emptyString.startIndex..<emptyString.endIndex
        
        #expect(emptyString.lineContentsRange(for: emptyRange) == emptyRange)
    }
    
    
    @Test func lineContentsRangeAtIndex() {
        
        let string = "foo\nbar\r\nbaz"
        
        #expect(string.lineContentsRange(at: string.startIndex) == string.range(of: "foo"))
        #expect(string.lineContentsRange(at: string.index(string.startIndex, offsetBy: 4)) == string.range(of: "bar"))
        #expect(string.lineContentsRange(at: string.index(string.startIndex, offsetBy: 9)) == string.range(of: "baz"))
    }
    
    
    @Test func lineStartAndContentsEndIndex() {
        
        let string = "foo\nbar\r\nbaz"
        let barIndex = string.index(string.startIndex, offsetBy: 6)
        let lineEndingIndex = string.index(string.startIndex, offsetBy: 3)
        
        #expect(string.lineStartIndex(at: barIndex) == string.index(string.startIndex, offsetBy: 4))
        #expect(string.lineContentsEndIndex(at: barIndex) == string.index(string.startIndex, offsetBy: 7))
        #expect(string.lineStartIndex(at: lineEndingIndex) == string.startIndex)
        #expect(string.lineContentsEndIndex(at: lineEndingIndex) == string.index(string.startIndex, offsetBy: 3))
    }
    
    
    @Test func lineContentsRanges() {
        
        #expect("foo\nbar".lineContentsRanges() == [NSRange(0..<3), NSRange(4..<7)])
        #expect("foo\nbar\n".lineContentsRanges() == [NSRange(0..<3), NSRange(4..<7)])
        #expect("foo\r\nbar".lineContentsRanges() == [NSRange(0..<3), NSRange(5..<8)])
        #expect("foo\r\r\rbar".lineContentsRanges().count == 4)
    }
    
    
    @Test func lineContentsRangesForRange() {
        
        #expect("foo\nbar".lineContentsRanges(for: NSRange(1..<1)) == [NSRange(1..<1)])
        
        let string = "foo\nbar\nbaz"
        let range = NSRange(1..<8)  // "oo\nbar\n"
        
        #expect(string.lineContentsRanges(for: range) == [NSRange(1..<3), NSRange(4..<7)])
    }
    
    
    @Test func firstLineEnding() {
        
        #expect("foo\r\nbar".firstLineEnding == "\r\n")
        #expect("foo".firstLineEnding == nil)
        #expect("".firstLineEnding == nil)
    }
    
    
    @Test func nsStringLineRangeAtLocation() {
        
        let string = "foo\nbar\r\nbaz" as NSString
        
        #expect(string.lineRange(at: 0) == NSRange(0..<4))
        #expect(string.lineRange(at: 4) == NSRange(4..<9))
        #expect(string.lineContentsRange(at: 4) == NSRange(4..<7))
    }
    
    
    @Test func nsStringLineIndexes() {
        
        let string = "foo\nbar\r\nbaz" as NSString
        
        #expect(string.lineStartIndex(at: 6) == 4)
        #expect(string.lineContentsEndIndex(at: 6) == 7)
        #expect(string.lineStartIndex(at: 8) == 4)
        #expect(string.lineContentsEndIndex(at: 8) == 7)
    }
}
