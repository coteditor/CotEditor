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
        
        #expect(highlights.count == 26)
        #expect(highlights[0] == ValueRange(value: .comments, range: NSRange(location: 4, length: 27)))
        #expect(highlights[1] == ValueRange(value: .attributes, range: NSRange(location: 36, length: 1)))
        #expect(highlights[2] == ValueRange(value: .types, range: NSRange(location: 37, length: 10)))
        #expect(highlights[3] == ValueRange(value: .attributes, range: NSRange(location: 37, length: 10)))
        #expect(highlights[4] == ValueRange(value: .keywords, range: NSRange(location: 48, length: 4)))
        #expect(highlights[5] == ValueRange(value: .commands, range: NSRange(location: 53, length: 15)))
        #expect(highlights[6] == ValueRange(value: .variables, range: NSRange(location: 69, length: 2)))
        #expect(highlights[7] == ValueRange(value: .variables, range: NSRange(location: 72, length: 6)))
        #expect(highlights[8] == ValueRange(value: .types, range: NSRange(location: 80, length: 6)))
        #expect(highlights[9] == ValueRange(value: .variables, range: NSRange(location: 88, length: 5)))
        #expect(highlights[10] == ValueRange(value: .types, range: NSRange(location: 95, length: 7)))
        #expect(highlights[11] == ValueRange(value: .keywords, range: NSRange(location: 104, length: 5)))
        #expect(highlights[12] == ValueRange(value: .keywords, range: NSRange(location: 110, length: 6)))
        #expect(highlights[13] == ValueRange(value: .types, range: NSRange(location: 121, length: 10)))
        #expect(highlights[14] == ValueRange(value: .keywords, range: NSRange(location: 152, length: 4)))
        #expect(highlights[15] == ValueRange(value: .variables, range: NSRange(location: 157, length: 5)))
        #expect(highlights[16] == ValueRange(value: .variables, range: NSRange(location: 163, length: 14)))
        #expect(highlights[17] == ValueRange(value: .commands, range: NSRange(location: 163, length: 14)))
        #expect(highlights[18] == ValueRange(value: .keywords, range: NSRange(location: 209, length: 3)))
        #expect(highlights[19] == ValueRange(value: .variables, range: NSRange(location: 235, length: 21)))
        #expect(highlights[20] == ValueRange(value: .keywords, range: NSRange(location: 274, length: 6)))
        #expect(highlights[21] == ValueRange(value: .keywords, range: NSRange(location: 281, length: 3)))
        #expect(highlights[22] == ValueRange(value: .keywords, range: NSRange(location: 285, length: 4)))
        #expect(highlights[23] == ValueRange(value: .variables, range: NSRange(location: 290, length: 5)))
        #expect(highlights[24] == ValueRange(value: .variables, range: NSRange(location: 296, length: 10)))
        #expect(highlights[25] == ValueRange(value: .commands, range: NSRange(location: 296, length: 10)))
    }
}
