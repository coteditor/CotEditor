//
//  StringTransposeTests.swift
//  TextEditingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-07-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import StringUtils
@testable import TextEditing

struct StringTransposeTests {
    
    @Test func transpose() throws {
        
        // swap the characters on either side of the insertion point,
        // and the two preceding ones at the document end
        let context = try #require("abc\ndef".transpose(at: [NSRange(location: 2, length: 0),
                                                             NSRange(location: 7, length: 0)]))
        #expect(context.strings == ["cb", "fe"])
        #expect(context.ranges == [NSRange(location: 1, length: 2), NSRange(location: 5, length: 2)])
        #expect(context.selectedRanges == [NSRange(location: 3, length: 0), NSRange(location: 7, length: 0)])
    }
    
    
    @Test func transposeAtLineEnd() throws {
        
        // at the end of a line, swap the two preceding characters instead of the trailing line ending
        let context = try #require("abc\ndef".transpose(at: [NSRange(location: 3, length: 0),
                                                             NSRange(location: 5, length: 0)]))
        #expect(context.strings == ["cb", "ed"])
        #expect(context.ranges == [NSRange(location: 1, length: 2), NSRange(location: 4, length: 2)])
        #expect(context.selectedRanges == [NSRange(location: 3, length: 0), NSRange(location: 6, length: 0)])
    }
    
    
    @Test func transposeKeepingCRLF() throws {
        
        // keep a CRLF line ending intact at the end of a line
        let context = try #require("ab\r\ncd".transpose(at: [NSRange(location: 2, length: 0),
                                                             NSRange(location: 6, length: 0)]))
        #expect(context.strings == ["ba", "dc"])
        #expect(context.ranges == [NSRange(location: 0, length: 2), NSRange(location: 4, length: 2)])
        #expect(context.selectedRanges == [NSRange(location: 2, length: 0), NSRange(location: 6, length: 0)])
    }
    
    
    @Test func transposeWithNothingToSwap() {
        
        // do nothing at the document start or on an empty line
        let context = "a\n\nb".transpose(at: [NSRange(location: 0, length: 0),
                                              NSRange(location: 2, length: 0)])
        #expect(context == nil)
    }
}
