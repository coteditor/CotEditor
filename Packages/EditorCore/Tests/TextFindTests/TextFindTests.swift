//
//  TextFindTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-03.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2024 1024jp
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
@testable import TextFind

struct TextFindTests {
    
    @Test func countCaptureGroup() throws {
        
        var mode: TextFind.Mode
        var textFind: TextFind
        
        mode = .regularExpression(options: [], unescapesReplacement: false)
        
        textFind = try TextFind(for: "", findString: "a", mode: mode)
        #expect(textFind.numberOfCaptureGroups == 0)
        
        textFind = try TextFind(for: "", findString: "(?!=a)(b)(c)(?=d)", mode: mode)
        #expect(textFind.numberOfCaptureGroups == 2)
        
        mode = .textual(options: [], fullWord: false)
        textFind = try TextFind(for: "", findString: "(?!=a)(b)(c)(?=d)", mode: mode)
        #expect(textFind.numberOfCaptureGroups == 0)
    }
    
    
    @Test func singleFind() throws {
        
        let text = "abcdefg abcdefg ABCDEFG"
        let findString = "abc"
        
        var textFind: TextFind
        var result: (range: NSRange, wrapped: Bool)
        var matches: [NSRange]
        
        textFind = try TextFind(for: text, findString: findString, mode: .textual(options: [], fullWord: false))
        matches = try textFind.matches
        
        result = try #require(textFind.find(in: matches, forward: true, wraps: false))
        #expect(matches.count == 2)
        #expect(result.range == NSRange(location: 0, length: 3))
        #expect(!result.wrapped)
        
        #expect(textFind.find(in: matches, forward: false, wraps: false) == nil)
        
        
        textFind = try TextFind(for: text, findString: findString, mode: .textual(options: [], fullWord: false), selectedRanges: [NSRange(location: 1, length: 0)])
        
        matches = try textFind.matches
        #expect(matches.count == 2)
        
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(result.range == NSRange(location: 8, length: 3))
        #expect(!result.wrapped)
        
        result = try #require(textFind.find(in: matches, forward: false, wraps: true))
        #expect(result.range == NSRange(location: 8, length: 3))
        #expect(result.wrapped)
        
        
        textFind = try TextFind(for: text, findString: findString, mode: .textual(options: .caseInsensitive, fullWord: false), selectedRanges: [NSRange(location: 1, length: 0)])
        
        matches = try textFind.matches
        #expect(matches.count == 3)
        
        result = try #require(textFind.find(in: matches, forward: false, wraps: true))
        #expect(result.range == NSRange(location: 16, length: 3))
        #expect(result.wrapped)
    }
    
    
    @Test func fullWord() throws {
        
        var textFind: TextFind
        var result: (range: NSRange, wrapped: Bool)
        var matches: [NSRange]
        
        textFind = try TextFind(for: "apples apple Apple", findString: "apple",
                                mode: .textual(options: .caseInsensitive, fullWord: true))
        matches = try textFind.matches
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(matches.count == 2)
        #expect(result.range == NSRange(location: 7, length: 5))
        
        textFind = try TextFind(for: "apples apple Apple", findString: "apple",
                                mode: .textual(options: [.caseInsensitive, .literal], fullWord: true))
        matches = try textFind.matches
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(matches.count == 2)
        #expect(result.range == NSRange(location: 7, length: 5))
        
        textFind = try TextFind(for: "Apfel Äpfel Äpfelchen", findString: "Äpfel",
                                mode: .textual(options: .diacriticInsensitive, fullWord: true))
        matches = try textFind.matches
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(matches.count == 2)
        #expect(result.range == NSRange(location: 0, length: 5))
        
        textFind = try TextFind(for: "イヌら ｲﾇ イヌ", findString: "イヌ",
                                mode: .textual(options: .widthInsensitive, fullWord: true))
        matches = try textFind.matches
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(matches.count == 2)
        #expect(result.range == NSRange(location: 4, length: 2))
    }
    
    
    @Test func unescapedRegexFind() throws {
        
        let mode: TextFind.Mode = .regularExpression(options: .caseInsensitive, unescapesReplacement: true)
        let textFind = try TextFind(for: "1", findString: "1", mode: mode, selectedRanges: [NSRange(0..<1)])
        let replacementResult = try #require(textFind.replace(with: #"foo：\n1"#))
        #expect(replacementResult.value == "foo：\n1")
    }
    
    
    @Test func findAndReplaceSingleRegex() throws {
        
        let findString = "(?!=a)b(c)(?=d)"
        let mode: TextFind.Mode = .regularExpression(options: .caseInsensitive, unescapesReplacement: true)
        
        var textFind: TextFind
        var result: (range: NSRange, wrapped: Bool)
        var matches: [NSRange]
        
        
        textFind = try TextFind(for: "abcdefg abcdefg ABCDEFG", findString: findString, mode: mode, selectedRanges: [NSRange(location: 1, length: 1)])
        
        matches = try textFind.matches
        #expect(matches.count == 3)
        
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(result.range == NSRange(location: 9, length: 2))
        #expect(!result.wrapped)
        
        result = try #require(textFind.find(in: matches, forward: false, wraps: true))
        #expect(result.range == NSRange(location: 17, length: 2))
        #expect(result.wrapped)
        
        
        textFind = try TextFind(for: "ABCDEFG", findString: findString, mode: mode, selectedRanges: [NSRange(location: 1, length: 1)])
        
        matches = try textFind.matches
        #expect(matches.count == 1)
        
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(result.range == NSRange(location: 1, length: 2))
        #expect(result.wrapped)
        
        result = try #require(textFind.find(in: matches, forward: false, wraps: true))
        #expect(result.range == NSRange(location: 1, length: 2))
        #expect(result.wrapped)
        
        #expect(textFind.replace(with: "$1") == nil)
        
        
        textFind = try TextFind(for: "ABCDEFG", findString: findString, mode: mode, selectedRanges: [NSRange(location: 1, length: 2)])
        
        let replacementResult = try #require(textFind.replace(with: "$1\\t"))
        #expect(replacementResult.value == "C\t")
        #expect(replacementResult.range == NSRange(location: 1, length: 2))
    }
    
    
    @Test func findAll() throws {
        
        let mode: TextFind.Mode = .regularExpression(options: .caseInsensitive, unescapesReplacement: false)
        var textFind: TextFind
        
        textFind = try TextFind(for: "abcdefg ABCDEFG", findString: "(?!=a)b(c)(?=d)", mode: mode)
        
        var matches = [[NSRange]]()
        textFind.findAll { (matchedRanges, _) in
            matches.append(matchedRanges)
        }
        #expect(matches.count == 2)
        #expect(matches[0].count == 2)
        #expect(matches[0][0] == NSRange(location: 1, length: 2))
        #expect(matches[0][1] == NSRange(location: 2, length: 1))
        #expect(matches[1].count == 2)
        #expect(matches[1][0] == NSRange(location: 9, length: 2))
        #expect(matches[1][1] == NSRange(location: 10, length: 1))
        
        
        textFind = try TextFind(for: "abcdefg ABCDEFG", findString: "ab", mode: mode)
        
        matches = [[NSRange]]()
        textFind.findAll { (matchedRanges, _) in
            matches.append(matchedRanges)
        }
        #expect(matches.count == 2)
        #expect(matches[0].count == 1)
        #expect(matches[0][0] == NSRange(location: 0, length: 2))
        #expect(matches[1].count == 1)
        #expect(matches[1][0] == NSRange(location: 8, length: 2))
    }
    
    
    @Test func replaceAll() throws {
        
        var textFind: TextFind
        var replacementItems: [TextFind.ReplacementItem]
        var selectedRanges: [NSRange]?
        
        textFind = try TextFind(for: "abcdefg ABCDEFG", findString: "(?!=a)b(c)(?=d)",
                                mode: .regularExpression(options: .caseInsensitive, unescapesReplacement: false))
        
        (replacementItems, selectedRanges) = textFind.replaceAll(with: "$1\\\\t") { (_, _, _) in }
        #expect(replacementItems.count == 1)
        #expect(replacementItems[0].value == "ac\\tdefg AC\\tDEFG")
        #expect(replacementItems[0].range == NSRange(location: 0, length: 15))
        #expect(selectedRanges == nil)
        
        
        textFind = try TextFind(for: "abcdefg abcdefg abcdefg", findString: "abc",
                                mode: .regularExpression(options: [], unescapesReplacement: false),
                                inSelection: true,
                                selectedRanges: [NSRange(location: 1, length: 14),
                                                 NSRange(location: 16, length: 7)])
        
        (replacementItems, selectedRanges) = textFind.replaceAll(with: "_") { (_, _, _) in }
        #expect(replacementItems.count == 2)
        #expect(replacementItems[0].value == "bcdefg _defg")
        #expect(replacementItems[0].range == NSRange(location: 1, length: 14))
        #expect(replacementItems[1].value == "_defg")
        #expect(replacementItems[1].range == NSRange(location: 16, length: 7))
        #expect(selectedRanges?[0] == NSRange(location: 1, length: 12))
        #expect(selectedRanges?[1] == NSRange(location: 14, length: 5))
    }
}
