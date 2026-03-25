//
//  LanguageRegistryTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-10.
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
import StringUtils
import ValueRange
@testable import Syntax

actor LanguageRegistryTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test(arguments: TreeSitterSyntax.allCases)
    func configuration(for syntax: TreeSitterSyntax) throws {
        
        #expect(throws: Never.self) { try self.registry.configuration(for: syntax) }
    }
    
    
    @Test func parserBuildsWorkingSwiftParser() async throws {
        
        let source = #"""
            class Foo {
                
                func bar() { }
            }
        """#
        let nsSource = source as NSString
        
        let parser = try self.registry.parser(syntax: .swift)
        let highlights = try #require(await parser.parseHighlights(in: source, range: source.nsRange))
        let outline = try await parser.parseOutline(in: source)
        
        #expect(highlights.highlights.contains {
            $0.value == .keywords && nsSource.substring(with: $0.range) == "func"
        })
        #expect(outline.map(\.title) == ["Foo", "bar()"])
        #expect(outline.map(\.kind) == [.container, .function])
    }
}
