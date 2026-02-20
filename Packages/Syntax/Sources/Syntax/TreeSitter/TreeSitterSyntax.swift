//
//  TreeSitterSyntax.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-01-23.
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

public enum TreeSitterSyntax: String, CaseIterable, Sendable {
    
    case css = "CSS"
    case go = "Go"
    case html = "HTML"
    case java = "Java"
    case javaScript = "JavaScript"
    case php = "PHP"
    case python = "Python"
    case ruby = "Ruby"
    case rust = "Rust"
    case scala = "Scala"
    case swift = "Swift"
    case typeScript = "TypeScript"
    
    var name: String { self.rawValue }
}
