//
//  TreeSitterHTMLOutlineTests.swift
//  SyntaxParsersTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-08.
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

struct TreeSitterHTMLOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesNestedInlineElementText() async throws {
        
        let source = #"""
            <!doctype html>
            <html lang="en">
              <head>
                <title>Guide for <code>CotEditor</code></title>
              </head>
              <body>
                <h1>Overview</h1>
                <h2><code>uncomment</code></h2>
                <h3>Use <code>code</code> blocks</h3>
                <figure>
                  <figcaption>Result for <code>sample()</code></figcaption>
                </figure>
                <table>
                  <caption>Fish &amp; Chips</caption>
                </table>
              </body>
            </html>
            """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Guide for CotEditor",
            "Overview",
            "uncomment",
            "Use code blocks",
            "Result for sample()",
            "Fish &amp; Chips",
        ])
        #expect(outline.map(\.kind) == [
            .title,
            .heading(nil),
            .heading(nil),
            .heading(nil),
            .title,
            .title,
        ])
        #expect(nsSource.substring(with: outline[2].range) == "uncomment")
    }
    
    
    @Test func outlineHandlesQuotedGreaterThanInsideInlineAttributes() async throws {
        
        let source = #"""
            <h2>See <a title="1 > 0">details</a></h2>
            """#
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == ["See details"])
        #expect(outline.map(\.kind) == [.heading(nil)])
    }
    
    
    @Test func outlineIgnoresAttributeWhitespaceBetweenInlineTextNodes() async throws {
        
        let source = #"""
            <h2>A<span class="x y">B</span>C</h2>
            """#
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == ["ABC"])
        #expect(outline.map(\.kind) == [.heading(nil)])
    }
    
    
    // MARK: Private Methods
    
    /// Parses outline items from an HTML source snippet using the shared HTML tree-sitter configuration.
    ///
    /// - Parameter source: The HTML source to parse.
    /// - Returns: The extracted outline items.
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .html)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .html)
        
        return try await client.parseOutline(in: source)
    }
}
