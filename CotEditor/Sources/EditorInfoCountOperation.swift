//
//  EditorInfoCountOperation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
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
    
    static let length     = EditorInfoTypes(rawValue: 1 << 0)
    static let characters = EditorInfoTypes(rawValue: 1 << 1)
    static let lines      = EditorInfoTypes(rawValue: 1 << 2)
    static let words      = EditorInfoTypes(rawValue: 1 << 3)
    static let location   = EditorInfoTypes(rawValue: 1 << 4)
    static let line       = EditorInfoTypes(rawValue: 1 << 5)
    static let column     = EditorInfoTypes(rawValue: 1 << 6)
    static let unicode    = EditorInfoTypes(rawValue: 1 << 7)
    
    static let all: EditorInfoTypes = [.length, .characters, .lines, .words, .location, .line, .column, .unicode]
    
    static let counts: EditorInfoTypes = [.length, .characters, .lines, .words]
    static let cursors: EditorInfoTypes = [.location, .line, .column]
}


struct EditorCountResult: Equatable {
    
    struct Count: Equatable {
        
        var length = 0
        var characters = 0
        var lines = 0
        var words = 0
    }
    
    struct Cursor: Equatable {
        
        var location = 1  // caret location from the beginning of document
        var line = 1      // current line
        var column = 1    // caret location from the beginning of line
    }
    
    
    var count = Count()
    var selectedCount = Count()
    var cursor = Cursor()
    var unicode: String?  // Unicode of selected single character (or surrogate-pair)
    
    
    
    func format(_ keyPath: KeyPath<Count, Int>) -> String {
        
        let count = self.count[keyPath: keyPath]
        let selectedCount = self.selectedCount[keyPath: keyPath]
        
        if selectedCount > 0 {
            return String.localizedStringWithFormat("%li (%li)", count, selectedCount)
        }
        
        return String.localizedStringWithFormat("%li", count)
    }
    
    
    func format(_ keyPath: KeyPath<Cursor, Int>) -> String {
        
        let count = self.cursor[keyPath: keyPath]
        
        return String.localizedStringWithFormat("%li", count)
    }
    
}



// MARK: -

final class EditorInfoCountOperation: Operation {
    
    // MARK: Public Properties
    
    private(set) var result = EditorCountResult()
    
    let countsWholeText: Bool
    
    
    // MARK: Private Properties
    
    private let string: String
    private let lineEnding: LineEnding
    private let selectedRange: Range<String.Index>
    
    private let requiredInfo: EditorInfoTypes
    private let countsLineEnding: Bool
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(string: String, lineEnding: LineEnding, selectedRange: Range<String.Index>, requiredInfo: EditorInfoTypes = .all, countsLineEnding: Bool, countsWholeText: Bool) {
        
        assert(selectedRange.upperBound <= string.endIndex)
        assert(!(string as NSString).className.contains("MutableString"))
        
        self.string = string
        self.lineEnding = lineEnding
        self.selectedRange = selectedRange
        self.requiredInfo = requiredInfo
        self.countsLineEnding = countsLineEnding
        self.countsWholeText = countsWholeText
        
        super.init()
    }
    
    
    
    // MARK: Operation Methods
    
    override func main() {
        
        if self.countsWholeText,
           !self.requiredInfo.isDisjoint(with: .counts),
           !self.string.isEmpty
        {
            self.result.count = self.count(in: self.string)
        }
        
        guard !self.isCancelled else { return }
        
        if !self.requiredInfo.isDisjoint(with: .cursors),
           !self.string.isEmpty
        {
            self.result.cursor = self.locate(location: self.selectedRange.lowerBound)
        }
        
        guard !self.isCancelled else { return }
        
        if !self.selectedRange.isEmpty {
            let selectedString = self.string[self.selectedRange]
            
            if !self.requiredInfo.isDisjoint(with: .counts) {
                self.result.selectedCount = self.count(in: selectedString)
            }
            
            if self.requiredInfo.contains(.unicode),
               selectedString.unicodeScalars.compareCount(with: 1) == .equal
            {
                self.result.unicode = selectedString.unicodeScalars.first?.codePoint
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    private func count<S: StringProtocol>(in string: S) -> EditorCountResult.Count {
        
        var count = EditorCountResult.Count()
        
        if self.requiredInfo.contains(.length) {
            count.length = (self.lineEnding.length == 1)
                ? string.utf16.count
                : string.replacingLineEndings(with: self.lineEnding).utf16.count
        }
        
        guard !self.isCancelled else { return count }
        
        if self.requiredInfo.contains(.characters) {
            count.characters = self.countsLineEnding
                ? string.count
                : string.countExceptLineEnding
        }
        
        guard !self.isCancelled else { return count }
        
        if self.requiredInfo.contains(.lines) {
            count.lines = string.numberOfLines
        }
        
        guard !self.isCancelled else { return count }
        
        if self.requiredInfo.contains(.words) {
            count.words = string.numberOfWords
        }
        
        return count
    }
    
    
    private func locate(location: String.Index) -> EditorCountResult.Cursor {
        
        let string = self.string[..<location]
        var cursor = EditorCountResult.Cursor()
        
        if self.requiredInfo.contains(.location) {
            cursor.location = self.countsLineEnding
                ? string.count + 1
                : string.countExceptLineEnding + 1
        }
        
        guard !self.isCancelled else { return cursor }
        
        if self.requiredInfo.contains(.line) {
            cursor.line = string.numberOfLines
        }
        
        guard !self.isCancelled else { return cursor }
        
        if self.requiredInfo.contains(.column) {
            let lineStartIndex = string.lineStartIndex(at: location)
            cursor.column = string[lineStartIndex...].count + 1
        }
        
        return cursor
    }
    
}
