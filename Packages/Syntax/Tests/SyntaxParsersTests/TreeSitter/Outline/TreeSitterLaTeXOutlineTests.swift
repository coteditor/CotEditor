//
//  TreeSitterLaTeXOutlineTests.swift
//  SyntaxParsersTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-01.
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

struct TreeSitterLaTeXOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineKeepsParenthesizedCaptionTextTogether() async throws {
        
        let source = #"""
            \section{Devices (Portable)}
            \begin{figure}
              \caption{MacBook Pro (Late 2020).}
            \end{figure}
            """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Devices (Portable)",
            "MacBook Pro (Late 2020).",
        ])
        #expect(outline.map(\.kind) == [
            .heading(nil),
            .title,
        ])
        #expect(outline.map(\.indent.level) == [0, 1])
        #expect(nsSource.substring(with: outline[0].range) == "Devices (Portable)")
        #expect(nsSource.substring(with: outline[1].range) == "MacBook Pro (Late 2020).")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .latex)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .latex)
        
        return try await client.parseOutline(in: source)
    }
}
