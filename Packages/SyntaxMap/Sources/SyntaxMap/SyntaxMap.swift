//
//  SyntaxMap.swift
//
//  SyntaxMap
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2024 1024jp
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
import Yams

public struct SyntaxMap: Equatable, Sendable, Codable {
    
    struct InvalidError: Error {
        
        var filename: String
        var underlyingError: any Error
    }
    
    public var extensions: [String]
    public var filenames: [String]
    public var interpreters: [String]

    
    /// Loads SyntaxMap of the given files.
    ///
    /// - Parameters:
    ///   - urls: File URLs of CotEditor's syntax definition files to load.
    ///   - ignoresInvalidData: If `true`, just ignores invalid files and continues scanning, otherwise throws an `InvalidError`.
    /// - Returns: Valid SyntaxMaps.
    public static func loadMaps(at urls: [URL], ignoresInvalidData: Bool = false) throws -> [String: SyntaxMap] {
        
        let decoder = YAMLDecoder()
        
        return try urls.reduce(into: [:]) { (map, url) in
            let syntax: Syntax
            do {
                let data = try Data(contentsOf: url)
                syntax = try decoder.decode(Syntax.self, from: data)
            } catch {
                if ignoresInvalidData {
                    return
                } else {
                    throw InvalidError(filename: url.lastPathComponent, underlyingError: error)
                }
            }
            
            let syntaxName = url.deletingPathExtension().lastPathComponent
            
            map[syntaxName] = SyntaxMap(
                extensions: syntax.extensions?.compactMap(\.keyString) ?? [],
                filenames: syntax.filenames?.compactMap(\.keyString) ?? [],
                interpreters: syntax.interpreters?.compactMap(\.keyString) ?? []
            )
        }
    }
}


private struct Syntax: Codable {
    
    struct KeyString: Codable {
        
        var keyString: String?
    }
    
    var extensions: [KeyString]?
    var filenames: [KeyString]?
    var interpreters: [KeyString]?
}
