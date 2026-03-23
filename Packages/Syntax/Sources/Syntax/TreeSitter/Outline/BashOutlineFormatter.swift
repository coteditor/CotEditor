//
//  BashOutlineFormatter.swift
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
import SwiftTreeSitter

enum BashOutlineFormatter: TreeSitterOutlineFormatting {
    
    /// Builds an outline item from a resolved Bash outline match.
    ///
    /// - Parameters:
    ///   - match: The resolved query match.
    ///   - source: The source text as `NSString`.
    ///   - policy: The outline policy for the syntax.
    /// - Returns: An outline item for the match, or `nil` if the match should be ignored.
    static func item(for match: QueryMatch, source: NSString, policy: OutlinePolicy) -> OutlineItem? {
        
        guard let capture = match.outlineCapture(policy: policy) else { return nil }
        
        guard capture.kind == .function else {
            return Self.defaultItem(for: match, source: source, policy: policy)
        }
        
        let title = source.substring(with: capture.range) + "()"
        guard let displayTitle = Self.formatTitle(title, kind: capture.kind) else { return nil }
        
        return OutlineItem(title: displayTitle,
                           range: Self.signatureRange(for: capture.range, source: source),
                           kind: capture.kind,
                           indent: .level(capture.depth))
    }
}


private extension BashOutlineFormatter {
    
    /// Returns the Bash signature range, including `()` when present in source.
    ///
    /// - Parameters:
    ///   - nameRange: The captured function name range.
    ///   - source: The source text as `NSString`.
    /// - Returns: The signature range.
    static func signatureRange(for nameRange: NSRange, source: NSString) -> NSRange {
        
        guard nameRange.upperBound < source.length else { return nameRange }
        
        let suffixRange = NSRange(location: nameRange.upperBound, length: source.length - nameRange.upperBound)
        let suffix = source.substring(with: suffixRange)
        
        guard let match = suffix.firstMatch(of: /^\s*\(\)/) else { return nameRange }
        
        let matchedLength = match.output.utf16.count
        
        return NSRange(location: nameRange.location, length: nameRange.length + matchedLength)
    }
}
