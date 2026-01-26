//
//  TreeSitterSyntax+OutlinePolicy.swift
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

extension TreeSitterSyntax {
    
    /// The outline behavior policy for the syntax.
    var outlinePolicy: OutlinePolicy {
        
        switch self {
            case .css:
                .init(titleFormatter: Self.cssOutlineTitleFormatter)
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
            case .markdown:
                .init(titleFormatter: Self.markdownOutlineTitleFormatter)
            case .sql:
                .init(normalization: .init(flattenLevels: true))
            case .swift:
                .init(titleFormatter: Self.swiftOutlineTitleFormatter,
                      normalization: .init(sectionMarkerKinds: [.separator, .mark], adjustSectionMarkerDepth: true))
            default:
                .init()
        }
    }
    
    /// Formats CSS outline titles to keep only the at-rule header.
    private static let cssOutlineTitleFormatter: OutlinePolicy.TitleFormatter = { _, title in
        
        let header = if let index = title.firstIndex(of: "{") ?? title.firstIndex(of: ";") {
            title[..<index]
        } else {
            title[...]
        }
        
        let normalized = header.replacing(/\s+/, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return normalized.isEmpty ? nil : normalized
    }
    
    
    /// Formats Swift outline titles with MARK comment handling.
    private static let swiftOutlineTitleFormatter: OutlinePolicy.TitleFormatter = { kind, title in
        
        guard kind == .mark else { return title }
        
        let trimmed = if let match = title.wholeMatch(of: /\/\/ +(.+)/)  // inline comment
                            ?? title.wholeMatch(of: /\/\* +(.+) +\*\//)  // block comment
        {
            String(match.output.1)
        } else {
            title
        }
        let comment = trimmed.replacing(/^MARK:\s*-?\s*/, with: "")
        
        return comment.isEmpty ? nil : comment
    }
    
    
    /// Formats Markdown outline titles with setext heading handling.
    private static let markdownOutlineTitleFormatter: OutlinePolicy.TitleFormatter = { kind, title in
        
        guard kind == .heading else { return title }
        
        // Setext headings include the underline on following lines.
        let firstLine = title.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            .first.map(String.init) ?? title
        
        let normalized = firstLine
            .replacing(/^#{1,6}[ \t]*/, with: "")  // ATX prefix
            .replacing(/[ \t]*#+[ \t]*$/, with: "")  // optional ATX closing
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return normalized.isEmpty ? nil : normalized
    }
}
