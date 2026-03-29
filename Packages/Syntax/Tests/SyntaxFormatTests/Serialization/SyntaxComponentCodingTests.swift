//
//  SyntaxComponentCodingTests.swift
//  SyntaxFormatTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-08.
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
@testable import SyntaxFormat

struct SyntaxComponentCodingTests {
    
    @Test func highlightDecodingDefaults() throws {
        
        let highlight = try JSONDecoder().decode(Syntax.Highlight.self, from: JSONSerialization.data(withJSONObject: [
            "begin": "abc",
        ]))
        
        #expect(highlight.begin == "abc")
        #expect(highlight.end == nil)
        #expect(!highlight.isRegularExpression)
        #expect(!highlight.ignoreCase)
        #expect(!highlight.isMultiline)
        #expect(highlight.description == nil)
    }
    
    
    @Test func highlightEncodingSkipsDefaults() throws {
        
        let highlight = Syntax.Highlight(begin: "abc", end: "", description: "note")
        let object = try Self.object(from: highlight)
        
        #expect(object["begin"] as? String == "abc")
        #expect(object["end"] == nil)
        #expect(object["regularExpression"] == nil)
        #expect(object["ignoreCase"] == nil)
        #expect(object["isMultiline"] == nil)
        #expect(object["description"] as? String == "note")
    }
    
    
    @Test func outlineDecodingDefaults() throws {
        
        let outline = try JSONDecoder().decode(Syntax.Outline.self, from: JSONSerialization.data(withJSONObject: [
            "pattern": "pattern",
            "template": "template",
        ]))
        
        #expect(outline.pattern == "pattern")
        #expect(outline.template == "template")
        #expect(!outline.ignoreCase)
        #expect(outline.kind == nil)
        #expect(outline.description == nil)
    }
    
    
    @Test func outlineEncodingSkipsDefaults() throws {
        
        let outline = Syntax.Outline(pattern: "pattern", template: "template", kind: .function)
        let object = try Self.object(from: outline)
        
        #expect(object["pattern"] as? String == "pattern")
        #expect(object["template"] as? String == "template")
        #expect(object["ignoreCase"] == nil)
        #expect(object["kind"] as? String == "function")
        #expect(object["description"] == nil)
    }
    
    
    @Test func outlineEncodingUsesDottedHeadingLevelToken() throws {
        
        let outline = Syntax.Outline(pattern: "pattern", template: "template", kind: .heading(2))
        let object = try Self.object(from: outline)
        
        #expect(object["kind"] as? String == "heading.2")
    }
    
    
    @Test func outlineDecodingSupportsBareHeadingToken() throws {
        
        let outline = try JSONDecoder().decode(Syntax.Outline.self, from: JSONSerialization.data(withJSONObject: [
            "pattern": "pattern",
            "template": "template",
            "kind": "heading",
        ]))
        
        #expect(outline.kind == .heading(nil))
    }
    
    
    @Test func outlineDecodingSupportsDottedHeadingLevelToken() throws {
        
        let outline = try JSONDecoder().decode(Syntax.Outline.self, from: JSONSerialization.data(withJSONObject: [
            "pattern": "pattern",
            "template": "template",
            "kind": "heading.5",
        ]))
        
        #expect(outline.kind == .heading(5))
    }
    
    
    @Test(arguments: ["heading.0", "heading.10", "heading.foo"])
    func outlineDecodingRejectsInvalidHeadingLevelTokens(token: String) throws {
        
        let data = try JSONSerialization.data(withJSONObject: [
            "pattern": "pattern",
            "template": "template",
            "kind": token,
        ])
        
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Syntax.Outline.self, from: data)
        }
    }
    
    
    @Test func commentInlineEncodingDefaults() throws {
        
        let inline = Syntax.Comment.Inline(begin: "//")
        let object = try Self.object(from: inline)
        
        #expect(object["begin"] as? String == "//")
        #expect(object["leadingOnly"] == nil)
    }
    
    
    @Test func commentInlineDecodingDefaults() throws {
        
        let inline = try JSONDecoder().decode(Syntax.Comment.Inline.self, from: JSONSerialization.data(withJSONObject: [
            "begin": "#",
        ]))
        
        #expect(inline.begin == "#")
        #expect(!inline.leadingOnly)
    }
    
    
    @Test func commentBlockDecodingDefaults() throws {
        
        let block = try JSONDecoder().decode(Syntax.Comment.Block.self, from: JSONSerialization.data(withJSONObject: [
            "begin": "/*",
            "end": "*/",
        ]))
        
        #expect(block.begin == "/*")
        #expect(block.end == "*/")
        #expect(!block.isNestable)
    }
    
    
    @Test func commentBlockEncodingSkipsDefaults() throws {
        
        let block = Syntax.Comment.Block(begin: "/*", end: "*/")
        let object = try Self.object(from: block)
        
        #expect(object["begin"] as? String == "/*")
        #expect(object["end"] as? String == "*/")
        #expect(object["isNestable"] == nil)
    }
    
    
    @Test func stringDelimiterDecodingDefaults() throws {
        
        let delimiter = try JSONDecoder().decode(Syntax.PairDelimiter.self, from: JSONSerialization.data(withJSONObject: [
            "begin": "\"",
            "end": "\"",
        ]))
        
        #expect(delimiter.begin == "\"")
        #expect(delimiter.end == "\"")
        #expect(delimiter.prefixes == nil)
        #expect(delimiter.escapeCharacter == nil)
        #expect(!delimiter.isMultiline)
        #expect(delimiter.description == nil)
    }
    
    
    @Test func stringDelimiterEncodingSkipsDefaults() throws {
        
        let delimiter = Syntax.PairDelimiter(begin: "'", end: "'")
        let object = try Self.object(from: delimiter)
        
        #expect(object["begin"] as? String == "'")
        #expect(object["end"] as? String == "'")
        #expect(object["prefixes"] == nil)
        #expect(object["isMultiline"] == nil)
        #expect(object["escapeCharacter"] == nil)
        #expect(object["description"] == nil)
    }
    
    
    @Test func stringDelimiterPrefixesRoundTrip() throws {
        
        let delimiter = Syntax.PairDelimiter(begin: "\"", end: "\"", prefixes: ["r", "f", "rb"])
        let data = try JSONEncoder().encode(delimiter)
        let object = try Self.object(from: delimiter)
        
        #expect(object["prefixes"] as? [String] == ["r", "f", "rb"])
        
        let decoded = try JSONDecoder().decode(Syntax.PairDelimiter.self, from: data)
        #expect(decoded == delimiter)
    }
    
    
    @Test func stringDelimiterNilPrefixesOmitted() throws {
        
        let delimiter = Syntax.PairDelimiter(begin: "\"", end: "\"", prefixes: nil)
        let object = try Self.object(from: delimiter)
        
        #expect(object["prefixes"] == nil)
    }
    
    
    @Test func stringDelimiterEmptyPrefixesOmitted() throws {
        
        let delimiter = Syntax.PairDelimiter(begin: "\"", end: "\"", prefixes: [])
        let object = try Self.object(from: delimiter)
        
        #expect(object["prefixes"] == nil)
    }
    
    
    @Test func stringDelimiterEncodingIncludesDescription() throws {
        
        let delimiter = Syntax.PairDelimiter(begin: "'", end: "'", description: "single quoted")
        let object = try Self.object(from: delimiter)
        
        #expect(object["begin"] as? String == "'")
        #expect(object["end"] as? String == "'")
        #expect(object["isMultiline"] == nil)
        #expect(object["escapeCharacter"] == nil)
        #expect(object["description"] as? String == "single quoted")
    }
    
    
    @Test func stringDelimiterDecodingDropsMultiCharacterEscape() throws {
        
        let delimiter = try JSONDecoder().decode(Syntax.PairDelimiter.self, from: JSONSerialization.data(withJSONObject: [
            "begin": "\"",
            "end": "\"",
            "escapeCharacter": "!!",
        ]))
        
        #expect(delimiter.escapeCharacter == nil)
    }
    
    
    @Test func delimiterDecodingDefaults() throws {
        
        let delimiter = try JSONDecoder().decode(Syntax.Delimiter.self, from: JSONSerialization.data(withJSONObject: [
            "begin": "{",
            "end": "}",
        ]))
        
        #expect(delimiter.begin == "{")
        #expect(delimiter.end == "}")
        #expect(!delimiter.ignoreCase)
        #expect(delimiter.description == nil)
    }
    
    
    @Test func delimiterEncodingSkipsDefaults() throws {
        
        let delimiter = Syntax.Delimiter(begin: "{", end: "}", description: "block")
        let object = try Self.object(from: delimiter)
        
        #expect(object["begin"] as? String == "{")
        #expect(object["end"] as? String == "}")
        #expect(object["ignoreCase"] == nil)
        #expect(object["description"] as? String == "block")
    }
    
    
    // MARK: Private Methods
    
    private static func object<T: Encodable>(from value: T) throws -> [String: Any] {
        
        let data = try JSONEncoder().encode(value)
        let object = try JSONSerialization.jsonObject(with: data)
        
        return try #require(object as? [String: Any])
    }
}
