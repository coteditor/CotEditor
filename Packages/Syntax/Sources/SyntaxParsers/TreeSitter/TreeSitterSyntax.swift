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

public import SyntaxFormat

import TreeSitterBash
import TreeSitterC
import TreeSitterCPP
import TreeSitterCSharp
import TreeSitterCSS
import TreeSitterGo
import TreeSitterHTML
import TreeSitterJava
import TreeSitterJavaScript
import TreeSitterKotlin
import TreeSitterLatex
import TreeSitterLua
import TreeSitterMake
import TreeSitterMarkdown
import TreeSitterPHP
import TreeSitterPython
import TreeSitterRuby
import TreeSitterRust
import TreeSitterScala
import TreeSitterSql
import TreeSitterSwift
import TreeSitterTypeScript

public enum TreeSitterSyntax: String, CaseIterable, Sendable {
    
    case bash = "Bash"
    case c = "C"
    case cpp = "C++"
    case cSharp = "C#"
    case css = "CSS"
    case go = "Go"
    case html = "HTML"
    case java = "Java"
    case javaScript = "JavaScript"
    case kotlin = "Kotlin"
    case latex = "LaTeX"
    case lua = "Lua"
    case makefile = "Makefile"
    case markdown = "Markdown"
    case php = "PHP"
    case python = "Python"
    case ruby = "Ruby"
    case rust = "Rust"
    case scala = "Scala"
    case sql = "SQL"
    case swift = "Swift"
    case typeScript = "TypeScript"
    
    var name: String  { self.rawValue }
    
    
    /// Supported features.
    public var features: ParserFeatures {
        
        switch self {
            case .markdown: [.outline]
            default: [.highlight, .outline]
        }
    }
    
    
    /// The provider/injection name.
    var providerName: String {
        
        switch self {
            case .cSharp: "c_sharp"
            case .makefile: "make"
            default: self.rawValue.lowercased()
        }
    }
    
    
    /// The tree-sitter language pointer.
    var language: OpaquePointer {
        
        switch self {
            case .bash: unsafe tree_sitter_bash()
            case .c: unsafe tree_sitter_c()
            case .cpp: unsafe tree_sitter_cpp()
            case .cSharp: unsafe tree_sitter_c_sharp()
            case .css: unsafe tree_sitter_css()
            case .go: unsafe tree_sitter_go()
            case .html: unsafe tree_sitter_html()
            case .java: unsafe tree_sitter_java()
            case .javaScript: unsafe tree_sitter_javascript()
            case .kotlin: unsafe tree_sitter_kotlin()
            case .latex: unsafe tree_sitter_latex()
            case .lua: unsafe tree_sitter_lua()
            case .makefile: unsafe tree_sitter_make()
            case .markdown: unsafe tree_sitter_markdown()
            case .php: unsafe tree_sitter_php()
            case .python: unsafe tree_sitter_python()
            case .ruby: unsafe tree_sitter_ruby()
            case .rust: unsafe tree_sitter_rust()
            case .scala: unsafe tree_sitter_scala()
            case .sql: unsafe tree_sitter_sql()
            case .swift: unsafe tree_sitter_swift()
            case .typeScript: unsafe tree_sitter_typescript()
        }
    }
}
