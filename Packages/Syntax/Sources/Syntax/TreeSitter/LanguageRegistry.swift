//
//  LanguageRegistry.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-23.
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
import Synchronization
import SwiftTreeSitter

import TreeSitterBash
import TreeSitterC
import TreeSitterCSS
import TreeSitterGo
import TreeSitterHTML
import TreeSitterJava
import TreeSitterJavaScript
import TreeSitterLua
import TreeSitterMake
import TreeSitterPHP
import TreeSitterPython
import TreeSitterRuby
import TreeSitterRust
import TreeSitterScala
import TreeSitterSql
import TreeSitterSwift
import TreeSitterTypeScript

extension Query.Definition {
    
    static let outline = Self.custom("outline")
}


public final class LanguageRegistry: Sendable {
    
    enum RegistryError: Error {
        
        case noQueriesDirectory
        case emptyQueries
    }
    
    
    // MARK: Public Properties
    
    public static let shared: LanguageRegistry = .init()
    
    
    // MARK: Private Properties
    
    private let directoryURL: URL
    private let cachedConfiguration: Mutex<[TreeSitterSyntax: LanguageConfiguration]> = .init([:])
    
    
    // MARK: Lifecycle
    
    init() {
        
        self.directoryURL = Bundle.module.url(forResource: "Queries", withExtension: nil)!
    }
    
    
    // MARK: Internal Methods
    
    /// Returns a provider mapping from a language provider/injection name to its `LanguageConfiguration`.
    ///
    /// - Parameters:
    ///   - name: The provider or injection name (e.g., "javascript", "markdown_inline").
    /// - Returns: A cached or newly created `LanguageConfiguration` if the language is supported, otherwise `nil`.
    nonisolated func languageProvider(name: String) -> LanguageConfiguration? {
        
        guard let syntax = TreeSitterSyntax(providerName: name) else { return nil }
        
        return try? self.configuration(for: syntax)
    }
    
    
    /// Returns (and caches) a `LanguageConfiguration` for the given syntax.
    ///
    /// - Parameters:
    ///   - syntax: The target syntax.
    /// - Returns: A language configuration.
    nonisolated func configuration(for syntax: TreeSitterSyntax) throws(RegistryError) -> LanguageConfiguration {
        
        if let cache = self.cachedConfiguration.withLock({ $0[syntax] }) {
            return cache
        }
        
        let queriesURL = self.queriesURL(for: syntax)
        
        guard (try? queriesURL.checkResourceIsReachable()) == true else { throw .noQueriesDirectory }
        
        let queries = syntax.loadQueries(at: queriesURL)
        
        guard !queries.isEmpty else { throw .emptyQueries }
        
        let config = unsafe LanguageConfiguration(syntax.language, name: syntax.name, queries: queries)
        self.cachedConfiguration.withLock { $0[syntax] = config }
        
        return config
    }
    
    
    /// Returns the file URL to the queries directory for the given syntax.
    ///
    /// - Parameters:
    ///   - syntax: The target syntax.
    /// - Returns: A file URL.
    nonisolated func queriesURL(for syntax: TreeSitterSyntax) -> URL {
        
        self.directoryURL.appending(component: syntax.name)
    }
}


// MARK: -

private extension TreeSitterSyntax {
    
    /// Resolves from provider/injection name.
    init?(providerName: String) {
        
        let lowercased = providerName.lowercased()
        
        guard
            let syntax = Self.allCases.first(where: { $0.providerName == lowercased })
        else { return nil }
        
        self = syntax
    }
    
    
    /// The provider/injection name.
    var providerName: String {
        
        switch self {
            case .makefile: "make"
            default: self.rawValue.lowercased()
        }
    }
    
    
    /// The tree-sitter language pointer.
    var language: OpaquePointer {
        
        switch self {
            case .bash: unsafe tree_sitter_bash()
            case .c: unsafe tree_sitter_c()
            case .css: unsafe tree_sitter_css()
            case .go: unsafe tree_sitter_go()
            case .html: unsafe tree_sitter_html()
            case .java: unsafe tree_sitter_java()
            case .javaScript: unsafe tree_sitter_javascript()
            case .lua: unsafe tree_sitter_lua()
            case .makefile: unsafe tree_sitter_make()
            case .php: unsafe tree_sitter_php()
            case .python: unsafe tree_sitter_python()
            case .ruby: unsafe tree_sitter_ruby()
            case .rust: unsafe tree_sitter_rust()
            case .scala: unsafe tree_sitter_scala()
            case .sql: unsafe tree_sitter_sql()
            case .swift: unsafe tree_sitter_swift()
            case .typeScript: unsafe tree_sitter_typescript()
        }
    }
    
    
    /// Loads query files from the given directory.
    ///
    /// - Parameters:
    ///   - syntax: The target tree-sitter syntax.
    ///   - queriesURL: The queries directory URL.
    /// - Returns: The loaded queries keyed by their definition.
    func loadQueries(at queriesURL: URL) -> [Query.Definition: Query] {
        
        let definitions: [Query.Definition] = [
            .injections,
            .highlights,
            .outline,
        ]
        
        var queries: [Query.Definition: Query] = [:]
        for definition in definitions {
            let queryURL = queriesURL.appending(path: definition.filename)
            
            guard (try? queryURL.resourceValues(forKeys: [.isReadableKey]))?.isReadable == true else { continue }
            
            let language = unsafe Language(self.language)
            do {
                queries[definition] = try Query(language: language, url: queryURL)
            } catch {
                assertionFailure("failed open \(self.name)'s \(queryURL.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        return queries
    }
}
