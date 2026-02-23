//
//  TreeSitterClientTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-23.
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
import StringUtils
import ValueRange
@testable import Syntax

actor TreeSitterClientTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func incrementalParseUpdatesRange() async throws {
        
        let source = #"""
            /// Tests highlighting.
            @concurrent private func doSomething(in string: String, range: NSRange) async throws -> [SomeItem] {
                
                guard #available(macOS 26, *) else { return }
                
                let item = Registry.items.first { $0.name = "with \(string)" }
                
                return try self.storage.replace(item, in: range)
            }
        """#
        
        let config = try self.registry.configuration(for: .swift)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .swift)
        _ = try #require(await client.parseHighlights(in: source, range: source.nsRange))
        
        let locationRange = (source as NSString).range(of: "doSomething")
        let insertLocation = locationRange.location
        let insertedText = "/*x*/"
        let editedRange = NSRange(location: insertLocation, length: insertedText.length)
        let editedSource = (source as NSString).replacingCharacters(in: NSRange(location: insertLocation, length: 0), with: insertedText)
        
        try await client.noteEdit(editedRange: editedRange, delta: insertedText.length, insertedText: insertedText)
        let requestedRange = NSRange(location: 0, length: 0)
        let result = try #require(await client.parseHighlights(in: editedSource, range: requestedRange))
        let updateRange = result.updateRange
        
        #expect(updateRange.lowerBound <= editedRange.lowerBound)
        #expect(updateRange.upperBound >= editedRange.upperBound)
        #expect(updateRange.upperBound > requestedRange.upperBound)
        #expect(!result.highlights.isEmpty)
    }
    
    
    @Test func highlightSwift() async throws {
        
        let source = #"""
            /// Tests highlighting.
            @concurrent private func doSomething(in string: String, range: NSRange) async throws -> [SomeItem] {
                
                guard #available(macOS 26, *) else { return }
                
                let item = Registry.items.first { $0.name = "with \(string)" }
                
                return try self.storage.replace(item, in: range)
            }
        """#
        
        let config = try self.registry.configuration(for: .swift)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .swift)
        let captures = try #require(await client.parseHighlights(in: source, range: source.nsRange))
            .highlights
            .map { Capture(type: $0.value, text: (source as NSString).substring(with: $0.range)) }
        
        #expect(captures.count == 32)
        #expect(captures[0] == Capture(type: .comments, text: "/// Tests highlighting."))
        #expect(captures[1] == Capture(type: .attributes, text: "@"))
        #expect(captures[2] == Capture(type: .types, text: "concurrent"))
        #expect(captures[3] == Capture(type: .attributes, text: "concurrent"))
        #expect(captures[4] == Capture(type: .keywords, text: "private"))
        #expect(captures[5] == Capture(type: .keywords, text: "func"))
        #expect(captures[6] == Capture(type: .commands, text: "doSomething"))
        #expect(captures[7] == Capture(type: .variables, text: "in"))
        #expect(captures[8] == Capture(type: .variables, text: "string"))
        #expect(captures[9] == Capture(type: .types, text: "String"))
        #expect(captures[10] == Capture(type: .variables, text: "range"))
        #expect(captures[11] == Capture(type: .types, text: "NSRange"))
        #expect(captures[12] == Capture(type: .keywords, text: "async"))
        #expect(captures[13] == Capture(type: .keywords, text: "throws"))
        #expect(captures[14] == Capture(type: .types, text: "SomeItem"))
        #expect(captures[15] == Capture(type: .keywords, text: "guard"))
        #expect(captures[16] == Capture(type: .attributes, text: "#available(macOS 26, *)"))
        #expect(captures[17] == Capture(type: .numbers, text: "26"))
        #expect(captures[18] == Capture(type: .keywords, text: "else"))
        #expect(captures[19] == Capture(type: .keywords, text: "return"))
        #expect(captures[20] == Capture(type: .keywords, text: "let"))
        #expect(captures[21] == Capture(type: .types, text: "Registry"))
        #expect(captures[22] == Capture(type: .variables, text: "$0"))
        #expect(captures[23] == Capture(type: .strings, text: "\""))
        #expect(captures[24] == Capture(type: .strings, text: "with "))
        #expect(captures[25] == Capture(type: .characters, text: #"\("#))
        #expect(captures[26] == Capture(type: .characters, text: ")"))
        #expect(captures[27] == Capture(type: .strings, text: #"""#))
        #expect(captures[28] == Capture(type: .keywords, text: "return"))
        #expect(captures[29] == Capture(type: .keywords, text: "try"))
        #expect(captures[30] == Capture(type: .keywords, text: "self"))
        #expect(captures[31] == Capture(type: .commands, text: "replace"))
    }
    
    
    @Test func outlineSwift() async throws {
        
        let source = #"""
            class Foo {
                
                func dog() { }
                // MARK: - Cow
                func cat() { }
            }
        """#
        
        let config = try self.registry.configuration(for: .swift)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .swift)
        let outline = try await client.parseOutline(in: source)
        
        #expect(outline.count == 5)
        #expect(outline[0].title == "Foo")
        #expect(outline[0].kind == .container)
        #expect(outline[0].indent == .level(0))
        #expect(outline[1].title == "dog")
        #expect(outline[1].kind == .function)
        #expect(outline[1].indent == .level(1))
        #expect(outline[2].title.isEmpty)
        #expect(outline[2].kind == .separator)
        #expect(outline[2].indent == .level(1))
        #expect(outline[3].title == "Cow")
        #expect(outline[3].kind == .mark)
        #expect(outline[3].indent == .level(1))
        #expect(outline[4].title == "cat")
        #expect(outline[4].kind == .function)
        #expect(outline[4].indent == .level(1))
    }
    
    
    @Test func outlinePythonDecoratedFunctionsRemainSiblings() async throws {
        
        let source = #"""
            def chunked(items, size):
                return []
            
            @contextmanager
            def open_text(path):
                yield path
            
            @asynccontextmanager
            async def timer(label):
                yield
        """#
        
        let config = try self.registry.configuration(for: .python)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .python)
        let outline = try await client.parseOutline(in: source)
        
        #expect(outline.count == 3)
        #expect(outline[0].title == "chunked")
        #expect(outline[0].kind == .function)
        #expect(outline[0].indent == .level(0))
        #expect(outline[1].title == "open_text")
        #expect(outline[1].kind == .function)
        #expect(outline[1].indent == .level(0))
        #expect(outline[2].title == "timer")
        #expect(outline[2].kind == .function)
        #expect(outline[2].indent == .level(0))
    }
}


private struct Capture: Equatable {
    
    var type: SyntaxType
    var text: String
}
