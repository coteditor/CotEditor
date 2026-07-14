//
//  StringCharacterTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-07-13.
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
@testable import StringUtils

struct StringCharacterTests {
    
    @Test func characterAroundRange() {
        
        let string = "a🐕b"  // UTF-16: a(0) 🐕(1..<3) b(3)
        
        #expect(string.character(before: NSRange(location: 0, length: 0)) == nil)
        #expect(string.character(before: NSRange(location: 1, length: 0)) == "a")
        #expect(string.character(before: NSRange(location: 3, length: 0)) == "🐕")  // a surrogate pair precedes
        #expect(string.character(before: NSRange(location: 4, length: 0)) == "b")
        
        #expect(string.character(after: NSRange(location: 0, length: 0)) == "a")
        #expect(string.character(after: NSRange(location: 1, length: 0)) == "🐕")  // a surrogate pair follows
        #expect(string.character(after: NSRange(location: 3, length: 0)) == "b")
        #expect(string.character(after: NSRange(location: 4, length: 0)) == nil)
        
        // inspect around the bounds of a non-empty range
        #expect(string.character(before: NSRange(location: 1, length: 2)) == "a")
        #expect(string.character(after: NSRange(location: 1, length: 2)) == "b")
    }
}
