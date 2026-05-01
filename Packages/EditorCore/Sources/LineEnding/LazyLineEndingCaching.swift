//
//  LazyLineEndingCaching.swift
//  LineEnding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2026 1024jp
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
import ValueRange

protocol LazyLineEndingCaching: AnyObject, LineRangeCalculating {
    
    /// The source string to parse line endings.
    var string: String { get }
    
    /// Line Endings sorted by location.
    var lineEndings: [ValueRange<LineEnding>] { get set }
    
    /// The first character index not yet parsed.
    var firstUnparsedIndex: Int { get set }
}


extension LazyLineEndingCaching {
    
    /// The UTF16-based length of the content string (implementation of `LineRangeCalculating`).
    public var length: Int {
        
        self.string.utf16.count
    }
    
    
    /// Calculates and caches `lineEndings` up to the line that contains the given character index, if not already done.
    ///
    /// - Parameters:
    ///   - characterIndex: The character index where needs the line number.
    ///   - needsNextEnd: Whether needs the next line ending to ensure the line range for the given `characterIndex`.
    func ensureLineEndings(upTo characterIndex: Int, needsNextEnd: Bool = false) {
        
        assert(characterIndex <= self.string.utf16.count)
        
        guard characterIndex >= self.firstUnparsedIndex else { return }
        
        guard self.length > 0 else { return }
        
        let parseRange = NSRange(self.firstUnparsedIndex..<characterIndex)
        var parsedRange = NSRange(location: NSNotFound, length: 0)
        var lineEndings = self.string.lineEndingRanges(in: parseRange, effectiveRange: &parsedRange)
        
        if needsNextEnd {
            let parsedUpper: Int
            if let next = self.string.nextLineEnding(at: parsedRange.upperBound) {
                lineEndings.append(next)
                parsedUpper = next.upperBound
            } else {
                parsedUpper = self.length
            }
            parsedRange = NSRange(parsedRange.lowerBound..<parsedUpper)
        }
        
        self.lineEndings.replace(items: lineEndings, in: parsedRange)
        self.firstUnparsedIndex = parsedRange.upperBound
    }
}
