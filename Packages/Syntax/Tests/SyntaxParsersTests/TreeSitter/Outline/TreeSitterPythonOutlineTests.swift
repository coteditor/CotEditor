//
//  TreeSitterPythonOutlineTests.swift
//  SyntaxParsersTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-23.
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
import SyntaxFormat
@testable import SyntaxParsers

struct TreeSitterPythonOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesParameterClauses() async throws {
        
        let source = #"""
            class Token:
                def __init__(self, kind: str, value: str = "word"):
                    self.kind = kind
            
            def traced(fn):
                def wrapper(*args, **kwargs):
                    return fn(*args, **kwargs)
                
                return wrapper
            
            @contextmanager
            def open_text(path: Path, encoding: str = "utf-8"):
                yield path
            
            @asynccontextmanager
            async def timer(label: str, *, log: bool = True):
                yield
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Token",
            "__init__(self, kind: str, value: str = \"word\")",
            "traced(fn)",
            "wrapper(*args, **kwargs)",
            "open_text(path: Path, encoding: str = \"utf-8\")",
            "timer(label: str, *, log: bool = True)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .function,
            .function,
            .function,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 1, 0, 1, 0, 0])
        #expect(nsSource.substring(with: outline[1].range) == "__init__(self, kind: str, value: str = \"word\")")
        #expect(nsSource.substring(with: outline[2].range) == "traced(fn)")
        #expect(nsSource.substring(with: outline[3].range) == "wrapper(*args, **kwargs)")
        #expect(nsSource.substring(with: outline[4].range) == "open_text(path: Path, encoding: str = \"utf-8\")")
        #expect(nsSource.substring(with: outline[5].range) == "timer(label: str, *, log: bool = True)")
    }
    
    
    @Test func outlineIncludesClassVariables() async throws {
        
        let source = #"""
            class Cache:
                initial_position = None
                fps: int = 60
                
                def resolve(self, key: str) -> str:
                    return key
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Cache",
            "initial_position",
            "fps",
            "resolve(self, key: str)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .value,
            .value,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 1, 1, 1])
        #expect(nsSource.substring(with: outline[1].range) == "initial_position")
        #expect(nsSource.substring(with: outline[2].range) == "fps")
        #expect(nsSource.substring(with: outline[3].range) == "resolve(self, key: str)")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .python)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .python)
        
        return try await client.parseOutline(in: source)
    }
}
