//
//  SyntaxFileWrapperSerializationTests.swift
//  SyntaxTests
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

struct SyntaxFileWrapperSerializationTests {
    
    @Test func fileWrapperSerializationIncludesSections() throws {
        
        let syntax = Syntax(
            kind: .general,
            fileMap: .init(extensions: ["md"]),
            highlights: [.keywords: [.init(begin: "todo")]],
            outlines: [.init(pattern: "^#", template: "header")],
            commentDelimiters: .init(inlines: [.init(begin: "#")]),
            stringDelimiters: [.init(begin: "\"", end: "\"", isMultiline: true, escapeCharacter: "\\")],
            characterDelimiters: [.init(begin: "'", end: "'")],
            completions: [.init(text: "hello", type: .keywords)],
            metadata: .init(author: "tester")
        )
        
        let wrapper = try syntax.fileWrapper
        let root = wrapper.fileWrappers ?? [:]
        
        #expect(root["Info.json"] != nil)
        #expect(root["Edit.json"] != nil)
        
        let regex = root["Regex"]?.fileWrappers ?? [:]
        #expect(regex["Highlights.json"] != nil)
        #expect(regex["Outlines.json"] != nil)
        
        let editData = try #require(root["Edit.json"]?.regularFileContents)
        let edit = try JSONDecoder().decode(Syntax.Edit.self, from: editData)
        #expect(try #require(edit.stringDelimiters) == [.init(begin: "\"", end: "\"", isMultiline: true, escapeCharacter: "\\")])
        #expect(try #require(edit.characterDelimiters) == [.init(begin: "'", end: "'")])
    }
    
    
    @Test func fileWrapperSerializationOmitsEmptyEdit() throws {
        
        let syntax = Syntax()
        let wrapper = try syntax.fileWrapper
        
        #expect(wrapper.fileWrappers?["Edit.json"] == nil)
    }
    
    
    @Test func fileWrapperSerializationOmitsEmptyRegexDirectory() throws {
        
        let syntax = Syntax(highlights: [.keywords: []])
        let wrapper = try syntax.fileWrapper
        
        #expect(wrapper.fileWrappers?["Regex"] == nil)
    }
    
    
    @Test func fileWrapperSerializationIncludesStringDelimitersOnly() throws {
        
        let syntax = Syntax(stringDelimiters: [.init(begin: "'", end: "'", escapeCharacter: "'")])
        
        let wrapper = try syntax.fileWrapper
        let editData = try #require(wrapper.fileWrappers?["Edit.json"]?.regularFileContents)
        let edit = try JSONDecoder().decode(Syntax.Edit.self, from: editData)
        
        #expect(edit.comment == nil)
        #expect(edit.indentation == nil)
        #expect(edit.characterDelimiters == nil)
        #expect(edit.stringDelimiters == [.init(begin: "'", end: "'", escapeCharacter: "'")])
    }
    
    
    @Test func fileWrapperSerializationIncludesCharacterDelimitersOnly() throws {
        
        let syntax = Syntax(characterDelimiters: [.init(begin: "'", end: "'")])
        
        let wrapper = try syntax.fileWrapper
        let editData = try #require(wrapper.fileWrappers?["Edit.json"]?.regularFileContents)
        let edit = try JSONDecoder().decode(Syntax.Edit.self, from: editData)
        
        #expect(edit.comment == nil)
        #expect(edit.indentation == nil)
        #expect(edit.stringDelimiters == nil)
        #expect(edit.characterDelimiters == [.init(begin: "'", end: "'")])
    }
}
