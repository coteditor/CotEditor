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

/// A reverse-lookup table that maps file-mapping items (extensions, filenames, interpreters) to syntax setting names.
public struct SyntaxMappingTable: Equatable, Sendable {
    
    enum SyntaxName {
        
        static let xml = "XML"
    }
    
    
    // MARK: Public Properties
    
    public private(set) var extensions: [String: [String]]
    public private(set) var filenames: [String: [String]]
    public private(set) var interpreters: [String: [String]]
    
    public var isEmpty: Bool {
        
        self.extensions.isEmpty && self.filenames.isEmpty && self.interpreters.isEmpty
    }
    
    
    // MARK: Lifecycle
    
    public init(extensions: [String: [String]] = [:], filenames: [String: [String]] = [:], interpreters: [String: [String]] = [:]) {
        
        self.extensions = extensions
        self.filenames = filenames
        self.interpreters = interpreters
    }
    
    
    /// Creates a mapping table by building reverse-lookup dictionaries from the given file maps.
    ///
    /// - Parameters:
    ///   - syntaxNames: The syntax names sorted by priority (earlier names take precedence).
    ///   - maps: The file maps for each setting.
    public init(syntaxNames: [String], maps: [String: Syntax.FileMap]) {
        
        self.extensions = Self.buildMapping(for: \.extensions, syntaxNames: syntaxNames, maps: maps)
        self.filenames = Self.buildMapping(for: \.filenames, syntaxNames: syntaxNames, maps: maps)
        self.interpreters = Self.buildMapping(for: \.interpreters, syntaxNames: syntaxNames, maps: maps)
    }
    
    
    // MARK: Public Methods
    
    /// Returns the syntax name that matches the given filename or its extension.
    ///
    /// - Parameter filename: The filename to look up.
    /// - Returns: A setting name, or `nil` if no match is found.
    public func syntaxName(forFilename filename: String) -> String? {
        
        if let name = self.filenames[filename]?.first {
            return name
        }
        
        guard let pathExtension = filename.split(separator: ".").last else { return nil }
        
        if let name = self.extensions[String(pathExtension)]?.first {
            return name
        }
        
        // check case-insensitively
        let lowerPathExtension = pathExtension.lowercased()
        return self.extensions
            .first { $0.key.lowercased() == lowerPathExtension }?
            .value.first
    }
    
    
    /// Returns the syntax name by scanning the shebang or XML declaration in the content.
    ///
    /// - Parameter content: The document content to inspect.
    /// - Returns: A setting name, or `nil` if no match is found.
    public func syntaxName(forContent content: String) -> String? {
        
        if let interpreter = Self.scanInterpreterInShebang(content),
           let name = self.interpreters[interpreter]?.first
        {
            return name
        }
        
        // check XML declaration
        if content.hasPrefix("<?xml ") {
            return SyntaxName.xml
        }
        
        return nil
    }
    
    
    // MARK: Private Methods
    
    /// Parses a shebang (#!) at the beginning of the given string and returns the interpreter name.
    ///
    /// - Parameter source: The source text to scan.
    /// - Returns: The interpreter name if found; otherwise `nil`.
    static func scanInterpreterInShebang(_ source: String) -> String? {
        
        guard
            let shebang = source.firstMatch(of: /^#!\s*(?<first>\S+)\s*(?<second>\S+)?/),
            let interpreter = shebang.first.split(separator: "/").last
        else { return nil }
        
        // use first arg if the path targets env
        if interpreter == "env", let second = shebang.second {
            return String(second)
        }
        
        return String(interpreter)
    }
    
    
    /// Builds a single mapping dictionary for the given file map key path.
    ///
    /// - Parameters:
    ///   - keyPath: The key path into `Syntax.FileMap` to build the mapping for.
    ///   - syntaxNames: The syntax names sorted by priority.
    ///   - maps: The file maps for each setting.
    /// - Returns: A dictionary mapping file-mapping items to their associated syntax names.
    private static func buildMapping(for keyPath: KeyPath<Syntax.FileMap, [String]?>, syntaxNames: [String], maps: [String: Syntax.FileMap]) -> [String: [String]] {
        
        syntaxNames.reduce(into: [String: [String]]()) { table, name in
            for item in maps[name]?[keyPath: keyPath] ?? [] {
                table[item, default: []].append(name)
            }
        }
    }
}
