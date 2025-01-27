//
//  StringExtensionsTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2025 1024jp
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

struct StringExtensionsTests {
    
    @Suite struct Escaping {
        
        @Test func escapeCharacter() {
            
            let string = "a\\a\\\\aa"
            
            #expect(!string.isEscaped(at: 0))
            #expect(string.isEscaped(at: 2))
            #expect(!string.isEscaped(at: 5))
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
    }
    
    
    @Test func fullwidthRoman() {
        
        let testString = "犬 イヌ いぬ Ｉｎｕ Dog 123 １２３"
        
        #expect(testString.fullwidthRoman(reverse: false) == "犬 イヌ いぬ Ｉｎｕ Ｄｏｇ １２３ １２３")
        #expect(testString.fullwidthRoman(reverse: true) == "犬 イヌ いぬ Inu Dog 123 123")
    }
    
    
    @Test func straightenQuotes() {
        
        #expect("I am a “dog.”".straighteningQuotes == "I am a \"dog.\"")
        #expect("I am a ‘dog.’".straighteningQuotes == "I am a 'dog.'")
        #expect("type `echo`".straighteningQuotes == "type `echo`")
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
