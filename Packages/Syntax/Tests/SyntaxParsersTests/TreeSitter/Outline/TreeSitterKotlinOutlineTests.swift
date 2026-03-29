//
//  TreeSitterKotlinOutlineTests.swift
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

struct TreeSitterKotlinOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesFunctionParameters() async throws {
        
        let source = #"""
            interface Formatter {
                fun format(input: String): String
            }
        
            class Service(val name: String) {
                fun process(data: List<Int>, flag: Boolean): Result {
                    return Result.success()
                }
        
                companion object {
                    fun create(config: Map<String, Any>): Service {
                        return Service("default")
                    }
                }
            }
        
            object Singleton {
                fun getInstance(): Singleton = this
            }
        
            fun topLevel(x: Int, y: Int): Int = x + y
        """#
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Formatter",
            "format(input: String)",
            "Service",
            "process(data: List<Int>, flag: Boolean)",
            "create(config: Map<String, Any>)",
            "Singleton",
            "getInstance()",
            "topLevel(x: Int, y: Int)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .function,
            .container,
            .function,
            .function,
            .container,
            .function,
            .function,
        ])
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .kotlin)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .kotlin)
        
        return try await client.parseOutline(in: source)
    }
}
