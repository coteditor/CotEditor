//
//  TreeSitterCSharpOutlineTests.swift
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

struct TreeSitterCSharpOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesMethodSignatures() async throws {
        
        let source = #"""
            namespace Demo.Core;
            
            interface IRepository {
                T? Find<T>(string id, CancellationToken cancellationToken = default);
            }
            
            sealed class Service : IDisposable {
                public Service(string name) {
                }
                
                ~Service() {
                }
                
                public void Run<T>(ref int count, string name = "demo") {
                    static int Add<TValue>(TValue left, int right) => right;
                    _ = Add(count, 1);
                }
                
                void IDisposable.Dispose() {
                }
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Demo.Core",
            "IRepository",
            "Find<T>(string id, CancellationToken cancellationToken = default)",
            "Service",
            "Service(string name)",
            "~Service()",
            "Run<T>(ref int count, string name = \"demo\")",
            "Add<TValue>(TValue left, int right)",
            "IDisposable.Dispose()",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .container,
            .function,
            .container,
            .function,
            .function,
            .function,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 0, 1, 0, 1, 1, 1, 2, 1])
        #expect(nsSource.substring(with: outline[2].range) == "Find<T>(string id, CancellationToken cancellationToken = default)")
        #expect(nsSource.substring(with: outline[4].range) == "Service(string name)")
        #expect(nsSource.substring(with: outline[5].range) == "~Service()")
        #expect(nsSource.substring(with: outline[6].range) == "Run<T>(ref int count, string name = \"demo\")")
        #expect(nsSource.substring(with: outline[7].range) == "Add<TValue>(TValue left, int right)")
        #expect(nsSource.substring(with: outline[8].range) == "IDisposable.Dispose()")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .cSharp)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .cSharp)
        
        return try await client.parseOutline(in: source)
    }
}
