//
//  MarkdownOutlineFormatter.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-23.
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
import SyntaxFormat

enum MarkdownOutlineFormatter: TreeSitterOutlineFormatting {
    
    /// Formats a Markdown outline title by stripping ATX prefixes and setext underlines.
    ///
    /// - Parameters:
    ///   - title: The raw title text.
    ///   - kind: The outline item kind.
    /// - Returns: The formatted title, or `nil` to exclude the item.
    static func formatTitle(_ title: String, kind: Syntax.Outline.Kind) -> String? {
        
        guard case .heading = kind else { return title }
        
        let lines = title
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        // -> Setext headings end with the underline line.
        let normalized = if lines.count > 1 {
            lines.dropLast()
                .map { $0.trimmingPrefix(/(?:>[ \t]*)+/) }  // block quote markers
                .joined(separator: " ")
        } else {
            (lines.first ?? "")
                .replacing(/^#{1,6}[ \t]*/, with: "")  // ATX prefix
                .replacing(/(?:^|[ \t]+)#+[ \t]*$/, with: "")  // optional ATX closing
        }
        
        return normalized.isEmpty ? nil : normalized
    }
}
