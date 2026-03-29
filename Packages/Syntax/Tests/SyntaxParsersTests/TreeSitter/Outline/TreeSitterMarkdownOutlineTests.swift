//
//  TreeSitterMarkdownOutlineTests.swift
//  SyntaxParsersTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-25.
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

import Testing
import SyntaxFormat
@testable import SyntaxParsers

struct TreeSitterMarkdownOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func parseOutlineCapturesATXAndSetextHeadings() async throws {
        
        let source = """
                     # Top
                     
                     ## Section
                     
                     Setext One
                     ==========
                     
                     Setext Two
                     ----------
                     
                     ---
                     """
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == ["Top", "Section", "Setext One", "Setext Two"])
        #expect(outline.map(\.kind) == [.heading(nil), .heading(nil), .heading(nil), .heading(nil)])
        #expect(outline.map(\.indent.level) == [0, 1, 0, 1])
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .markdown)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .markdown)
        
        return try await client.parseOutline(in: source)
    }
}
