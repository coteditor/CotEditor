//
//  TreeSitterBashOutlineTests.swift
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

struct TreeSitterBashOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineShowsFunctionNotation() async throws {
        
        let source = #"""
            readonly APP_NAME="coteditor"
            
            log_info() {
              echo "[$APP_NAME] $1"
            }
            
            function cleanup {
              rm -f "$1"
            }
            
            main () {
              log_info "hello"
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "APP_NAME",
            "log_info()",
            "cleanup()",
            "main()",
        ])
        #expect(outline.map(\.kind) == [
            .value,
            .function,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 0, 0, 0])
        #expect(nsSource.substring(with: outline[1].range) == "log_info()")
        #expect(nsSource.substring(with: outline[2].range) == "cleanup")
        #expect(nsSource.substring(with: outline[3].range) == "main ()")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .bash)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .bash)
        
        return try await client.parseOutline(in: source)
    }
}
