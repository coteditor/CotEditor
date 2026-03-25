//
//  TreeSitterScalaOutlineTests.swift
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

struct TreeSitterScalaOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesParameterClauses() async throws {
        
        let source = #"""
            trait Foldable {
                
                def size: Int
                def foldLeft[A, B](seed: B)(step: (B, A) => B): B
            }
            
            object Numbers {
                
                def empty(): Unit = ()
                def sum(a: Int, b: Int): Int = a + b
                def sorted(using ord: Ordering[Int]): List[Int] = Nil
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Foldable",
            "size",
            "foldLeft(seed)(step)",
            "Numbers",
            "empty()",
            "sum(a, b)",
            "sorted(using ord)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .function,
            .function,
            .container,
            .function,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 1, 1, 0, 1, 1, 1])
        #expect(nsSource.substring(with: outline[1].range) == "size")
        #expect(nsSource.substring(with: outline[2].range) == "foldLeft[A, B](seed: B)(step: (B, A) => B)")
        #expect(nsSource.substring(with: outline[4].range) == "empty()")
        #expect(nsSource.substring(with: outline[5].range) == "sum(a: Int, b: Int)")
        #expect(nsSource.substring(with: outline[6].range) == "sorted(using ord: Ordering[Int])")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .scala)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .scala)
        
        return try await client.parseOutline(in: source)
    }
}
