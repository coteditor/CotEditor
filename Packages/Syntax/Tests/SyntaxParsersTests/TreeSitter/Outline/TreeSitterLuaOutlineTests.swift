//
//  TreeSitterLuaOutlineTests.swift
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

struct TreeSitterLuaOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesParameterClausesWhileKeepingPseudoNestingFlat() async throws {
        
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
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "sum(a, b)",
            "describe(name)",
            "run(input)",
            "prepare(value)",
            "execute(value)",
            "finalize(value)",
            "outer(value)",
            "inner(x)",
        ])
        #expect(outline.map(\.kind) == [.function, .function, .function, .function, .function, .function, .function, .function])
        #expect(outline.map(\.indent.level) == [0, 0, 0, 0, 0, 0, 0, 1])
        #expect(nsSource.substring(with: outline[0].range) == "sum(a, b)")
        #expect(nsSource.substring(with: outline[1].range) == "describe(name)")
        #expect(nsSource.substring(with: outline[2].range) == "run = function(input)")
        #expect(nsSource.substring(with: outline[3].range) == "prepare = function(value)")
        #expect(nsSource.substring(with: outline[4].range) == "execute = function(value)")
        #expect(nsSource.substring(with: outline[5].range) == "finalize(value)")
        #expect(nsSource.substring(with: outline[6].range) == "outer(value)")
        #expect(nsSource.substring(with: outline[7].range) == "inner(x)")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .lua)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .lua)
        
        return try await client.parseOutline(in: source)
    }
}
