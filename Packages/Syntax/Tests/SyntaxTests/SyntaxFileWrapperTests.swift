//
//  SyntaxFileWrapperTests.swift
//  SyntaxTests
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
import StringUtils
import Testing
@testable import Syntax

struct SyntaxFileWrapperTests {
    
    @Test func highlightDecodingDefaults() throws {
        
        let data = try JSONSerialization.data(withJSONObject: [
            "beginString": "abc",
        ])
        
        let highlight = try JSONDecoder().decode(Syntax.Highlight.self, from: data)
        
        #expect(highlight.begin == "abc")
        #expect(highlight.end == nil)
        #expect(!highlight.isRegularExpression)
        #expect(!highlight.ignoreCase)
        #expect(!highlight.isMultiline)
        #expect(highlight.description == nil)
    }
    
    
    @Test func highlightEncodingSkipsDefaults() throws {
        
        let highlight = Syntax.Highlight(begin: "abc", end: "", description: "note")
        let data = try JSONEncoder().encode(highlight)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        
        #expect(object["beginString"] as? String == "abc")
        #expect(object["endString"] == nil)
        #expect(object["regularExpression"] == nil)
        #expect(object["ignoreCase"] == nil)
        #expect(object["isMultiline"] == nil)
        #expect(object["description"] as? String == "note")
    }
    
    
    @Test func outlineDecodingDefaults() throws {
        
        let data = try JSONSerialization.data(withJSONObject: [
            "beginString": "pattern",
            "keyString": "template",
        ])
        
        let outline = try JSONDecoder().decode(Syntax.Outline.self, from: data)
        
        #expect(outline.pattern == "pattern")
        #expect(outline.template == "template")
        #expect(!outline.ignoreCase)
        #expect(outline.kind == nil)
        #expect(outline.description == nil)
    }
    
    
    @Test func outlineEncodingSkipsDefaults() throws {
        
        let outline = Syntax.Outline(pattern: "pattern", template: "template", kind: .function)
        let data = try JSONEncoder().encode(outline)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        
        #expect(object["beginString"] as? String == "pattern")
        #expect(object["keyString"] as? String == "template")
        #expect(object["ignoreCase"] == nil)
        #expect(object["kind"] as? String == "function")
        #expect(object["description"] == nil)
    }
    
    
    @Test func commentInlineEncodingDefaults() throws {
        
        let inline = Syntax.Comment.Inline(begin: "//")
        let data = try JSONEncoder().encode(inline)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        
        #expect(object["begin"] as? String == "//")
        #expect(object["leadingOnly"] == nil)
    }
    
    
    @Test func commentInlineDecodingDefaults() throws {
        
        let data = try JSONSerialization.data(withJSONObject: [
            "begin": "#",
        ])
        
        let inline = try JSONDecoder().decode(Syntax.Comment.Inline.self, from: data)
        
        #expect(inline.begin == "#")
        #expect(!inline.leadingOnly)
    }
    
    
    @Test func fileWrapperMinimal() throws {
        
        let info = Syntax.Info(kind: .general, fileMap: nil, metadata: nil)
        let infoData = try JSONEncoder().encode(info)
        let wrapper = FileWrapper(directoryWithFileWrappers: [
            "Info.json": FileWrapper(regularFileWithContents: infoData),
        ])
        
        let syntax = try Syntax(fileWrapper: wrapper)
        
        #expect(syntax.kind == .general)
        #expect(syntax.fileMap == .init())
        #expect(syntax.metadata == .init())
        #expect(syntax.commentDelimiters.isEmpty)
        #expect(syntax.completions.isEmpty)
        #expect(syntax.highlights.isEmpty)
        #expect(syntax.outlines.isEmpty)
    }
    
    
    @Test func fileWrapperWithEditAndRegex() throws {
        
        let info = Syntax.Info(kind: Syntax.Kind.code, fileMap: .init(extensions: ["swift"]), metadata: .init(author: "me"))
        let edit = Syntax.Edit(comment: .init(inlines: [.init(begin: "//")], blocks: [Pair("/*", "*/")]),
                               completions: [.init(text: "print", type: SyntaxType.commands)])
        let highlights: [SyntaxType: [Syntax.Highlight]] = [
            SyntaxType.keywords: [.init(begin: "func")],
        ]
        let outlines: [Syntax.Outline] = [
            .init(pattern: "^func", template: "func", kind: .function),
        ]
        
        let encoder = JSONEncoder()
        let wrapper = FileWrapper(directoryWithFileWrappers: [
            "Info.json": FileWrapper(regularFileWithContents: try encoder.encode(info)),
            "Edit.json": FileWrapper(regularFileWithContents: try encoder.encode(edit)),
            "Regex": FileWrapper(directoryWithFileWrappers: [
                "Highlights.json": FileWrapper(regularFileWithContents: try encoder.encode(highlights)),
                "Outlines.json": FileWrapper(regularFileWithContents: try encoder.encode(outlines)),
            ]),
        ])
        
        let syntax = try Syntax(fileWrapper: wrapper)
        
        #expect(syntax.kind == Syntax.Kind.code)
        #expect(syntax.fileMap.extensions == ["swift"])
        #expect(syntax.metadata.author == "me")
        #expect(syntax.commentDelimiters.inlines.map { $0.begin } == ["//"])
        #expect(syntax.commentDelimiters.blocks == [Pair("/*", "*/")])
        #expect(syntax.completions.map { $0.text } == ["print"])
        #expect(syntax.highlights[SyntaxType.keywords]?.map { $0.begin } == ["func"])
        #expect(syntax.outlines.map { $0.pattern } == ["^func"])
    }
    
    
    @Test func fileWrapperSerializationIncludesSections() throws {
        
        let syntax = Syntax(
            kind: .general,
            fileMap: .init(extensions: ["md"]),
            highlights: [SyntaxType.keywords: [.init(begin: "todo")]],
            outlines: [.init(pattern: "^#", template: "header")],
            commentDelimiters: .init(inlines: [.init(begin: "#")]),
            completions: [.init(text: "hello", type: SyntaxType.keywords)],
            metadata: .init(author: "tester")
        )
        
        let wrapper = try syntax.fileWrapper
        let root = wrapper.fileWrappers ?? [:]
        
        #expect(root["Info.json"] != nil)
        #expect(root["Edit.json"] != nil)
        
        let regex = root["Regex"]?.fileWrappers ?? [:]
        #expect(regex["Highlights.json"] != nil)
        #expect(regex["Outlines.json"] != nil)
    }
    
    
    @Test func fileWrapperRequiresInfo() {
        
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])
        
        #expect(throws: CocoaError.self) {
            _ = try Syntax(fileWrapper: wrapper)
        }
    }
}
