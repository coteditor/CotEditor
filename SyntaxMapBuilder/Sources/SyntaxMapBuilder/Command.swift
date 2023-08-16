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
//  © 2020-2023 1024jp
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
import ArgumentParser
import Yams

private struct Syntax: Codable {
    
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
    var input: URL
    
    @Argument(help: "The path to the result JSON file.")
    var output: URL
    
    
    func run() throws {
        
        try buildSyntaxMap(directoryURL: self.input)
            .write(to: self.output)
    }
}


func buildSyntaxMap(directoryURL: URL) throws -> Data {
    
    // find syntax files
    let urls = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension == "yml" }
    
    // build syntaxMap from syntax files
    let decoder = YAMLDecoder()
    let syntaxMap: [String: [String: [String]]] = try urls.reduce(into: [:]) { (map, url) in
        let syntaxName = url.deletingPathExtension().lastPathComponent
        let yaml = try String(contentsOf: url)
        let syntax = try decoder.decode(Syntax.self, from: yaml)
        
        map[syntaxName] = [
            "extensions": syntax.extensions,
            "filenames": syntax.filenames,
            "interpreters": syntax.interpreters,
        ]
            .mapValues { $0?.map(\.keyString) ?? [] }
    }
    
    // encode syntaxMap to JSON style
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    return try encoder.encode(syntaxMap)
}



extension URL: ExpressibleByArgument {
    
    public init?(argument: String) {
        
        self.init(filePath: argument)
    }
}
