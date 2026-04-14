//
//  TreeSitterCOutlineTests.swift
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

struct TreeSitterCOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesFunctionSignatures() async throws {
        
        let source = #"""
            typedef struct User {
                int id;
            } User;
            
            static int add(int a, int b) {
                return a + b;
            }
            
            static const char *find_name(int id) {
                return "";
            }
            
            static char **alloc_names(size_t count) {
                return 0;
            }
            
            static void print_user(const User *user, ...) {
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "User",
            "id",
            "add(int a, int b)",
            "find_name(int id)",
            "alloc_names(size_t count)",
            "print_user(const User *user, ...)",
        ])
        #expect(outline.map(\.kind) == [.container, .value, .function, .function, .function, .function])
        #expect(outline.map(\.indent.level) == [0, 1, 0, 0, 0, 0])
        #expect(nsSource.substring(with: outline[2].range) == "add(int a, int b)")
        #expect(nsSource.substring(with: outline[3].range) == "find_name(int id)")
        #expect(nsSource.substring(with: outline[4].range) == "alloc_names(size_t count)")
        #expect(nsSource.substring(with: outline[5].range) == "print_user(const User *user, ...)")
    }
    
    
    @Test func outlineFlattensPointerAndArrayFields() async throws {
        
        let source = #"""
            struct Box {
                int flag;
                const char *label;
                int values[4];
                char **names;
                int *pointers[4];
            };
        """#
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == ["Box", "flag", "label", "values", "names", "pointers"])
        #expect(outline.map(\.kind) == [.container, .value, .value, .value, .value, .value])
        #expect(outline.map(\.indent.level) == [0, 1, 1, 1, 1, 1])
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .c)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .c)
        
        return try await client.parseOutline(in: source)
    }
}
