//
//  NestableTests.swift
//  SyntaxParsersTests
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
import SyntaxFormat
@testable import SyntaxParsers

struct NestableTests {
    
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
        
        
        @Test func inlineCommentsIgnoreLaterTokensOnSameLine() throws {
            
            let source = """
                         # "x"
                         "y"
                         """
            let tokens: [NestableToken: SyntaxType] = [
                .inline("#", leadingOnly: false): .comments,
                .pair(Pair("\"", "\""), isMultiline: false, isNestable: true, escapeCharacter: "\\"): .strings,
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            
            let commentMatches = try #require(dict[.comments]).map((source as NSString).substring(with:))
            let stringMatches = try #require(dict[.strings]).map((source as NSString).substring(with:))
            
            #expect(commentMatches == [#"# "x""#])
            #expect(stringMatches == [#""y""#])
        }
        
        
        @Test func pairSameDelimiter() throws {
            
            let source = "a 'x' 'y'"
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("'", "'"), isMultiline: false, isNestable: true, escapeCharacter: "\\"): .strings
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
                .pair(Pair("'", "'"), isMultiline: false, isNestable: true, escapeCharacter: "'"): .strings
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.strings])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 2)
            #expect(matches[0] == "'x''y'")
            #expect(matches[1] == "'z'")
        }
        
        
        @Test func pairSameDelimiterWithMultipleDoubleDelimiterRuns() throws {
            
            let source = "a 'x''''y''z' b"
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("'", "'"), isMultiline: false, isNestable: true, escapeCharacter: "'"): .strings
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.strings])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 1)
            #expect(matches[0] == "'x''''y''z'")
        }
        
        
        @Test func pairSameDelimiterBackslashVsNone() throws {
            
            let source = "'a\\'b' 'c'"
            let backslashTokens: [NestableToken: SyntaxType] = [
                .pair(Pair("'", "'"), isMultiline: false, isNestable: true, escapeCharacter: "\\"): .strings
            ]
            let noneTokens: [NestableToken: SyntaxType] = [
                .pair(Pair("'", "'"), isMultiline: false, isNestable: true, escapeCharacter: nil): .strings
            ]
            let backslashDict = try backslashTokens.parseHighlights(in: source, range: source.nsRange)
            let noneDict = try noneTokens.parseHighlights(in: source, range: source.nsRange)
            let backslashMatches = try #require(backslashDict[.strings]).map((source as NSString).substring(with:))
            let noneMatches = try #require(noneDict[.strings]).map((source as NSString).substring(with:))
            
            #expect(backslashMatches == ["'a\\'b'", "'c'"])
            #expect(noneMatches == ["'a\\'", "' '"])
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
                .pair(Pair("/*", "*/"), isMultiline: false, isNestable: true, escapeCharacter: "\\"): .comments,
                .pair(Pair("'", "'"), isMultiline: false, isNestable: true, escapeCharacter: "\\"): .strings,
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
        
        
        @Test func unterminatedPairDoesNotBlockLaterLinePair() throws {
            
            let source = """
                         'unterminated
                         'ok'
                         """
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("'", "'"), isMultiline: false, isNestable: true, escapeCharacter: "\\"): .strings
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.strings])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches == ["'ok'"])
        }
        
        
        @Test func pairDifferentDelimiters() throws {
            
            let source = "/* a /* b */ c */ d */"  // last '*/' unmatched should be ignored
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("/*", "*/"), isMultiline: true, isNestable: true, escapeCharacter: "\\"): .comments
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.comments])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(!matches.isEmpty)
            
            #expect(matches[0].hasPrefix("/*"))
            #expect(matches[0].hasSuffix("*/"))
        }
        
        
        @Test func nonNestablePairDifferentDelimiters() throws {
            
            let source = "/* a /* b */ c */ d */"
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("/*", "*/"), isMultiline: true, isNestable: false, escapeCharacter: "\\"): .comments
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.comments])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches == ["/* a /* b */"])
        }
        
        
        @Test func prefixedSameDelimiter() throws {
            
            let source = #"r"hello" "world""#
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("\"", "\""), prefixes: ["r"], isMultiline: false, isNestable: true): .strings
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.strings])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 1)
            #expect(matches[0] == #"r"hello""#)
        }
        
        
        @Test func prefixedSameDelimiterMultiplePrefixes() throws {
            
            let source = #"f"a" rb"b" "c""#
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("\"", "\""), prefixes: ["f", "rb"], isMultiline: false, isNestable: true): .strings
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.strings])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 2)
            #expect(matches[0] == #"f"a""#)
            #expect(matches[1] == #"rb"b""#)
        }
        
        
        @Test func prefixedLongestMatch() throws {
            
            let source = #"rb"x""#
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("\"", "\""), prefixes: ["r", "rb"], isMultiline: false, isNestable: true): .strings
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            let ranges = try #require(dict[.strings])
            let matches = ranges.map((source as NSString).substring(with:))
            
            #expect(matches.count == 1)
            #expect(matches[0] == #"rb"x""#)
        }
        
        
        @Test func unprefixedAndPrefixedCoexistence() throws {
            
            let source = #"r"raw" "plain""#
            let tokens: [NestableToken: SyntaxType] = [
                .pair(Pair("\"", "\""), isMultiline: false, isNestable: true, escapeCharacter: "\\"): .strings,
                .pair(Pair("\"", "\""), prefixes: ["r"], isMultiline: false, isNestable: true): .characters,
            ]
            let dict = try tokens.parseHighlights(in: source, range: source.nsRange)
            
            let prefixedMatches = (dict[.characters] ?? []).map((source as NSString).substring(with:))
            #expect(prefixedMatches == [#"r"raw""#])
            
            let plainMatches = (dict[.strings] ?? []).map((source as NSString).substring(with:))
            #expect(plainMatches == [#""plain""#])
        }
    }
}
