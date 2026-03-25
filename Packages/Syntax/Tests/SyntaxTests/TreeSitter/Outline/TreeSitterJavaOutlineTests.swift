//
//  TreeSitterJavaOutlineTests.swift
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

struct TreeSitterJavaOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesMethodParameters() async throws {
        
        let source = #"""
            interface Formatter {
                String format(String input);
                <T> T parse(Class<T> type, String value);
            }
            
            public final class Service {
                public Service(String name) {
                }
                
                protected <T extends Comparable<T>> T pickFirst(T left, T right) {
                    return left;
                }
                
                private static String join(String delimiter, String... parts) {
                    return String.join(delimiter, parts);
                }
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Formatter",
            "format(String input)",
            "parse(Class<T> type, String value)",
            "Service",
            "Service(String name)",
            "pickFirst(T left, T right)",
            "join(String delimiter, String... parts)",
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
        #expect(nsSource.substring(with: outline[1].range) == "format(String input)")
        #expect(nsSource.substring(with: outline[2].range) == "parse(Class<T> type, String value)")
        #expect(nsSource.substring(with: outline[4].range) == "Service(String name)")
        #expect(nsSource.substring(with: outline[5].range) == "pickFirst(T left, T right)")
        #expect(nsSource.substring(with: outline[6].range) == "join(String delimiter, String... parts)")
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .java)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .java)
        
        return try await client.parseOutline(in: source)
    }
}
