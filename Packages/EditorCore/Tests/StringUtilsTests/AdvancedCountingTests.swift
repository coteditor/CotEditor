//
//  AdvancedCountingTests.swift
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

struct AdvancedCountingTests {
    
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
}
