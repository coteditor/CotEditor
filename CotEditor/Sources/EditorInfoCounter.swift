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

import Foundation

struct EditorInfoTypes: OptionSet {
    
    let rawValue: Int
    
    static let length     = Self(rawValue: 1 << 0)
    static let characters = Self(rawValue: 1 << 1)
    static let lines      = Self(rawValue: 1 << 2)
    static let words      = Self(rawValue: 1 << 3)
    static let location   = Self(rawValue: 1 << 4)
    static let line       = Self(rawValue: 1 << 5)
    static let column     = Self(rawValue: 1 << 6)
    static let unicode    = Self(rawValue: 1 << 7)
    
    static let all: Self = [.length, .characters, .lines, .words, .location, .line, .column, .unicode]
    
    static let counts: Self = [.length, .characters, .lines, .words]
    static let cursors: Self = [.location, .line, .column]
}


struct EditorCountResult: Equatable {
    
    struct Count: Equatable {
        
        var length = 0
        var characters = 0
        var lines = 0
        var words = 0
    }
    
    struct Cursor: Equatable {
        
        var location = 1  // cursor location from the beginning of document
        var line = 1      // current line
        var column = 1    // cursor location from the beginning of line
    }
    
    
    var count = Count()
    var selectedCount = Count()
    var cursor = Cursor()
    var unicode: String?  // Unicode of selected single character (or surrogate-pair)
    var character: Character?
    
    
    
    func format(_ keyPath: KeyPath<Count, Int>) -> String {
        
        let count = self.count[keyPath: keyPath]
        let selectedCount = self.selectedCount[keyPath: keyPath]
        
        if selectedCount > 0 {
            return "\(count.formatted()) (\(selectedCount.formatted()))"
        }
        
        return count.formatted()
    }
    
    
    func format(_ keyPath: KeyPath<Cursor, Int>) -> String {
        
        let count = self.cursor[keyPath: keyPath]
        
        return count.formatted()
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
    
    init(string: String, selectedRange: Range<String.Index>, requiredInfo: EditorInfoTypes = .all, countsWholeText: Bool) {
        
        assert(selectedRange.upperBound <= string.endIndex)
        assert(!(string as NSString).className.contains("MutableString"))
        
        self.string = string
        self.selectedRange = selectedRange
        self.requiredInfo = requiredInfo
        self.countsWholeText = countsWholeText
    }
    
    
    
    // MARK: Operation Methods
    
    func count() throws -> EditorCountResult {
        
        var result = EditorCountResult()
        
        if self.countsWholeText, !self.requiredInfo.isDisjoint(with: .counts) {
            result.count = self.string.isEmpty
                ? .init()
                : try self.count(in: self.string)
        }
        
        if !self.requiredInfo.isDisjoint(with: .counts) {
            result.selectedCount = self.selectedRange.isEmpty
                ? .init()
                : try self.count(in: self.string[self.selectedRange])
        }
        
        if !self.requiredInfo.isDisjoint(with: .cursors) {
            result.cursor = try self.locate(location: self.selectedRange.lowerBound)
        }
        
        if self.requiredInfo.contains(.unicode) {
            let selectedString = self.string[self.selectedRange]
            if selectedString.compareCount(with: 1) == .equal,
               let character = selectedString.first
            {
                result.unicode = character.unicodeScalars.map(\.codePoint).joined(separator: ", ")
            }
        }
        
        return result
    }
    
    
    
    // MARK: Private Methods
    
    private func count<S: StringProtocol>(in string: S) throws -> EditorCountResult.Count {
        
        var count = EditorCountResult.Count()
        
        try Task.checkCancellation()
        
        if self.requiredInfo.contains(.length) {
            count.length = string.utf16.count
        }
        
        try Task.checkCancellation()
        
        if self.requiredInfo.contains(.characters) {
            count.characters = string.count
        }
        
        try Task.checkCancellation()
        
        if self.requiredInfo.contains(.lines) {
            count.lines = string.numberOfLines
        }
        
        try Task.checkCancellation()
        
        if self.requiredInfo.contains(.words) {
            count.words = string.numberOfWords
        }
        
        return count
    }
    
    
    private func locate(location: String.Index) throws -> EditorCountResult.Cursor {
        
        var cursor = EditorCountResult.Cursor()
        
        try Task.checkCancellation()
        
        let string = self.string[..<location]
        
        try Task.checkCancellation()
        
        if self.requiredInfo.contains(.location) {
            cursor.location = string.count + 1
        }
        
        try Task.checkCancellation()
        
        if self.requiredInfo.contains(.line) {
            cursor.line = max(string.numberOfLines, 1)
        }
        
        try Task.checkCancellation()
        
        if self.requiredInfo.contains(.column) {
            let lineStartIndex = string.lineStartIndex(at: location)
            cursor.column = string.distance(from: lineStartIndex, to: string.endIndex) + 1
        }
        
        return cursor
    }
    
}
