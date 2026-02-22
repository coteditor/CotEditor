//
//  OutlineTitleFormatter.swift
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

typealias OutlineTitleFormatter = @Sendable (Syntax.Outline.Kind, String) -> String?


struct OutlineNormalizationPolicy: Sendable {
    
    var sectionMarkerKinds: Set<Syntax.Outline.Kind>
    var adjustSectionMarkerDepth: Bool
    
    static let standard = Self(sectionMarkerKinds: [.separator], adjustSectionMarkerDepth: false)
    
    
    func isSectionMarker(kind: Syntax.Outline.Kind?) -> Bool {
        
        kind.map(self.sectionMarkerKinds.contains) ?? false
    }
}


extension TreeSitterSyntax {
    
    /// The outline title formatter for the syntax.
    ///
    /// The formatter receives a trimmed title string.
    var outlineTitleFormatter: OutlineTitleFormatter {
        
        switch self {
            case .css: Self.cssOutlineTitleFormatter
            case .swift: Self.swiftOutlineTitleFormatter
            default: { _, title in title }
        }
    }
    
    
    /// The outline normalization policy for the syntax.
    var outlineNormalizationPolicy: OutlineNormalizationPolicy {
        
        switch self {
            case .swift:
                .init(sectionMarkerKinds: [.separator, .mark], adjustSectionMarkerDepth: true)
            default:
                .standard
        }
    }
    
    
    /// Formats CSS outline titles to keep only the at-rule header.
    private static let cssOutlineTitleFormatter: OutlineTitleFormatter = { _, title in
        
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
    private static let swiftOutlineTitleFormatter: OutlineTitleFormatter = { kind, title in
        
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
}
