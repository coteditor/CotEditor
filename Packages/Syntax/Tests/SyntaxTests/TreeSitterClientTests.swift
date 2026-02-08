//
//  TreeSitterClientTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-23.
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

actor TreeSitterClientTests {
    
    private let registry: LanguageRegistry = .init()
    
    
    @Test func highlightSwift() async throws {
        
        let source = """
            /// Parses provided string.
            @concurrent func parseHighlights(in string: String, range: NSRange) async throws -> [NamedRange] {
                
                self.layer.replaceContent(with: string)
                
                let textProvider = string.predicateTextProvider
                
                return try self.layer.highlights(in: range, provider: textProvider)
            }
        """
        
        let config = try #require(try self.registry.configuration(for: .swift))
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider)
        let highlights = try await client.parseHighlights(in: source, range: source.nsRange)
        
        #expect(highlights == [
            ValueRange(value: .comments, range: NSRange(location: 4, length: 27)),
            ValueRange(value: .attributes, range: NSRange(location: 36, length: 1)),
            ValueRange(value: .types, range: NSRange(location: 37, length: 10)),
            ValueRange(value: .attributes, range: NSRange(location: 37, length: 10)),
            ValueRange(value: .keywords, range: NSRange(location: 48, length: 4)),
            ValueRange(value: .commands, range: NSRange(location: 53, length: 15)),
            ValueRange(value: .variables, range: NSRange(location: 69, length: 2)),
            ValueRange(value: .variables, range: NSRange(location: 72, length: 6)),
            ValueRange(value: .types, range: NSRange(location: 80, length: 6)),
            ValueRange(value: .variables, range: NSRange(location: 88, length: 5)),
            ValueRange(value: .types, range: NSRange(location: 95, length: 7)),
            ValueRange(value: .keywords, range: NSRange(location: 104, length: 5)),
            ValueRange(value: .keywords, range: NSRange(location: 110, length: 6)),
            ValueRange(value: .types, range: NSRange(location: 121, length: 10)),
            ValueRange(value: .variables, range: NSRange(location: 152, length: 4)),
            ValueRange(value: .variables, range: NSRange(location: 157, length: 5)),
            ValueRange(value: .variables, range: NSRange(location: 163, length: 14)),
            ValueRange(value: .commands, range: NSRange(location: 163, length: 14)),
            ValueRange(value: .keywords, range: NSRange(location: 209, length: 3)),
            ValueRange(value: .variables, range: NSRange(location: 235, length: 21)),
            ValueRange(value: .keywords, range: NSRange(location: 274, length: 6)),
            ValueRange(value: .keywords, range: NSRange(location: 281, length: 3)),
            ValueRange(value: .variables, range: NSRange(location: 285, length: 4)),
            ValueRange(value: .variables, range: NSRange(location: 290, length: 5)),
            ValueRange(value: .variables, range: NSRange(location: 296, length: 10)),
            ValueRange(value: .commands, range: NSRange(location: 296, length: 10)),
        ])
    }
}
