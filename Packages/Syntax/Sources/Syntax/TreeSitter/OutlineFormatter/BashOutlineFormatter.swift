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
    
    static func functionSignature(for match: QueryMatch, capture: OutlineCapture, source: NSString) -> (title: String, range: NSRange) {
        
        (title: source.substring(with: capture.range) + "()",
         range: Self.signatureRange(for: capture.range, source: source))
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
