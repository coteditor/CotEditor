//
//  Command.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-18.
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

import Foundation
import ArgumentParser
import Syntax

@main
struct Command: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "A command-line tool to migrate CotEditor's legacy syntax definitions in YAML to the CotEditor Syntax format used since CotEditor 7."
    )
    
    @Argument(help: "A path to a legacy syntax file or a directory containing legacy syntax files.", transform: { URL(filePath: $0) })
    var path: URL
    
    @Option(name: .customLong("out"), help: "The path to the output directory.", transform: { URL(filePath: $0) })
    var destinationURL: URL?
    
    @Flag(help: "whether to keep the original.")
    var keep: Bool = false
    
    
    func run() throws {
        
        if try self.path.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true {
            try Syntax.migrateFormat(in: self.path, to: self.destinationURL, deletingOriginal: !self.keep)
        } else {
            try Syntax.migrate(fileURL: self.path, to: self.destinationURL, deletingOriginal: !self.keep)
        }
    }
}
