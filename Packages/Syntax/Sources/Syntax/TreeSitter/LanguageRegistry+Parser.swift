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
    
    /// Returns highlight and outline parsers for the given tree-sitter syntax when available.
    ///
    /// - Parameters:
    ///   - syntax: The tree-sitter syntax to look up in the registry.
    /// - Returns: A tuple of optional parsers for highlights and outline.
    /// - Throws: Any error that occurs while resolving the language layer.
    func parsers(syntax: TreeSitterSyntax) throws -> (highlight: (any HighlightParsing)?, outline: (any OutlineParsing)?) {
        
        let config = try self.configuration(for: syntax)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.languageProvider, syntax: syntax)
        
        return ((config.queries[.highlights] != nil) ? client : nil,
                (config.queries[.outline] != nil) ? client : nil)
    }
}
