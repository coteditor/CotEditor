//
//  TreeSitterClient.Content.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-10.
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
import StringUtils
import SwiftTreeSitter

extension TreeSitterClient {
    
    struct Content {
        
        private(set) var string: String
        private(set) var lineStarts: [Int]
        
        
        /// Creates a new content container.
        ///
        /// - Parameter string: The initial content string.
        init(_ string: String = "") {
            
            self.string = string
            self.lineStarts = string.lineStartIndexes()
        }
    }
}


extension TreeSitterClient.Content {
    
    enum EditError: Error {
        
        case invalidRange
        case pointCalculationFailed
    }
    
    
    // MARK: Internal Methods
    
    /// Resets the content and rebuilds the line start cache.
    ///
    /// - Parameters:
    ///   - string: The new content string.
    mutating func reset(_ string: String) {
        
        self.string = string
        self.lineStarts = string.lineStartIndexes()
    }
    
    
    /// Applies an edit and returns the corresponding tree-sitter input edit.
    ///
    /// - Parameters:
    ///   - editedRange: The edited range in the post-edit string.
    ///   - delta: The change in length between pre-edit and post-edit strings.
    ///   - insertedText: The inserted text that occupies `editedRange`.
    /// - Returns: An `InputEdit` describing the change for tree-sitter.
    mutating func applyEdit(editedRange: NSRange, delta: Int, insertedText: String) throws(EditError) -> InputEdit {
        
        guard
            editedRange.location >= 0,
            insertedText.length == editedRange.length
        else { throw .invalidRange }
        
        let oldLength = editedRange.length - delta
        
        guard oldLength >= 0 else { throw .invalidRange }
        
        let preEditRange = NSRange(location: editedRange.location, length: oldLength)
        let preEditString = self.string as NSString
        let preEditLineStarts = self.lineStarts
        
        guard preEditRange.upperBound <= preEditString.length else { throw .invalidRange }
        
        self.string = preEditString.replacingCharacters(in: preEditRange, with: insertedText)
        self.updateLineStartIndexes(preEditRange: preEditRange, editedRange: editedRange, delta: delta, insertedText: insertedText)
        
        guard
            let startPoint = Self.point(at: preEditRange.lowerBound, in: preEditLineStarts),
            let oldEndPoint = Self.point(at: preEditRange.upperBound, in: preEditLineStarts),
            let newEndPoint = Self.point(at: editedRange.upperBound, in: self.lineStarts)
        else { throw .pointCalculationFailed }
        
        return InputEdit(startByte: preEditRange.lowerBound * 2,
                         oldEndByte: preEditRange.upperBound * 2,
                         newEndByte: editedRange.upperBound * 2,
                         startPoint: startPoint,
                         oldEndPoint: oldEndPoint,
                         newEndPoint: newEndPoint)
    }
    
    
    // MARK: Private Methods
    
    /// Returns the tree-sitter point (row/column) at the given UTF-16 location.
    ///
    /// - Parameters:
    ///   - location: The UTF-16 offset in the string.
    ///   - lineStarts: The cached line start locations.
    /// - Returns: The corresponding point, or `nil` if the location is out of bounds.
    private static func point(at location: Int, in lineStarts: [Int]) -> Point? {
        
        guard location >= 0 else { return nil }
        
        let upperIndex = lineStarts.partitioningIndex { $0 > location }
        
        guard upperIndex > lineStarts.startIndex else { return nil }
        
        let row = lineStarts.index(before: upperIndex)
        let lineStart = lineStarts[row]
        let column = location - lineStart
        
        return Point(row: row, column: column)
    }
    
    
    /// Updates cached line start locations to reflect the edit.
    ///
    /// - Parameters:
    ///   - preEditRange: The edited range in the pre-edit string.
    ///   - editedRange: The edited range in the post-edit string.
    ///   - delta: The change in length between pre-edit and post-edit strings.
    ///   - insertedText: The inserted text that occupies `editedRange`.
    private mutating func updateLineStartIndexes(preEditRange: NSRange, editedRange: NSRange, delta: Int, insertedText: String) {
        
        let removalStartIndex = self.lineStarts.partitioningIndex { $0 > preEditRange.location }
        let shiftStartIndex = self.lineStarts.partitioningIndex { $0 > preEditRange.upperBound }
        var insertedLineStarts = insertedText.lineStartIndexes()
        insertedLineStarts.removeFirst()
        
        var lineStarts = Array(self.lineStarts[..<removalStartIndex])
        lineStarts.reserveCapacity(self.lineStarts.count - (shiftStartIndex - removalStartIndex) + insertedLineStarts.count)
        lineStarts.append(contentsOf: insertedLineStarts.map { $0 + editedRange.location })
        lineStarts.append(contentsOf: self.lineStarts[shiftStartIndex...].map { $0 + delta })
        
        self.lineStarts = lineStarts
    }
}


// MARK: -

private extension NSString {
    
    /// Returns the line start locations (UTF-16) for the string.
    ///
    /// - Returns: An array containing all line start locations.
    func lineStartIndexes() -> [Int] {
        
        var lineStarts = [0]
        
        guard self.length > 0 else { return lineStarts }
        
        var location = 0
        while location < self.length {
            var lineEnd = 0
            var contentsEnd = 0
            unsafe self.getLineStart(nil, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: location, length: 0))
            
            guard
                lineEnd > location
            else { break }
            
            if contentsEnd < lineEnd {
                lineStarts.append(lineEnd)
            }
            location = lineEnd
        }
        
        return lineStarts
    }
}
