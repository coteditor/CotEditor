//
//  Command.swift
//
//  SyntaxMapBuilder
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2022 1024jp
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
import UniformTypeIdentifiers
import ArgumentParser
import Yams

private struct SyntaxStyle: Codable {
    
    struct StringItem: Codable {
        
        var keyString: String
    }
    
    var extensions: [StringItem]?
    var filenames: [StringItem]?
    var interpreters: [StringItem]?
}


@main
struct Command: ParsableCommand {
    
    @Argument(help: "A path to the Syntaxes directory.")
    var directoryPath: String
    
    
    func run() throws {
        
        let url = URL(filePath: self.directoryPath, directoryHint: .isDirectory)
        let json = try buildSyntaxMap(directoryURL: url)
        
        print(json)
    }
    
}


func buildSyntaxMap(directoryURL: URL) throws -> String {
    
    // find syntax style files
    let urls = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.contentTypeKey])
        .filter { try $0.resourceValues(forKeys: [.contentTypeKey]).contentType?.conforms(to: .yaml) == true }
    
    // build syntaxMap from syntax style files
    let decoder = YAMLDecoder()
    let syntaxMap: [String: [String: [String]]] = try urls.reduce(into: [:]) { (map, url) in
        let styleName = url.deletingPathExtension().lastPathComponent
        let yaml = try String(contentsOf: url)
        let style = try decoder.decode(SyntaxStyle.self, from: yaml)
        
        map[styleName] = [
            "extensions": style.extensions,
            "filenames": style.filenames,
            "interpreters": style.interpreters,
        ]
            .mapValues { $0?.map(\.keyString) ?? [] }
    }
    
    // encode syntaxMap to JSON style
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(syntaxMap)
    let json = String(data: data, encoding: .utf8)!
    
    return json
}
