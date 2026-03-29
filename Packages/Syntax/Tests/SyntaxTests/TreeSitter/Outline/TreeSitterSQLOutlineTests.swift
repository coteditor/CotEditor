//
//  TreeSitterSQLOutlineTests.swift
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
import SyntaxFormat
@testable import SyntaxParsers

struct TreeSitterSQLOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineFlattensTopLevelEntries() async throws {
        
        let source = #"""
            CREATE TABLE users (id INTEGER);
            CREATE FUNCTION twice(i INTEGER) RETURNS INTEGER AS $$
              SELECT i * 2;
            $$ LANGUAGE SQL;
        """#
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == ["users", "twice(INTEGER)"])
        #expect(outline.map(\.kind) == [.container, .function])
        #expect(outline.map(\.indent.level) == [0, 0])
    }
    
    
    @Test func outlineIncludesSchemaAndArgumentTypes() async throws {
        
        let source = #"""
            CREATE FUNCTION public.twice(i integer) RETURNS integer AS $$
              SELECT i * 2;
            $$ LANGUAGE SQL;
            
            CREATE FUNCTION add_user(IN user_id integer, state public.user_state, display_name text DEFAULT 'x', VARIADIC tags text[]) RETURNS integer AS $$
              SELECT 1;
            $$ LANGUAGE SQL;
            
            CREATE PROCEDURE sync_users(INOUT count integer, threshold DOUBLE PRECISION) AS $$
              SELECT 1;
            $$;
            
            CREATE PROCEDURE reset_cache AS $$
              SELECT 1;
            $$;
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "public.twice(integer)",
            "add_user(integer, public.user_state, text, text[])",
            "sync_users(integer, DOUBLE PRECISION)",
            "reset_cache",
        ])
        #expect(outline.map(\.kind) == [.function, .function, .function, .function])
        #expect(outline.map(\.indent.level) == [0, 0, 0, 0])
        #expect(nsSource.substring(with: outline[0].range) == "public.twice(i integer)")
        #expect(nsSource.substring(with: outline[1].range) == "add_user(IN user_id integer, state public.user_state, display_name text DEFAULT 'x', VARIADIC tags text[])")
        #expect(nsSource.substring(with: outline[2].range) == "sync_users(INOUT count integer, threshold DOUBLE PRECISION)")
        #expect(nsSource.substring(with: outline[3].range) == "reset_cache")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .sql)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .sql)
        
        return try await client.parseOutline(in: source)
    }
}
