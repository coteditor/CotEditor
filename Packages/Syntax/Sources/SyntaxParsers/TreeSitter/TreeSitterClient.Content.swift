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
        private(set) var lineStarts: IndexSet
        
        
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
        
        guard insertedText.length == editedRange.length else { throw .invalidRange }
        
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
    private static func point(at location: Int, in lineStarts: IndexSet) -> Point? {
        
        guard
            location >= 0,
            let lineStart = lineStarts.rangeView(of: 0...location).last?.lowerBound
        else { return nil }
        
        let row = lineStarts.count(in: 0..<lineStart)
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
        
        var lineStarts = self.lineStarts
        
        let removalLowerBound = preEditRange.location + 1
        let removalUpperBound = preEditRange.upperBound + 1
        if removalLowerBound < removalUpperBound {
            lineStarts.remove(integersIn: removalLowerBound..<removalUpperBound)
        }
        
        if delta != 0 {
            lineStarts.shift(startingAt: preEditRange.upperBound, by: delta)
        }
        
        var insertedLineStarts = insertedText.lineStartIndexes()
        insertedLineStarts.remove(0)
        if !insertedLineStarts.isEmpty {
            insertedLineStarts.shift(startingAt: 0, by: editedRange.location)
            lineStarts.formUnion(insertedLineStarts)
        }
        
        lineStarts.insert(0)
        
        self.lineStarts = lineStarts
    }
}


// MARK: -

private extension NSString {
    
    /// Returns the line start locations (UTF-16) for the string.
    ///
    /// - Returns: An index set containing all line start locations.
    func lineStartIndexes() -> IndexSet {
        
        var lineStarts = IndexSet()
        lineStarts.insert(0)
        
        guard self.length > 0 else { return lineStarts }
        
        var location = 0
        while location < self.length {
            var lineEnd = 0
            unsafe self.getLineStart(nil, end: &lineEnd, contentsEnd: nil, for: NSRange(location: location, length: 0))
            
            guard
                lineEnd < self.length,
                lineEnd > location
            else { break }
            
            lineStarts.insert(lineEnd)
            location = lineEnd
        }
        
        return lineStarts
    }
}
