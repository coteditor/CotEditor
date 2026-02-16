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
    
    /// Returns a syntax highlight parser for the given language name.
    ///
    /// - Parameters:
    ///   - name: The language name to look up in the registry.
    /// - Returns: A `HighlightParsing` client when the language layer exists, or `nil` if not found.
    /// - Throws: Any error that occurs while resolving the language layer.
    func highlightParser(name: String) throws -> (any HighlightParsing)? {
        
        guard
            let syntax = TreeSitterSyntax(rawValue: name),
            let config = try self.configuration(for: syntax)
        else { return nil }
        
        return try TreeSitterClient(languageConfig: config, languageProvider: self.languageProvider)
    }
}
