//
//  TreeSitterOutlineTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-16.
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
@testable import Syntax

actor TreeSitterOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func formatCSS() {
        
        let formatter = TreeSitterSyntax.css.outlinePolicy.titleFormatter
        
        #expect(formatter(.container, "@media (prefers-color-scheme: dark) { .item { color: white; } }") == "@media (prefers-color-scheme: dark)")
        #expect(formatter(.container, "@layer utilities { .m-1 { margin: 1rem; } }") == "@layer utilities")
        #expect(formatter(.container, "@import url(\"theme.css\");") == "@import url(\"theme.css\")")
        #expect(formatter(.container, "   ;") == nil)
    }
    
    
    @Test func formatSwift() {
        
        let formatter = TreeSitterSyntax.swift.outlinePolicy.titleFormatter
        
        #expect(formatter(.function, "SomeFunction") == "SomeFunction")
        #expect(formatter(.mark, "// MARK: Swift") == "Swift")
        #expect(formatter(.mark, "// MARK: - Swift") == "Swift")
        #expect(formatter(.mark, "/* MARK: Swift */") == "Swift")
        #expect(formatter(.mark, "// MARK:") == nil)
    }
    
    
    @Test func formatMarkdown() {
        
        let formatter = TreeSitterSyntax.markdown.outlinePolicy.titleFormatter
        
        #expect(formatter(.heading, "Setext H1\n========") == "Setext H1")
        #expect(formatter(.heading, "Setext H2\n--------") == "Setext H2")
        #expect(formatter(.heading, "ATX H1") == "ATX H1")
    }
    
    
    @Test func parseMarkdownOutlineCapturesATXAndSetextHeadings() async throws {
        
        let source = """
                     # Top
                     
                     ## Section
                     
                     Setext One
                     ==========
                     
                     Setext Two
                     ----------
                     
                     ---
                     """
        
        let outline = try await self.parseOutline(in: source, syntax: .markdown)
        
        #expect(outline.map(\.title) == ["Top", "Section", "Setext One", "Setext Two"])
        #expect(outline.map(\.kind) == [.heading, .heading, .heading, .heading])
        #expect(outline.map(\.indent.level) == [0, 1, 0, 1])
    }
    
    
    @Test func parseSwiftOutlineAppliesMarkFormattingAndSectionDepth() async throws {
        
        let source = #"""
            class Foo {
                
                func dog() { }
                // MARK: - Cow
                func cat() { }
            }
        """#
        
        let outline = try await self.parseOutline(in: source, syntax: .swift)
        
        #expect(outline.map(\.title) == ["Foo", "dog", "", "Cow", "cat"])
        #expect(outline.map(\.kind) == [.container, .function, .separator, .mark, .function])
        #expect(outline.map(\.indent.level) == [0, 1, 1, 1, 1])
    }
    
    
    @Test func parseSQLOutlineIsFlattened() async throws {
        
        let source = #"""
            CREATE TABLE users (id INTEGER);
            CREATE FUNCTION twice(i INTEGER) RETURNS INTEGER AS $$
              SELECT i * 2;
            $$ LANGUAGE SQL;
        """#
        
        let outline = try await self.parseOutline(in: source, syntax: .sql)
        
        #expect(outline.map(\.title) == ["users", "twice"])
        #expect(outline.map(\.kind) == [.container, .function])
        #expect(outline.map(\.indent.level) == [0, 0])
    }
    
    
    @Test func parsePythonDecoratedFunctionsRemainSiblings() async throws {
        
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
        
        let outline = try await self.parseOutline(in: source, syntax: .python)
        
        #expect(outline.map(\.title) == ["chunked", "open_text", "timer"])
        #expect(outline.map(\.kind) == [.function, .function, .function])
        #expect(outline.map(\.indent.level) == [0, 0, 0])
    }
    
    
    @Test func parseLuaOutlineHandlesPseudoAndTrueNesting() async throws {
        
        let source = #"""
            function M.sum(a, b)
                return a + b
            end
            
            function M:describe(name)
                return name
            end
            
            M.run = function(input)
                return input
            end
            
            M.pipeline = {
                prepare = function(value)
                    return value
                end,
                execute = function(value)
                    return value
                end,
            }
            
            function M.pipeline:finalize(value)
                return value
            end
            
            local function outer(value)
                local function inner(x)
                    return x
                end
                
                return inner(value)
            end
        """#
        
        let outline = try await self.parseOutline(in: source, syntax: .lua)
        
        #expect(outline.map(\.title) == ["sum", "describe", "run", "prepare", "execute", "finalize", "outer", "inner"])
        #expect(outline.map(\.kind) == [.function, .function, .function, .function, .function, .function, .function, .function])
        #expect(outline.map(\.indent.level) == [0, 0, 0, 0, 0, 0, 0, 1])
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String, syntax: TreeSitterSyntax) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: syntax)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: syntax)
        
        return try await client.parseOutline(in: source)
    }
}
