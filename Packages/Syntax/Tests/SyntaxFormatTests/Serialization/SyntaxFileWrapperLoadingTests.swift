//
//  SyntaxFileWrapperLoadingTests.swift
//  SyntaxFormatTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-25.
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

struct SyntaxFileWrapperLoadingTests {
    
    @Test func fileWrapperMinimal() throws {
        
        let info = Syntax.Info(kind: .general, fileMap: nil, metadata: nil)
        let wrapper = FileWrapper(directoryWithFileWrappers: [
            "Info.json": FileWrapper(regularFileWithContents: try JSONEncoder().encode(info)),
        ])
        
        let syntax = try Syntax(fileWrapper: wrapper)
        
        #expect(syntax.kind == .general)
        #expect(syntax.fileMap == .init())
        #expect(syntax.metadata == .init())
        #expect(syntax.commentDelimiters.isEmpty)
        #expect(syntax.stringDelimiters.isEmpty)
        #expect(syntax.characterDelimiters.isEmpty)
        #expect(syntax.completions.isEmpty)
        #expect(syntax.highlights.isEmpty)
        #expect(syntax.outlines.isEmpty)
    }
    
    
    @Test func fileWrapperWithEditAndRegex() throws {
        
        let info = Syntax.Info(kind: .code, fileMap: .init(extensions: ["swift"]), metadata: .init(author: "me"))
        let edit = Syntax.Edit(
            comment: .init(inlines: [.init(begin: "//")], blocks: [.init(begin: "/*", end: "*/")]),
            stringDelimiters: [.init(begin: "'", end: "'", isMultiline: true, escapeCharacter: "'")],
            characterDelimiters: [.init(begin: "'", end: "'")]
        )
        let completions: [Syntax.CompletionWord] = [.init(text: "print", type: .commands)]
        let highlights: [SyntaxType: [Syntax.Highlight]] = [
            .keywords: [.init(begin: "func")],
        ]
        let outlines: [Syntax.Outline] = [
            .init(pattern: "^func", template: "func", kind: .function),
        ]
        
        let encoder = JSONEncoder()
        let wrapper = FileWrapper(directoryWithFileWrappers: [
            "Info.json": FileWrapper(regularFileWithContents: try encoder.encode(info)),
            "Edit.json": FileWrapper(regularFileWithContents: try encoder.encode(edit)),
            "Completion.json": FileWrapper(regularFileWithContents: try encoder.encode(completions)),
            "Regex": FileWrapper(directoryWithFileWrappers: [
                "Highlights.json": FileWrapper(regularFileWithContents: try encoder.encode(highlights)),
                "Outlines.json": FileWrapper(regularFileWithContents: try encoder.encode(outlines)),
            ]),
        ])
        
        let syntax = try Syntax(fileWrapper: wrapper)
        
        #expect(syntax.kind == .code)
        #expect(syntax.fileMap.extensions == ["swift"])
        #expect(syntax.metadata.author == "me")
        #expect(syntax.commentDelimiters.inlines.map(\.begin) == ["//"])
        #expect(syntax.commentDelimiters.blocks == [.init(begin: "/*", end: "*/")])
        #expect(syntax.stringDelimiters == [.init(begin: "'", end: "'", isMultiline: true, escapeCharacter: "'")])
        #expect(syntax.characterDelimiters == [.init(begin: "'", end: "'")])
        #expect(syntax.completions.map(\.text) == ["print"])
        #expect(syntax.highlights[.keywords]?.map(\.begin) == ["func"])
        #expect(syntax.outlines.map(\.pattern) == ["^func"])
    }
    
    
    @Test func fileWrapperRequiresInfo() {
        
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])
        
        #expect(throws: CocoaError.self) {
            _ = try Syntax(fileWrapper: wrapper)
        }
    }
}
