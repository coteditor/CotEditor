//
//  TreeSitterClientPendingRangeTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-28.
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
import StringUtils
import SyntaxFormat
@testable import SyntaxParsers

struct TreeSitterClientPendingRangeTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineOnlyParserConsumesPendingRanges() async throws {
        
        let initialSource = "# Top\n"
        let editedSource = "# Top\n## Section\n"
        let config = try self.registry.configuration(for: .markdown)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .markdown)
        
        await client.update(content: initialSource)
        #expect(try self.hasPendingAffectedRanges(client))
        
        _ = try await client.parseOutline(in: initialSource)
        #expect(try !self.hasPendingAffectedRanges(client))
        
        await client.update(content: editedSource)
        #expect(try self.hasPendingAffectedRanges(client))
        
        _ = try await client.parseOutline(in: editedSource)
        #expect(try !self.hasPendingAffectedRanges(client))
    }
    
    
    @Test func highlightCapableParserPreservesPendingRangesUntilHighlightParse() async throws {
        
        let initialSource = "struct Foo {}\n"
        let editedSource = "struct Bar {}\n"
        let config = try self.registry.configuration(for: .swift)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .swift)
        
        await client.update(content: initialSource)
        _ = try #require(await client.parseHighlights(in: initialSource, range: initialSource.nsRange))
        #expect(try !self.hasPendingAffectedRanges(client))
        
        await client.update(content: editedSource)
        #expect(try self.hasPendingAffectedRanges(client))
        
        _ = try await client.parseOutline(in: editedSource)
        #expect(try self.hasPendingAffectedRanges(client))
        
        _ = try #require(await client.parseHighlights(in: editedSource, range: editedSource.nsRange))
        #expect(try !self.hasPendingAffectedRanges(client))
    }
    
    
    // MARK: Private Methods
    
    private func hasPendingAffectedRanges(_ client: TreeSitterClient) throws -> Bool {
        
        let pendingRanges = try #require(Mirror(reflecting: client).descendant("pendingAffectedRanges") as? EditedRangeSet)
        
        return !pendingRanges.isEmpty
    }
}
