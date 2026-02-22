//
//  LanguageRegistry+Parser.swift
//  Syntax

//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-25.
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

import SwiftTreeSitter

public extension LanguageRegistry {
    
    /// Returns the parser and feature support for the given tree-sitter syntax.
    ///
    /// - Parameters:
    ///   - syntax: The tree-sitter syntax to look up in the registry.
    /// - Returns: A tuple of the parser and the supported features derived from available queries.
    /// - Throws: Any error that occurs while resolving the language layer.
    func parser(syntax: TreeSitterSyntax) throws -> (parser: (any HighlightParsing & OutlineParsing), support: TreeSitterSyntax.FeatureSupport) {
        
        let config = try self.configuration(for: syntax)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.languageProvider, syntax: syntax)
        
        return (client, TreeSitterSyntax.FeatureSupport(queries: config.queries))
    }
}


public extension TreeSitterSyntax {
    
    struct FeatureSupport: OptionSet, Sendable {
        
        public var rawValue: Int
        
        public static let highlight = Self(rawValue: 1 << 0)
        public static let outline   = Self(rawValue: 1 << 1)
        
        
        public init(rawValue: Int) {
            
            self.rawValue = rawValue
        }
        
        
        init(queries: [Query.Definition: Query]) {
            
            self = .init()
                .union((queries[.highlights] != nil) ? .highlight : [])
                .union((queries[.outline] != nil) ? .outline : [])
        }
    }
}
