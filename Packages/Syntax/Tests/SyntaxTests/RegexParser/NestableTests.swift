//
//  NestableTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-01.
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

import Testing
import Foundation
import StringUtils
@testable import Syntax

struct NestableTests {
    
    @Suite struct TokenTests {
        
        @Test func pairMultiline() {
            
            let highlight = Syntax.Highlight(begin: "/*", end: "*/", isMultiline: true)
            let token = NestableToken(highlight: highlight)
            
            #expect(token == .pair(Pair("/*", "*/"), isMultiline: true))
        }
        
        
        @Test func inlineRejectedWhenWordy() {
            
            let highlight = Syntax.Highlight(begin: "todo", end: nil)
            let token = NestableToken(highlight: highlight)
            
            #expect(token == nil)
        }
        
        
        @Test func pairRejectedWhenRegex() {
            
            let highlight = Syntax.Highlight(begin: "\"", end: "\"", isRegularExpression: true)
            let token = NestableToken(highlight: highlight)
            
            #expect(token == nil)
        }
    }
    
    
    @Suite struct ParseTests {
        
        @Test func inlineComments() throws {
            
            let source = """
                         a # x
                         b # y
                         
                         """
            let tokens: [NestableToken: SyntaxType] = [
                .inline("#", leadingOnly: false): .comments
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.comments])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 2)
            #expect(matches[0] == "# x")
            #expect(matches[1] == "# y")
        }
        
        
        @Test func inlineCommentsLeadingOnly() throws {
            
            let source = """
                           # one
                         not a comment # mid
                         # two
                         
                         """
            let tokens: [NestableToken: SyntaxType] = [
                .inline("#", leadingOnly: true): .comments
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.comments])
            
            #expect(ranges.count == 2)
            
            let matches = ranges.map((source as NSString).substring(with:))
            #expect(matches[0].hasPrefix("#"))
            #expect(matches[1].hasPrefix("#"))
        }
        
        
        @Test func pairSameDelimiter() throws {
            
            let source = "a 'x' 'y'"
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("'", "'"), isMultiline: false): .strings
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.strings])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 2)
            #expect(matches[0] == "'x'")
            #expect(matches[1] == "'y'")
        }
        
        
        @Test func pairSameDelimiterWithDoubleDelimiterEscaping() throws {
            
            let source = "a 'x''y' 'z'"
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("'", "'"), isMultiline: false): .strings
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange, delimiterEscapeRule: .doubleDelimiter)
            let ranges = try #require(dict[.strings])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 2)
            #expect(matches[0] == "'x''y'")
            #expect(matches[1] == "'z'")
        }
        
        
        @Test func pairSameDelimiterWithMultipleDoubleDelimiterRuns() throws {
            
            let source = "a 'x''''y''z' b"
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("'", "'"), isMultiline: false): .strings
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange, delimiterEscapeRule: .doubleDelimiter)
            let ranges = try #require(dict[.strings])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 1)
            #expect(matches[0] == "'x''''y''z'")
        }
        
        
        @Test func pairDoesNotCrossLinesWithMixedTokens() throws {
            
            let source = """
                         /* a
                         'x' 'y
                         */ b
                         /* ok */
                         z'
                         """
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("/*", "*/"), isMultiline: false): .comments,
                .pair(Pair("'", "'"), isMultiline: false): .strings,
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let commentRanges = try #require(dict[.comments])
            let stringRanges = try #require(dict[.strings])
            let commentMatches = commentRanges.map((source as NSString).substring(with:))
            let stringMatches = stringRanges.map((source as NSString).substring(with:))
            
            #expect(commentMatches.count == 1)
            #expect(commentMatches[0] == "/* ok */")
            #expect(stringMatches.count == 1)
            #expect(stringMatches[0] == "'x'")
        }
        
        
        @Test func pairDifferentDelimiters() throws {
            
            let source = "/* a /* b */ c */ d */"  // last '*/' unmatched should be ignored
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("/*", "*/"), isMultiline: true): .comments
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.comments])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(!matches.isEmpty)
            
            #expect(matches[0].hasPrefix("/*"))
            #expect(matches[0].hasSuffix("*/"))
        }
        
        
        @Test func respectsEscapes() throws {
            
            let source = """
                         \\// not a comment
                         // real
                         """
            let tokens: [NestableToken: SyntaxType] = [
                .inline("//", leadingOnly: false): .comments
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.comments])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 1)
            #expect(matches[0].hasPrefix("//"))
        }
        
        
        @Test func ignoresEscapesWhenRuleIsNone() throws {
            
            let source = """
                         \\// not a comment
                         // real
                         """
            let tokens: [NestableToken: SyntaxType] = [
                .inline("//", leadingOnly: false): .comments
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange, delimiterEscapeRule: .none)
            let ranges = try #require(dict[.comments])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 2)
            #expect(matches[0].hasPrefix("//"))
            #expect(matches[1].hasPrefix("//"))
        }
    }
}
