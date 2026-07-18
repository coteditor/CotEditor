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
//  © 2017-2026 1024jp
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
import ValueRange
import Testing
@testable import TextFind

struct TextFindTests {
    
    @Test func selectionInitializationError() throws {
        
        let pattern = try TextFind.Pattern(findString: "a", mode: .textual(options: [], fullWord: false))
        #expect(throws: TextFind.Error.emptyInSelectionSearch) {
            try TextFind(for: "abc", pattern: pattern, inSelection: true, selectedRanges: [NSRange()])
        }
    }
    
    
    @Test func patternInitializationErrors() {
        
        #expect(throws: TextFind.Error.emptyFindString) {
            try TextFind.Pattern(findString: "", mode: .textual(options: [], fullWord: false))
        }
        
        let regexError = #expect(throws: TextFind.Error.self) {
            try TextFind.Pattern(findString: "[", mode: .regularExpression(options: [], unescapesReplacement: false))
        }
        if case .regularExpression(let reason) = regexError {
            #expect(!reason.isEmpty)
        } else {
            Issue.record()
        }
    }
    
    
    @Test func reusePattern() throws {
        
        let mode = TextFind.Mode.regularExpression(options: [], unescapesReplacement: false)
        let pattern = try TextFind.Pattern(findString: #"item-\d+"#, mode: mode)
        let firstTextFind = TextFind(for: "item-1 item-x", pattern: pattern)
        let secondTextFind = TextFind(for: "item-22", pattern: pattern)
        
        #expect(firstTextFind.findString == pattern.findString)
        #expect(firstTextFind.mode == pattern.mode)
        #expect(try firstTextFind.matches == [NSRange(location: 0, length: 6)])
        #expect(try secondTextFind.matches == [NSRange(location: 0, length: 7)])
    }
    
    
    @Test func scopeRangeInSelection() throws {
        
        let pattern = try TextFind.Pattern(findString: "a", mode: .textual(options: [], fullWord: false))
        let textFind = try TextFind(for: "abcdef", pattern: pattern,
                                    inSelection: true,
                                    selectedRanges: [NSRange(location: 1, length: 2),
                                                     NSRange(location: 4, length: 1)])
        
        #expect(textFind.scopeRange == 1..<5)
    }
    
    
    @Test func findIncludingSelection() throws {
        
        let pattern = try TextFind.Pattern(findString: "abc", mode: .textual(options: [], fullWord: false))
        let textFind = try TextFind(for: "abc abc", pattern: pattern,
                                    selectedRanges: [NSRange(location: 0, length: 3)])
        
        let matches = try textFind.matches
        let included = try #require(textFind.find(in: matches, forward: true, includingSelection: true, wraps: false))
        #expect(included.range == NSRange(location: 0, length: 3))
        
        let excluded = try #require(textFind.find(in: matches, forward: true, includingSelection: false, wraps: false))
        #expect(excluded.range == NSRange(location: 4, length: 3))
    }
    
    
    @Test func findZeroLengthMatch() throws {
        
        let mode: TextFind.Mode = .regularExpression(options: [], unescapesReplacement: false)
        let pattern = try TextFind.Pattern(findString: "(?=a)", mode: mode)
        let matches = try TextFind(for: "aa", pattern: pattern).matches
        
        #expect(matches == [NSRange(location: 0, length: 0), NSRange(location: 1, length: 0)])
        
        var textFind = try TextFind(for: "aa", pattern: pattern,
                                    selectedRanges: [NSRange(location: 0, length: 0)])
        
        let included = try #require(textFind.find(in: matches, forward: true, includingSelection: true, wraps: false))
        #expect(included.range == NSRange(location: 0, length: 0))
        
        let next = try #require(textFind.find(in: matches, forward: true, wraps: false))
        #expect(next.range == NSRange(location: 1, length: 0))
        
        let wrappedPrevious = try #require(textFind.find(in: matches, forward: false, wraps: true))
        #expect(wrappedPrevious.range == NSRange(location: 1, length: 0))
        #expect(wrappedPrevious.wrapped)
        
        textFind = try TextFind(for: "aa", pattern: pattern,
                                selectedRanges: [NSRange(location: 1, length: 0)])
        
        let previous = try #require(textFind.find(in: matches, forward: false, wraps: false))
        #expect(previous.range == NSRange(location: 0, length: 0))
        
        let wrappedNext = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(wrappedNext.range == NSRange(location: 0, length: 0))
        #expect(wrappedNext.wrapped)
    }
    
    
    @Test func matchesCancellation() async throws {
        
        let string = "aa aa"
        let pattern = try TextFind.Pattern(findString: "a", mode: .textual(options: [], fullWord: false))
        let textFind = TextFind(for: string, pattern: pattern)
        
        let task = Task {
            while !Task.isCancelled {
                await Task.yield()
            }
            
            _ = try textFind.matches
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) { try await task.value }
    }
    
    
    @Test func countCaptureGroup() throws {
        
        let mode = TextFind.Mode.regularExpression(options: [], unescapesReplacement: false)
        var pattern: TextFind.Pattern
        var textFind: TextFind
        
        pattern = try TextFind.Pattern(findString: "a", mode: mode)
        textFind = TextFind(for: "", pattern: pattern)
        #expect(textFind.numberOfCaptureGroups == 0)
        
        pattern = try TextFind.Pattern(findString: "(?!=a)(b)(c)(?=d)", mode: mode)
        textFind = TextFind(for: "", pattern: pattern)
        #expect(textFind.numberOfCaptureGroups == 2)
        
        pattern = try TextFind.Pattern(findString: "(?!=a)(b)(c)(?=d)", mode: .textual(options: [], fullWord: false))
        textFind = TextFind(for: "", pattern: pattern)
        #expect(textFind.numberOfCaptureGroups == 0)
    }
    
    
    @Test func singleFind() throws {
        
        let text = "abcdefg abcdefg ABCDEFG"
        let findString = "abc"
        let pattern = try TextFind.Pattern(findString: findString, mode: .textual(options: [], fullWord: false))
        
        var textFind: TextFind
        var result: (range: NSRange, wrapped: Bool)
        var matches: [NSRange]
        
        textFind = TextFind(for: text, pattern: pattern)
        matches = try textFind.matches
        
        result = try #require(textFind.find(in: matches, forward: true, wraps: false))
        #expect(matches.count == 2)
        #expect(result.range == NSRange(location: 0, length: 3))
        #expect(!result.wrapped)
        
        #expect(textFind.find(in: matches, forward: false, wraps: false) == nil)
        
        
        textFind = try TextFind(for: text, pattern: pattern, selectedRanges: [NSRange(location: 1, length: 0)])
        
        matches = try textFind.matches
        #expect(matches.count == 2)
        
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(result.range == NSRange(location: 8, length: 3))
        #expect(!result.wrapped)
        
        result = try #require(textFind.find(in: matches, forward: false, wraps: true))
        #expect(result.range == NSRange(location: 8, length: 3))
        #expect(result.wrapped)
        
        
        let caseInsensitivePattern = try TextFind.Pattern(findString: findString, mode: .textual(options: .caseInsensitive, fullWord: false))
        textFind = try TextFind(for: text, pattern: caseInsensitivePattern, selectedRanges: [NSRange(location: 1, length: 0)])
        
        matches = try textFind.matches
        #expect(matches.count == 3)
        
        result = try #require(textFind.find(in: matches, forward: false, wraps: true))
        #expect(result.range == NSRange(location: 16, length: 3))
        #expect(result.wrapped)
    }
    
    
    @Test func fullWord() throws {
        
        var pattern: TextFind.Pattern
        var textFind: TextFind
        var result: (range: NSRange, wrapped: Bool)
        var matches: [NSRange]
        
        pattern = try TextFind.Pattern(findString: "apple", mode: .textual(options: .caseInsensitive, fullWord: true))
        textFind = TextFind(for: "apples apple Apple", pattern: pattern)
        matches = try textFind.matches
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(matches.count == 2)
        #expect(result.range == NSRange(location: 7, length: 5))
        
        pattern = try TextFind.Pattern(findString: "apple", mode: .textual(options: [.caseInsensitive, .literal], fullWord: true))
        textFind = TextFind(for: "apples apple Apple", pattern: pattern)
        matches = try textFind.matches
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(matches.count == 2)
        #expect(result.range == NSRange(location: 7, length: 5))
        
        pattern = try TextFind.Pattern(findString: "Äpfel", mode: .textual(options: .diacriticInsensitive, fullWord: true))
        textFind = TextFind(for: "Apfel Äpfel Äpfelchen", pattern: pattern)
        matches = try textFind.matches
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(matches.count == 2)
        #expect(result.range == NSRange(location: 0, length: 5))
        
        pattern = try TextFind.Pattern(findString: "イヌ", mode: .textual(options: .widthInsensitive, fullWord: true))
        textFind = TextFind(for: "イヌら ｲﾇ イヌ", pattern: pattern)
        matches = try textFind.matches
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(matches.count == 2)
        #expect(result.range == NSRange(location: 4, length: 2))
    }
    
    
    @Test func unescapedRegexFind() throws {
        
        let mode: TextFind.Mode = .regularExpression(options: .caseInsensitive, unescapesReplacement: true)
        let pattern = try TextFind.Pattern(findString: "1", mode: mode)
        let textFind = try TextFind(for: "1", pattern: pattern, selectedRanges: [NSRange(0..<1)])
        let replacementResult = try #require(textFind.replace(with: #"foo：\n1"#))
        #expect(replacementResult.value == "foo：\n1")
    }
    
    
    @Test func findAndReplaceSingleRegex() throws {
        
        let findString = "(?!=a)b(c)(?=d)"
        let mode: TextFind.Mode = .regularExpression(options: .caseInsensitive, unescapesReplacement: true)
        let pattern = try TextFind.Pattern(findString: findString, mode: mode)
        
        var textFind: TextFind
        var result: (range: NSRange, wrapped: Bool)
        var matches: [NSRange]
        
        
        textFind = try TextFind(for: "abcdefg abcdefg ABCDEFG", pattern: pattern, selectedRanges: [NSRange(location: 1, length: 1)])
        
        matches = try textFind.matches
        #expect(matches.count == 3)
        
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(result.range == NSRange(location: 9, length: 2))
        #expect(!result.wrapped)
        
        result = try #require(textFind.find(in: matches, forward: false, wraps: true))
        #expect(result.range == NSRange(location: 17, length: 2))
        #expect(result.wrapped)
        
        
        textFind = try TextFind(for: "ABCDEFG", pattern: pattern, selectedRanges: [NSRange(location: 1, length: 1)])
        
        matches = try textFind.matches
        #expect(matches.count == 1)
        
        result = try #require(textFind.find(in: matches, forward: true, wraps: true))
        #expect(result.range == NSRange(location: 1, length: 2))
        #expect(result.wrapped)
        
        result = try #require(textFind.find(in: matches, forward: false, wraps: true))
        #expect(result.range == NSRange(location: 1, length: 2))
        #expect(result.wrapped)
        
        #expect(textFind.replace(with: "$1") == nil)
        
        
        textFind = try TextFind(for: "ABCDEFG", pattern: pattern, selectedRanges: [NSRange(location: 1, length: 2)])
        
        let replacementResult = try #require(textFind.replace(with: "$1\\t"))
        #expect(replacementResult.value == "C\t")
        #expect(replacementResult.range == NSRange(location: 1, length: 2))
    }
    
    
    @Test func findAll() throws {
        
        let mode: TextFind.Mode = .regularExpression(options: .caseInsensitive, unescapesReplacement: false)
        var pattern: TextFind.Pattern
        var textFind: TextFind
        
        pattern = try TextFind.Pattern(findString: "(?!=a)b(c)(?=d)", mode: mode)
        textFind = TextFind(for: "abcdefg ABCDEFG", pattern: pattern)
        
        var matches = [[NSRange]]()
        textFind.findAll { matchedRanges, _ in
            matches.append(matchedRanges)
        }
        #expect(matches.count == 2)
        #expect(matches[0].count == 2)
        #expect(matches[0][0] == NSRange(location: 1, length: 2))
        #expect(matches[0][1] == NSRange(location: 2, length: 1))
        #expect(matches[1].count == 2)
        #expect(matches[1][0] == NSRange(location: 9, length: 2))
        #expect(matches[1][1] == NSRange(location: 10, length: 1))
        
        
        pattern = try TextFind.Pattern(findString: "ab", mode: mode)
        textFind = TextFind(for: "abcdefg ABCDEFG", pattern: pattern)
        
        matches = [[NSRange]]()
        textFind.findAll { matchedRanges, _ in
            matches.append(matchedRanges)
        }
        #expect(matches.count == 2)
        #expect(matches[0].count == 1)
        #expect(matches[0][0] == NSRange(location: 0, length: 2))
        #expect(matches[1].count == 1)
        #expect(matches[1][0] == NSRange(location: 8, length: 2))
    }
    
    
    @Test func replaceAll() throws {
        
        var pattern: TextFind.Pattern
        var textFind: TextFind
        var replacementItems: [TextFind.ReplacementItem]
        var selectedRanges: [NSRange]?
        
        pattern = try TextFind.Pattern(findString: "(?!=a)b(c)(?=d)",
                                       mode: .regularExpression(options: .caseInsensitive, unescapesReplacement: false))
        textFind = TextFind(for: "abcdefg ABCDEFG", pattern: pattern)
        
        (replacementItems, selectedRanges) = textFind.replaceAll(with: "$1\\\\t") { _, _, _ in }
        #expect(replacementItems.count == 1)
        #expect(replacementItems[0].value == "ac\\tdefg AC\\tDEFG")
        #expect(replacementItems[0].range == NSRange(location: 0, length: 15))
        #expect(selectedRanges == nil)
        
        
        pattern = try TextFind.Pattern(findString: "abc", mode: .regularExpression(options: [], unescapesReplacement: false))
        textFind = try TextFind(for: "abcdefg abcdefg abcdefg", pattern: pattern,
                                inSelection: true,
                                selectedRanges: [NSRange(location: 1, length: 14),
                                                 NSRange(location: 16, length: 7)])
        
        (replacementItems, selectedRanges) = textFind.replaceAll(with: "_") { _, _, _ in }
        #expect(replacementItems.count == 2)
        #expect(replacementItems[0].value == "bcdefg _defg")
        #expect(replacementItems[0].range == NSRange(location: 1, length: 14))
        #expect(replacementItems[1].value == "_defg")
        #expect(replacementItems[1].range == NSRange(location: 16, length: 7))
        #expect(selectedRanges?[0] == NSRange(location: 1, length: 12))
        #expect(selectedRanges?[1] == NSRange(location: 14, length: 5))
        
        
        pattern = try TextFind.Pattern(findString: "abc", mode: .textual(options: [], fullWord: false))
        textFind = try TextFind(for: "abcx---def", pattern: pattern,
                                inSelection: true,
                                selectedRanges: [NSRange(location: 0, length: 4),
                                                 NSRange(location: 7, length: 3)])
        
        (replacementItems, selectedRanges) = textFind.replaceAll(with: "_") { _, _, _ in }
        #expect(replacementItems.count == 1)
        #expect(replacementItems[0].value == "_x")
        #expect(replacementItems[0].range == NSRange(location: 0, length: 4))
        #expect(selectedRanges?[0] == NSRange(location: 0, length: 2))
        #expect(selectedRanges?[1] == NSRange(location: 5, length: 3))
    }
    
    
    @Test func replaceAllTextualCanonicallyEquivalentCharacter() throws {
        
        let pattern = try TextFind.Pattern(findString: "\u{00B7}", mode: .textual(options: [], fullWord: false))
        let textFind = TextFind(for: "\u{00B7}", pattern: pattern)
        
        let (replacementItems, selectedRanges) = textFind.replaceAll(with: "\u{0387}") { _, _, _ in }
        
        #expect(replacementItems.count == 1)
        #expect(replacementItems[0].value.unicodeScalars.map(\.value) == [0x0387])
        #expect(replacementItems[0].range == NSRange(location: 0, length: 1))
        #expect(selectedRanges == nil)
    }
}
