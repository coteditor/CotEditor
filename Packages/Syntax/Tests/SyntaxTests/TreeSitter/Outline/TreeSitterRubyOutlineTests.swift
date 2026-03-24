//
//  TreeSitterRubyOutlineTests.swift
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

actor TreeSitterRubyOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineRubyIncludesMethodParameters() async throws {
        
        let source = #"""
            def foo a, **b
            end
            
            class Demo
              def label(prefix = "user", count: 1)
              end
              
              def self.build(name, *args, **kwargs, &block)
              end
              
              def empty
              end
            end
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "foo(a, **b)",
            "Demo",
            "label(prefix = \"user\", count: 1)",
            "self.build(name, *args, **kwargs, &block)",
            "empty()",
        ])
        #expect(outline.map(\.kind) == [
            .function,
            .container,
            .function,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 0, 1, 1, 1])
        #expect(nsSource.substring(with: outline[0].range) == "foo a, **b")
        #expect(nsSource.substring(with: outline[2].range) == "label(prefix = \"user\", count: 1)")
        #expect(nsSource.substring(with: outline[3].range) == "self.build(name, *args, **kwargs, &block)")
        #expect(nsSource.substring(with: outline[4].range) == "empty")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .ruby)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .ruby)
        
        return try await client.parseOutline(in: source)
    }
}
