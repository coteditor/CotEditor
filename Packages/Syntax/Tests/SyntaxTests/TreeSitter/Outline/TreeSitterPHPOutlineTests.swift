//
//  TreeSitterPHPOutlineTests.swift
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

actor TreeSitterPHPOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlinePHPIncludesParameterClauses() async throws {
        
        let source = #"""
            <?php
            
            interface Formatter
            {
                public function format(string $input): string;
            }
            
            final class User
            {
                public function __construct(
                    public int $id,
                    public string $name,
                ) {}
                
                public function label(string $prefix = 'user'): string
                {
                    return sprintf('%s:%d:%s', $prefix, $this->id, $this->name);
                }
            }
            
            function export(array &$target, string|int ...$values): void
            {
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Formatter",
            "format(string $input)",
            "User",
            "__construct(public int $id, public string $name)",
            "label(string $prefix = 'user')",
            "export(array &$target, string|int ...$values)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .function,
            .container,
            .function,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 1, 0, 1, 1, 0])
        #expect(nsSource.substring(with: outline[1].range) == "format(string $input)")
        #expect(nsSource.substring(with: outline[3].range) == "__construct(\n            public int $id,\n            public string $name,\n        )")
        #expect(nsSource.substring(with: outline[4].range) == "label(string $prefix = 'user')")
        #expect(nsSource.substring(with: outline[5].range) == "export(array &$target, string|int ...$values)")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .php)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .php)
        
        return try await client.parseOutline(in: source)
    }
}
