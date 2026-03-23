//
//  TreeSitterSyntax+Outline.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-16.
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
import SwiftTreeSitter

extension TreeSitterSyntax {
    
    /// The outline behavior policy for the syntax.
    var outlinePolicy: OutlinePolicy {
        
        switch self {
            case .go:
                .init(ignoredDepthNodeTypes: ["type_spec"])
            case .lua:
                .init(ignoredDepthNodeTypes: [
                    "identifier",
                    "dot_index_expression",
                    "method_index_expression",
                    "function_declaration",
                    "variable_list",
                    "expression_list",
                    "assignment_statement",
                    "table_constructor",
                    "field",
                ])
            case .python:
                .init(ignoredDepthNodeTypes: ["decorated_definition"])
            case .sql:
                .init(normalization: .init(flattenLevels: true))
            case .swift:
                .init(normalization: .init(sectionMarkerKinds: [.separator, .mark], adjustSectionMarkerDepth: true))
            default:
                .init()
        }
    }
    
    
    /// The outline formatter type for the syntax.
    var outlineFormatter: any TreeSitterOutlineFormatting.Type {
        
        switch self {
            case .c:
                COutlineFormatter.self
            case .css:
                CSSOutlineFormatter.self
            case .go:
                GoOutlineFormatter.self
            case .markdown:
                MarkdownOutlineFormatter.self
            case .rust:
                RustOutlineFormatter.self
            case .scala:
                ScalaOutlineFormatter.self
            case .sql:
                SQLOutlineFormatter.self
            case .swift:
                SwiftOutlineFormatter.self
            default:
                DefaultOutlineFormatter.self
        }
    }
}
