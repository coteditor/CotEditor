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

struct LineRangeTests {
    
    @Test func lineRange() {
        
        let string = "foo\n\rbar\n\r"
        
        #expect(string.lineContentsRange(for: string.startIndex..<string.endIndex) ==
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
}
