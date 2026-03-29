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

public extension LanguageRegistry {
    
    /// Returns the parser and feature support for the given tree-sitter syntax.
    ///
    /// - Parameters:
    ///   - syntax: The tree-sitter syntax to look up in the registry.
    /// - Returns: A tuple of the parser and the supported features derived from available queries.
    /// - Throws: Any error that occurs while resolving the language layer.
    func parser(syntax: TreeSitterSyntax) throws -> any HighlightParsing & OutlineParsing {
        
        let config = try self.configuration(for: syntax)
        
        return try TreeSitterClient(languageConfig: config, languageProvider: self.languageProvider, syntax: syntax)
    }
}
