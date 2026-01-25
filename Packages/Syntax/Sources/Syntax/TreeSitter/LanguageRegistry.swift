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

import TreeSitterCSS
import TreeSitterHTML
import TreeSitterSwift

public final class LanguageRegistry: Sendable {
    
    /// Supported languages.
    public enum Language: String, Sendable {
        
        case css = "CSS"
        case html = "HTML"
        case swift = "Swift"
        
        
        public static let internalLanguages: [Self] = []
        
        public var name: String { self.rawValue }
    }
    
    
    // MARK: Public Properties
    
    public static let shared: LanguageRegistry = .init()
    
    
    // MARK: Private Properties
    
    private let directoryURL: URL
    private let cachedConfiguration: Mutex<[Language: LanguageConfiguration]> = .init([:])
    
    
    // MARK: Lifecycle
    
    init() {
        
        self.directoryURL = Bundle.module.url(forResource: "Syntaxes", withExtension: nil)!
    }
    
    
    // MARK: Internal Methods
    
    /// Returns a provider mapping from a language provider/injection name to its `LanguageConfiguration`.
    ///
    /// - Parameters:
    ///   - name: The provider or injection name (e.g., "javascript", "markdown_inline").
    /// - Returns: A cached or newly created `LanguageConfiguration` if the language is supported, otherwise `nil`.
    nonisolated func languageProvider(name: String) -> LanguageConfiguration? {
        
        guard let language = Language(providerName: name) else { return nil }
        
        return try? self.configuration(for: language)
    }
    
    
    /// Returns (and caches) a `LanguageConfiguration` for the given language.
    ///
    /// - Parameters:
    ///   - language: The target language.
    /// - Returns: A configuration if the language can be initialized.
    nonisolated func configuration(for language: Language) throws -> LanguageConfiguration? {
        
        if let cache = self.cachedConfiguration.withLock({ $0[language] }) {
            return cache
        }
        
        let queriesURL = self.queriesURL(for: language)
        
        guard (try? queriesURL.checkResourceIsReachable()) == true else { return nil }
        
        let config = try unsafe LanguageConfiguration(language.language, name: language.name, queriesURL: queriesURL)
        self.cachedConfiguration.withLock { $0[language] = config }
        
        return config
    }
    
    
    // MARK: Private Methods
    
    /// Returns the file URL to the queries directory for the given language.
    ///
    /// - Parameters:
    ///   - language: The target language.
    /// - Returns: A file URL.
    private nonisolated func queriesURL(for language: Language) -> URL {
        
        switch language {
            default:
                self.directoryURL.appending(components: language.name, "Queries")
        }
    }
}


// MARK: -

private extension LanguageRegistry.Language {
    
    /// Resolves from provider/injection name.
    init?(providerName: String) {
        
        switch providerName.lowercased() {
            case "css": self = .css
            case "html": self = .html
            case "swift": self = .swift
            default: return nil
        }
    }
    
    
    /// The provider/injection name.
    var providerName: String {
        
        switch self {
            case .css: "css"
            case .html: "html"
            case .swift: "swift"
        }
    }
    
    /// The tree-sitter language pointer.
    var language: OpaquePointer {
        
        switch self {
            case .css: unsafe tree_sitter_css()
            case .html: unsafe tree_sitter_html()
            case .swift: unsafe tree_sitter_swift()
        }
    }
}
