//
//  TreeSitterTypeScriptOutlineTests.swift
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

struct TreeSitterTypeScriptOutlineTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test func outlineIncludesTypeParametersAndAnnotations() async throws {
        
        let source = #"""
            interface Loader {
                find?<T>(id: string): Promise<T | undefined>;
            }
            
            abstract class Service {
                abstract fetch<T>(id: string): Promise<T>;
            }
            
            class UserService extends Service {
                constructor(private readonly baseURL: string) {
                }
                
                #load<T>(path: string): Promise<T> {
                    throw new Error(path);
                }
            }
            
            function log<T>(value: T, label?: string): T {
                return value;
            }
            
            function* entries<T>(items: readonly T[]): IterableIterator<T> {
                yield* items;
            }
            
            declare function parse<T>(input: string): T;
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Loader",
            "find?<T>(id: string)",
            "Service",
            "fetch<T>(id: string)",
            "UserService",
            "constructor(private readonly baseURL: string)",
            "#load<T>(path: string)",
            "log<T>(value: T, label?: string)",
            "entries<T>(items: readonly T[])",
            "parse<T>(input: string)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .function,
            .container,
            .function,
            .container,
            .function,
            .function,
            .function,
            .function,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 1, 0, 1, 0, 1, 1, 0, 0, 0])
        #expect(nsSource.substring(with: outline[1].range) == "find?<T>(id: string)")
        #expect(nsSource.substring(with: outline[3].range) == "fetch<T>(id: string)")
        #expect(nsSource.substring(with: outline[5].range) == "constructor(private readonly baseURL: string)")
        #expect(nsSource.substring(with: outline[6].range) == "#load<T>(path: string)")
        #expect(nsSource.substring(with: outline[7].range) == "log<T>(value: T, label?: string)")
        #expect(nsSource.substring(with: outline[8].range) == "entries<T>(items: readonly T[])")
        #expect(nsSource.substring(with: outline[9].range) == "parse<T>(input: string)")
    }


    @Test func outlineIncludesProperties() async throws {
        
        let source = #"""
            interface Loader {
                baseURL?: string;
            }
            
            class UserService {
                public host = "example.com";
                
                constructor(
                    private readonly baseURL: string,
                    protected cacheKey?: string,
                    timeout: number,
                ) {
                }
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Loader",
            "baseURL",
            "UserService",
            "host",
            "constructor(private readonly baseURL: string, protected cacheKey?: string, timeout: number)",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .value,
            .container,
            .value,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 1, 0, 1, 1])
        #expect(nsSource.substring(with: outline[1].range) == "baseURL")
        #expect(nsSource.substring(with: outline[3].range) == "host")
        #expect(nsSource.substring(with: outline[4].range) == "constructor(\n            private readonly baseURL: string,\n            protected cacheKey?: string,\n            timeout: number,\n        )")
    }
    
    
    @Test func outlineIncludesAssignedCallablesAndComputedMethods() async throws {
        
        let source = #"""
            const replacer: (key: string, value: unknown) => unknown = function (key, value) {
                return value
            }
            
            const asyncTask = async <T>(value: T): Promise<T> => value
            const identity = value => value
            
            class Service {
                [Symbol.asyncIterator](): AsyncIterator<string> {
                    throw new Error()
                }
            }
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "replacer",
            "asyncTask",
            "identity",
            "Service",
            "[Symbol.asyncIterator]()",
        ])
        #expect(outline.map(\.kind) == [
            .function,
            .function,
            .function,
            .container,
            .function,
        ])
        #expect(outline.map(\.indent.level) == [0, 0, 0, 0, 1])
        #expect(nsSource.substring(with: outline[3].range) == "Service")
    }
    
    
    @Test func outlineIncludesModulesAndTypeAliases() async throws {
        
        let source = #"""
            const enum Flag {
                Read = 1
            }
            
            namespace Legacy {
                export type LegacyID = string
                
                export function parse(input: string): string {
                    return input
                }
            }
            
            module Compat {
                export function migrate(): void {
                }
            }
            
            type ID = string | number | bigint
            type ReadonlyRecord<K extends PropertyKey, V> = {
                readonly [P in K]?: V
            }
            export type PublicID = ID
        """#
        let nsSource = source as NSString
        
        let outline = try await self.parseOutline(in: source)
        
        #expect(outline.map(\.title) == [
            "Flag",
            "Legacy",
            "LegacyID",
            "parse(input: string)",
            "Compat",
            "migrate()",
            "ID",
            "ReadonlyRecord",
            "PublicID",
        ])
        #expect(outline.map(\.kind) == [
            .container,
            .container,
            .value,
            .function,
            .container,
            .function,
            .value,
            .value,
            .value,
        ])
        #expect(outline.map(\.indent.level) == [0, 0, 1, 1, 0, 1, 0, 0, 0])
        #expect(nsSource.substring(with: outline[0].range) == "Flag")
        #expect(nsSource.substring(with: outline[1].range) == "Legacy")
        #expect(nsSource.substring(with: outline[2].range) == "LegacyID")
        #expect(nsSource.substring(with: outline[4].range) == "Compat")
        #expect(nsSource.substring(with: outline[6].range) == "ID")
        #expect(nsSource.substring(with: outline[7].range) == "ReadonlyRecord")
        #expect(nsSource.substring(with: outline[8].range) == "PublicID")
    }


    // MARK: Private Methods
    
    private func parseOutline(in source: String) async throws -> [OutlineItem] {
        
        let config = try self.registry.configuration(for: .typeScript)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: .typeScript)
        
        return try await client.parseOutline(in: source)
    }
}
