//
//  main.swift
//
//  SyntaxMapBuilder
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

private struct SyntaxStyle: Codable {
    
    struct StringItem: Codable {
        
        var keyString: String
    }
    
    var extensions: [StringItem]?
    var filenames: [StringItem]?
    var interpreters: [StringItem]?
}


private func buildSyntaxMap(directoryPath: String) throws -> String {
    
    // find syntax style files
    let directoryURL = URL(fileURLWithPath: directoryPath, isDirectory: true)
    let urls = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "yaml" }
    
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


guard CommandLine.arguments.count > 1 else { exit(1) }

let json = try buildSyntaxMap(directoryPath: CommandLine.arguments[1])

print(json)
