//
//  TreeSitterJavaScriptOutlineTests.swift
//  SyntaxTests
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
@testable import Syntax

struct TreeSitterJavaScriptOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesParameterClauses() async throws {
        
        let source = #"""
            class User {
              constructor(id, name) {
                this.id = id;
                this.name = name;
              }
            
              label(prefix = "user") {
                return `${prefix}:${this.id}:${this.name}`;
              }
            
              #secret(value, { force = false } = {}) {
                return force ? value : null;
              }
            }
            
            function score(users, factor = 1) {
              return users.length * factor;
            }
            
            function* entries(items) {
              yield* items;
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "User",
            "constructor(id, name)",
            "label(prefix = \"user\")",
            "#secret(value, { force = false } = {})",
            "score(users, factor = 1)",
            "entries(items)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .function,
            .function,
            .function,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 1, 1, 1, 0, 0])
        #expect(nsSource.substring(with: outline[1].range) == "constructor(id, name)")
        #expect(nsSource.substring(with: outline[2].range) == "label(prefix = \"user\")")
        #expect(nsSource.substring(with: outline[3].range) == "#secret(value, { force = false } = {})")
        #expect(nsSource.substring(with: outline[4].range) == "score(users, factor = 1)")
        #expect(nsSource.substring(with: outline[5].range) == "entries(items)")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .javaScript)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .javaScript)
        
        return try await client.parseOutline(in: source)
    }
}
