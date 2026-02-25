//
//  StringSmartIndentingTests.swift
//  TextEditingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-24.
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
import StringUtils
@testable import TextEditing

struct StringSmartIndentingTests {
    
    private nonisolated static let tokens: [IndentToken] = [
        .symbolPair(Pair("{", "}")),
        .beginToken(":", ignoreCase: false),
        .tokenPair(Pair("then", "end"), ignoreCase: false),
    ]
    
    
    @Test func indentTokenInit() {
        
        let symbols: [Character] = ["{", "[", "(", ":"]
        #expect(try symbols.allSatisfy(\.isPunctuation))
        
        #expect(IndentToken(begin: "", end: "") == nil)
        #expect(IndentToken(begin: "", end: "}") == nil)
        #expect(IndentToken(begin: "{", end: "") == .beginToken("{", ignoreCase: false))
        #expect(IndentToken(begin: "\\", end: "") == .beginToken("\\", ignoreCase: false))
        #expect(IndentToken(begin: "{", end: "}") == .symbolPair(Pair("{", "}")))
        #expect(IndentToken(begin: "begin", end: "end") == .tokenPair(Pair("begin", "end"), ignoreCase: false))
    }
    
    
    @Test func smartIndentNoIndent() {
        
        // no indent
        let string = "foo\n"
        let range = NSRange(location: 4, length: 0)
        let context = string.smartIndent(style: .space, indentWidth: 2, tokens: Self.tokens, in: [range])
        
        #expect(context == nil)
    }
    
    
    @Test func smartIndentSameLevel() throws {
        
        // normal indentation at the same level
        let string = "    foo\n"
        let range = NSRange(location: 8, length: 0)
        let context = try #require(string.smartIndent(style: .space, indentWidth: 2, tokens: Self.tokens, in: [range]))
        
        #expect(context.strings == ["    "])
        #expect(context.ranges == [NSRange(location: 8, length: 0)])
        #expect(context.selectedRanges == [NSRange(location: 12, length: 0)])
    }
    
    
    @Test func smartIndentAfterColon() throws {
        
        // increasing the level with `:`
        let string = "    if foo:\n"
        let range = NSRange(location: 12, length: 0)
        let context = try #require(string.smartIndent(style: .space, indentWidth: 2, tokens: Self.tokens, in: [range]))
        
        #expect(context.strings == ["      "])
        #expect(context.ranges == [NSRange(location: 12, length: 0)])
        #expect(context.selectedRanges == [NSRange(location: 18, length: 0)])
    }
    
    
    @Test func smartIndentBraces() throws {
        
        // increasing the level with `{` and `}`
        let string = "    {\n}"
        let range = NSRange(location: 6, length: 0)
        let context = try #require(string.smartIndent(style: .space, indentWidth: 2, tokens: Self.tokens, in: [range]))
        
        #expect(context.strings == ["      \n    "])
        #expect(context.ranges == [NSRange(location: 6, length: 0)])
        #expect(context.selectedRanges == [NSRange(location: 12, length: 0)])
    }
    
    
    @Test func smartIndentNoExpandWithoutClosingBrace() throws {
        
        // no expanding if `}` is not just after the insertion location
        let string = "{\n }"
        let range = NSRange(location: 2, length: 0)
        let context = try #require(string.smartIndent(style: .space, indentWidth: 2, tokens: Self.tokens, in: [range]))
        
        #expect(context.strings == ["  "])
        #expect(context.ranges == [NSRange(location: 2, length: 0)])
        #expect(context.selectedRanges == [NSRange(location: 4, length: 0)])
    }
    
    
    @Test func smartIndentNoIndentWhenTokenNotBeforeLineEnding() {
        
        // no indent if the token is not just before the line ending
        let string = "if foo: \n"
        let range = NSRange(location: string.utf16.count, length: 0)
        let context = string.smartIndent(style: .space, indentWidth: 2, tokens: Self.tokens, in: [range])
        
        #expect(context == nil)
    }
    
    
    @Test func smartIndentThenEndPair() throws {
        
        // insert extra line when the closing token follows
        let string = "then\nend"
        let range = NSRange(location: 5, length: 0)
        let context = try #require(string.smartIndent(style: .space, indentWidth: 2, tokens: Self.tokens, in: [range]))
        
        #expect(context.strings == ["  \n"])
        #expect(context.ranges == [NSRange(location: 5, length: 0)])
        #expect(context.selectedRanges == [NSRange(location: 7, length: 0)])
    }
    
    
    @Test func lineEndingStringBefore() {
        
        let lf = "a\nb".lineEndingString(before: 2)
        #expect(lf == "\n")
        
        let crlf = "a\r\nb".lineEndingString(before: 3)
        #expect(crlf == "\r\n")
        
        let cr = "a\rb".lineEndingString(before: 2)
        #expect(cr == "\r")
        
        let nel = "a\u{0085}b".lineEndingString(before: 2)
        #expect(nel == "\u{0085}")
        
        let ls = "a\u{2028}b".lineEndingString(before: 2)
        #expect(ls == "\u{2028}")
        
        let ps = "a\u{2029}b".lineEndingString(before: 2)
        #expect(ps == "\u{2029}")
        
        #expect("a\n".lineEndingString(before: 0) == nil)
        #expect("a\n".lineEndingString(before: 1) == nil)
    }
    
    
    @Test func matchesTokenBefore() {
        
        #expect("then\n".matches(token: "then", before: 4))
        #expect(!"thens\n".matches(token: "then", before: 5))
        #expect("{".matches(token: "{", before: 1))
        #expect(!"{".matches(token: "{", before: 0))
    }
    
    
    @Test func matchesTokenAfter() {
        
        #expect("then".matches(token: "then", after: 0, ignoreCase: false))
        #expect(!"thens".matches(token: "then", after: 0))
        #expect("}".matches(token: "}", after: 0))
        #expect(!"}".matches(token: "}", after: "}".utf16.count))
    }
    
    
    @Test func matchesTokenIgnoreCase() {
        
        #expect("THEN\n".matches(token: "then", before: 4, ignoreCase: true))
        #expect("End".matches(token: "end", after: 0, ignoreCase: true))
        #expect(!"THEN\n".matches(token: "then", before: 4, ignoreCase: false))
    }
}
