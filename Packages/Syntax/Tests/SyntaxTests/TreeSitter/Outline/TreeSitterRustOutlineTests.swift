//
//  TreeSitterRustOutlineTests.swift
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
@testable import Syntax

actor TreeSitterRustOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineRustIncludesFunctionSignatures() async throws {
        
        let source = #"""
            struct Job;
            
            trait Runner {
                fn run(&mut self, input: &str) -> Result<(), String>;
                fn reset();
            }
            
            impl Job {
                fn new(name: String) -> Self {
                    Self
                }
                
                fn map<const N: usize, T>(values: [T; N]) -> [T; N] {
                    values
                }
            }
            
            fn classify<'a>(value: Option<&'a str>) -> &'a str {
                value.unwrap_or("none")
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Job",
            "Runner",
            "run(&mut self, input: &str)",
            "reset()",
            "Job",
            "new(name: String)",
            "map<const N: usize, T>(values: [T; N])",
            "classify<'a>(value: Option<&'a str>)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .container,
            .function,
            .function,
            .container,
            .function,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 0, 1, 1, 0, 1, 1, 0])
        #expect(nsSource.substring(with: outline[2].range) == "run(&mut self, input: &str)")
        #expect(nsSource.substring(with: outline[3].range) == "reset()")
        #expect(nsSource.substring(with: outline[5].range) == "new(name: String)")
        #expect(nsSource.substring(with: outline[6].range) == "map<const N: usize, T>(values: [T; N])")
        #expect(nsSource.substring(with: outline[7].range) == "classify<'a>(value: Option<&'a str>)")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .rust)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .rust)
        
        return try await client.parseOutline(in: source)
    }
}
