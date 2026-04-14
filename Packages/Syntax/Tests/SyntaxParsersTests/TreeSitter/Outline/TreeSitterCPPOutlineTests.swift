//
//  TreeSitterCPPOutlineTests.swift
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

struct TreeSitterCPPOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineClassAndMethods() async throws {
        
        let source = #"""
            namespace demo {
        
            class Widget {
            public:
                Widget(const std::string& name) : name_(name) {}
        
                std::string name() const { return name_; }
        
                static Widget create(const std::string& label) {
                    return Widget(label);
                }
        
            private:
                std::string name_;
            };
        
            struct Point {
                double x;
                double y;
        
                Point operator+(const Point& other) const {
                    return {x + other.x, y + other.y};
                }
            };
        
            }
        
            template <typename T>
            T clamp(T value, T low, T high) {
                return value;
            }
        
            int main() {
                return 0;
            }
        """#
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "demo",
            "Widget",
            "Widget(const std::string& name)",
            "name()",
            "create(const std::string& label)",
            "name_",
            "Point",
            "x",
            "y",
            "operator+(const Point& other)",
            "clamp(T value, T low, T high)",
            "main()",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .container,
            .function,
            .function,
            .function,
            .value,
            .container,
            .value,
            .value,
            .function,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 1, 2, 2, 2, 2, 1, 2, 2, 2, 0, 0])
        
        // Verify range covers the function signature (name through parameters)
        let nsSource = source as NSString
        #expect(nsSource.substring(with: outline[3].range) == "name()")
    }
    
    
    @Test func outlineFlattensTemplateDeclarations() async throws {
        
        let source = #"""
            namespace demo {
            
            template <typename T>
            concept Printable = requires(T t) {
                { std::cout << t };
            };
            
            class Widget {
                int id_;
            };
            
            template <typename T>
            T clamp(T value, T low, T high) {
                return value;
            }
            
            }
        """#
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "demo",
            "Printable",
            "Widget",
            "id_",
            "clamp(T value, T low, T high)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .value,
            .container,
            .value,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 1, 1, 2, 1])
    }
    
    
    @Test func outlineFlattensPointerAndArrayFields() async throws {
        
        let source = #"""
            class Widget {
                int flag;
                std::string* label;
                int& ref;
                int values[4];
                char** names;
                int* pointers[4];
                std::string*& handle;
            };
        """#
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == ["Widget", "flag", "label", "ref", "values", "names", "pointers", "handle"])
        #expect(outline.map(\.kind) == [.container, .value, .value, .value, .value, .value, .value, .value])
        #expect(outline.map(\.indent.level) == [0, 1, 1, 1, 1, 1, 1, 1])
    }
    
    
    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .cpp)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .cpp)
        
        return try await client.parseOutline(in: source)
    }
}
