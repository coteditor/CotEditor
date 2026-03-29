//
//  TreeSitterGoOutlineTests.swift
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

struct TreeSitterGoOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesFunctionSignatures() async throws {
        
        let source = #"""
            package demo
            
            type Buffer struct{}
            
            func Plain(name string, count int) {}
            
            func Empty() {}
            
            func Map[T any](items []T, f func(T) T) []T {
                return nil
            }
            
            func (b *Buffer) ReadAt(p []byte, off int64) (n int, err error) {
                return 0, nil
            }
            
            type Reader interface {
                Read(p []byte) (n int, err error)
                Close() error
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Buffer",
            "Plain(name string, count int)",
            "Empty()",
            "Map[T any](items []T, f func(T) T)",
            "(*Buffer).ReadAt(p []byte, off int64)",
            "Reader",
            "Read(p []byte)",
            "Close()",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .function,
            .function,
            .function,
            .function,
            .container,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 0, 0, 0, 0, 0, 1, 1])
        #expect(nsSource.substring(with: outline[1].range) == "Plain(name string, count int)")
        #expect(nsSource.substring(with: outline[2].range) == "Empty()")
        #expect(nsSource.substring(with: outline[3].range) == "Map[T any](items []T, f func(T) T)")
        #expect(nsSource.substring(with: outline[4].range) == "ReadAt(p []byte, off int64)")
        #expect(nsSource.substring(with: outline[6].range) == "Read(p []byte)")
        #expect(nsSource.substring(with: outline[7].range) == "Close()")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .go)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .go)
        
        return try await client.parseOutline(in: source)
    }
}
