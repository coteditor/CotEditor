//
//  EditorInfoCounter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2022 1024jp
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

struct EditorInfoTypes: OptionSet {
    
    let rawValue: Int
    
    static let characters = Self(rawValue: 1 << 0)
    static let lines      = Self(rawValue: 1 << 1)
    static let words      = Self(rawValue: 1 << 2)
    static let location   = Self(rawValue: 1 << 3)
    static let line       = Self(rawValue: 1 << 4)
    static let column     = Self(rawValue: 1 << 5)
    static let unicode    = Self(rawValue: 1 << 6)
    
    static let all: Self = [.characters, .lines, .words, .location, .line, .column, .unicode]
    
    static let counts: Self = [.characters, .lines, .words]
    static let cursors: Self = [.location, .line, .column]
}


struct EditorCountResult: Equatable {
    
    struct Count: Equatable {
        
        var characters = 0
        var lines = 0
        var words = 0
    }
    
    
    var count: Count?
    var selectedCount: Count?
    
    var location: Int?  // cursor location from the beginning of document
    var line: Int?   // current line
    var column: Int?   // cursor location from the beginning of line
    
    var unicode: String?  // Unicode of selected single character (or surrogate-pair)
    
    
    
    func format(_ keyPath: KeyPath<Count, Int>) -> String? {
        
        let count = self.count?[keyPath: keyPath]
        
        guard
            let selectedCount = self.selectedCount?[keyPath: keyPath],
            selectedCount > 0
        else { return count?.formatted() }
        
        return "\(count?.formatted() ?? "-") (\(selectedCount.formatted()))"
    }
    
}



// MARK: -

final class EditorInfoCounter {
    
    // MARK: Private Properties
    
    private let string: String
    private let selectedRange: Range<String.Index>
    
    private let requiredInfo: EditorInfoTypes
    private let countsWholeText: Bool
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(string: String, selectedRange: Range<String.Index>, requiredInfo: EditorInfoTypes, countsWholeText: Bool) {
        
        assert(selectedRange.upperBound <= string.endIndex)
        
        self.string = string
        self.selectedRange = selectedRange
        self.requiredInfo = requiredInfo
        self.countsWholeText = countsWholeText
    }
    
    
    
    // MARK: Public Methods
    
    func count() throws -> EditorCountResult {
        
        var result = EditorCountResult()
        
        if self.countsWholeText, !self.requiredInfo.isDisjoint(with: .counts) {
            result.count = try self.count(in: self.string)
        }
        
        if !self.requiredInfo.isDisjoint(with: .counts) {
            result.selectedCount = try self.count(in: self.string[self.selectedRange])
        }
        
        if self.requiredInfo.contains(.location) {
            try Task.checkCancellation()
            result.location = self.string.distance(from: self.string.startIndex,
                                                   to: self.selectedRange.lowerBound) + 1
        }
        
        if self.requiredInfo.contains(.line) {
            try Task.checkCancellation()
            result.line = (self.selectedRange.lowerBound == self.string.startIndex)
                ? 1
                : self.string.numberOfLines(in: self.string.startIndex..<self.selectedRange.lowerBound)
        }
        
        if self.requiredInfo.contains(.column) {
            try Task.checkCancellation()
            let lineStartIndex = self.string.lineStartIndex(at: self.selectedRange.lowerBound)
            result.column = self.string.distance(from: lineStartIndex, to: self.selectedRange.lowerBound) + 1
        }
        
        if self.requiredInfo.contains(.unicode) {
            let selectedString = self.string[self.selectedRange]
            if selectedString.compareCount(with: 1) == .equal {
                result.unicode = selectedString.first?.unicodeScalars.map(\.codePoint).joined(separator: ", ")
            }
        }
        
        return result
    }
    
    
    
    // MARK: Private Methods
    
    private func count(in string: some StringProtocol) throws -> EditorCountResult.Count {
        
        var count = EditorCountResult.Count()
        
        if self.requiredInfo.contains(.characters) {
            try Task.checkCancellation()
            count.characters = string.count
        }
        
        if self.requiredInfo.contains(.lines) {
            try Task.checkCancellation()
            count.lines = string.numberOfLines
        }
        
        if self.requiredInfo.contains(.words) {
            try Task.checkCancellation()
            count.words = string.numberOfWords
        }
        
        return count
    }
    
}
