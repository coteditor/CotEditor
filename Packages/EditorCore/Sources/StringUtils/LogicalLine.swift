//
//  LogicalLine.swift
//  StringUtils
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-04.
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

package import Foundation

package struct LogicalLine: Equatable, Sendable {
    
    /// The line contents excluding line-ending characters.
    package var contents: String
    
    /// The line-ending characters immediately following the contents, or `nil` if absent.
    package var lineEnding: String?
    
    
    /// Creates a logical line.
    ///
    /// - Parameters:
    ///   - contents: The line contents excluding line-ending characters.
    ///   - lineEnding: The line-ending characters immediately following the contents, or `nil` if absent.
    package init(contents: String, lineEnding: String?) {
        
        self.contents = contents
        self.lineEnding = lineEnding
    }
}


package extension String {
    
    /// Splits the range into logical lines preserving existing line endings.
    ///
    /// - Parameter range: The range to split.
    /// - Returns: Logical lines with their trailing line endings.
    func logicalLines(in range: NSRange) -> [LogicalLine] {
        
        let string = self as NSString
        let ranges = self.lineContentsRanges(for: range)
        
        return ranges.enumerated().map { index, lineRange in
            let upperBound = ranges.indices.contains(index + 1)
                ? ranges[index + 1].lowerBound
                : range.upperBound
            let lineEndingRange = NSRange(lineRange.upperBound..<upperBound)
            let lineEnding = lineEndingRange.isEmpty ? nil : string.substring(with: lineEndingRange)
            
            return LogicalLine(contents: string.substring(with: lineRange), lineEnding: lineEnding)
        }
    }
}


package extension Collection where Element == LogicalLine {
    
    /// Joins lines preserving line endings.
    ///
    /// - Parameters:
    ///   - baseLineEnding: The line ending to add when a line without one moves before a line-ending slot.
    ///   - includingTrailingLineEnding: Whether to include a line ending after the final line.
    /// - Returns: A joined string.
    func joined(baseLineEnding: String, includingTrailingLineEnding: Bool = false) -> String {
        
        self.enumerated()
            .map { offset, line in
                let isLast = (offset == self.count - 1)
                let lineEnding = (isLast && !includingTrailingLineEnding) ? "" : (line.lineEnding ?? baseLineEnding)
                
                return line.contents + lineEnding
            }
            .joined()
    }
}
