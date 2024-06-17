//
//  Command.swift
//
//  SyntaxMap
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-18.
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
import ArgumentParser
import SyntaxMap

@main
struct Command: ParsableCommand {
    
    @Argument(help: "A path to the Syntaxes directory.")
    var input: URL
    
    @Argument(help: "The path to the result JSON file.")
    var output: URL
    
    
    func run() throws {
        
        let urls = try FileManager.default.contentsOfDirectory(at: self.input, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "yml" }
        let syntaxMap = try SyntaxMap.loadMaps(at: urls)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(syntaxMap)
        try data.write(to: self.output)
    }
}


extension URL: @retroactive ExpressibleByArgument {
    
    public init?(argument: String) {
        
        self.init(filePath: argument)
    }
}
