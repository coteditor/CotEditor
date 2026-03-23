//
//  TreeSitterSwiftOutlineTests.swift
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

actor TreeSitterSwiftOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func formatSwift() {
        
        let policy = TreeSitterSyntax.swift.outlinePolicy
        
        #expect(policy.titleFormatter(.function, "SomeFunction") == "SomeFunction")
        #expect(policy.titleFormatter(.mark, "// MARK: Swift") == "Swift")
        #expect(policy.titleFormatter(.mark, "// MARK: - Swift") == "Swift")
        #expect(policy.titleFormatter(.mark, "/* MARK: Swift */") == "Swift")
        #expect(policy.titleFormatter(.mark, "// MARK:") == nil)
    }
    
    
    @Test func outlineSwift() async throws {
        
        let source = #"""
            class Foo {
                
                func dog() { }
                // MARK: - Cow
                func cat() { }
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.count == 5)
        #expect(outline[0].title == "Foo")
        #expect(outline[0].kind == .container)
        #expect(outline[0].indent == .level(0))
        #expect(outline[1].title == "dog()")
        #expect(outline[1].kind == .function)
        #expect(outline[1].indent == .level(1))
        #expect(nsSource.substring(with: outline[1].range) == "dog()")
        #expect(outline[2].title.isEmpty)
        #expect(outline[2].kind == .separator)
        #expect(outline[2].indent == .level(1))
        #expect(outline[3].title == "Cow")
        #expect(outline[3].kind == .mark)
        #expect(outline[3].indent == .level(1))
        #expect(outline[4].title == "cat()")
        #expect(outline[4].kind == .function)
        #expect(outline[4].indent == .level(1))
        #expect(nsSource.substring(with: outline[4].range) == "cat()")
    }
    
    
    @Test func outlineSwiftIncludesParameterLabels() async throws {
        
        let source = #"""
            class Foo {
                
                func plain() { }
                func labeled(value: Int, at index: Int) { }
                func mixed(_ value: Int, label other: String) { }
                init(value: Int) { }
                subscript(_ index: Int, named name: String) -> String { "" }
                deinit { }
            }
            
            protocol Bar {
                
                func protocolMethod(value: Int, at index: Int)
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Foo",
            "plain()",
            "labeled(value:at:)",
            "mixed(_:label:)",
            "init(value:)",
            "subscript(_:named:)",
            "deinit",
            "Bar",
            "protocolMethod(value:at:)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .function,
            .function,
            .function,
            .function,
            .function,
            .function,
            .container,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 1, 1, 1, 1, 1, 1, 0, 1])
        #expect(nsSource.substring(with: outline[1].range) == "plain()")
        #expect(nsSource.substring(with: outline[2].range) == "labeled(value: Int, at index: Int)")
        #expect(nsSource.substring(with: outline[3].range) == "mixed(_ value: Int, label other: String)")
        #expect(nsSource.substring(with: outline[4].range) == "init(value: Int)")
        #expect(nsSource.substring(with: outline[5].range) == "subscript(_ index: Int, named name: String)")
        #expect(nsSource.substring(with: outline[6].range) == "deinit")
        #expect(nsSource.substring(with: outline[8].range) == "protocolMethod(value: Int, at index: Int)")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .swift)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .swift)
        
        return try await client.parseOutline(in: source)
    }
}
