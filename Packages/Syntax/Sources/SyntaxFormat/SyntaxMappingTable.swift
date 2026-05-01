//
//  SyntaxMappingTable.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-11.
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

import URLUtils

/// A reverse-lookup table that maps file-mapping items (extensions, filenames, interpreters) to syntax setting names.
public struct SyntaxMappingTable: Equatable, Sendable {
    
    public typealias SyntaxName = String
    
    
    // MARK: Public Properties
    
    public private(set) var extensions: [String: [SyntaxName]]
    public private(set) var filenames: [String: [SyntaxName]]
    public private(set) var interpreters: [String: [SyntaxName]]
    
    public var isEmpty: Bool {
        
        self.extensions.isEmpty && self.filenames.isEmpty && self.interpreters.isEmpty
    }
    
    
    // MARK: Lifecycle
    
    public init(extensions: [String: [SyntaxName]] = [:], filenames: [String: [SyntaxName]] = [:], interpreters: [String: [SyntaxName]] = [:]) {
        
        self.extensions = extensions.reduce(into: [:]) { table, item in
            table[item.key.lowercased(), default: []].append(contentsOf: item.value)
        }
        self.filenames = filenames
        self.interpreters = interpreters
    }
    
    
    /// Creates a mapping table by building reverse-lookup dictionaries from the given file maps.
    ///
    /// - Parameters:
    ///   - syntaxNames: The syntax names sorted by priority (earlier names take precedence).
    ///   - maps: The file maps for each setting.
    public init(syntaxNames: [SyntaxName], maps: [SyntaxName: Syntax.FileMap]) {
        
        self.extensions = Self.buildMapping(for: \.extensions, syntaxNames: syntaxNames, maps: maps, normalizesKeys: true)
        self.filenames = Self.buildMapping(for: \.filenames, syntaxNames: syntaxNames, maps: maps)
        self.interpreters = Self.buildMapping(for: \.interpreters, syntaxNames: syntaxNames, maps: maps)
    }
    
    
    // MARK: Public Methods
    
    /// Returns the syntax name that matches the given filename or its extension.
    ///
    /// - Parameter filename: The filename to look up.
    /// - Returns: A setting name, or `nil` if no match is found.
    public func syntaxName(forFilename filename: String) -> SyntaxName? {
        
        if let name = self.filenames[filename]?.first {
            return name
        }
        
        guard let pathExtension = filename.pathExtension else { return nil }
        
        return self.extensions[pathExtension.lowercased()]?.first
    }
    
    
    /// Returns the syntax name by scanning the shebang or XML declaration in the content.
    ///
    /// - Parameter content: The document content to inspect.
    /// - Returns: A setting name, or `nil` if no match is found.
    public func syntaxName(forContent content: String) -> SyntaxName? {
        
        if let interpreter = Self.scanInterpreterInShebang(content),
           let name = self.interpreters[interpreter]?.first
        {
            return name
        }
        
        // check XML declaration
        if content.hasPrefix("<?xml ") {
            return "XML"
        }
        
        return nil
    }
    
    
    // MARK: Private Methods
    
    /// Parses a shebang (#!) at the beginning of the given string and returns the interpreter name.
    ///
    /// - Parameter source: The source text to scan.
    /// - Returns: The interpreter name if found; otherwise `nil`.
    static func scanInterpreterInShebang(_ source: String) -> SyntaxName? {
        
        guard
            let shebang = source.firstMatch(of: /^#!\s*(?<first>\S+)(?<rest>[^\n]*)/),
            let interpreter = shebang.first.split(separator: "/").last
        else { return nil }
        
        if interpreter == "env" {
            return shebang.rest
                .split(whereSeparator: \.isWhitespace)
                .first { !$0.hasPrefix("-") }
                .map(String.init)
        }
        
        return String(interpreter)
    }
    
    
    /// Builds a single mapping dictionary for the given file map key path.
    ///
    /// - Parameters:
    ///   - keyPath: The key path into `Syntax.FileMap` to build the mapping for.
    ///   - syntaxNames: The syntax names sorted by priority.
    ///   - maps: The file maps for each setting.
    ///   - normalizesKeys: Whether to lowercase mapping keys while building the table.
    /// - Returns: A dictionary mapping file-mapping items to their associated syntax names.
    private static func buildMapping(for keyPath: KeyPath<Syntax.FileMap, [String]?>, syntaxNames: [SyntaxName], maps: [SyntaxName: Syntax.FileMap], normalizesKeys: Bool = false) -> [String: [String]] {
        
        syntaxNames.reduce(into: [String: [String]]()) { table, name in
            for item in maps[name]?[keyPath: keyPath] ?? [] {
                let key = normalizesKeys ? item.lowercased() : item
                table[key, default: []].append(name)
            }
        }
    }
}
