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
        assert((string as AnyObject).className != "NSBigMutableString")
        
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
        
        if self.countsWholeText {
            self.result.count = self.count()
        }
        
        guard !self.isCancelled else { return }
        
        self.result.cursor = self.locate(location: self.selectedRange.lowerBound)
        
        guard !self.isCancelled else { return }
        
        // calculate selected string
        if !self.selectedRange.isEmpty {
            self.result.selectedCount = self.count(in: self.selectedRange)
            
            if self.requiredInfo.contains(.unicode) {
                let selectedString = self.string[self.selectedRange]
                if selectedString.unicodeScalars.compareCount(with: 1) == .equal {
                    self.result.unicode = selectedString.unicodeScalars.first?.codePoint
                }
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    private func count(in range: Range<String.Index>? = nil) -> EditorCountResult.Count {
        
        let string = range.flatMap { self.string[$0] } ?? self.string[...]
        var count = EditorCountResult.Count()
        
        if self.requiredInfo.contains(.length) {
            count.length = (self.lineEnding.length == 1)
                ? (string as NSString).length
                : (string.replacingLineEndings(with: self.lineEnding) as NSString).length
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
        
        var cursor = EditorCountResult.Cursor()
        
        // calculate current location
        if self.requiredInfo.contains(.location) {
            let locString = self.string[..<location]
            cursor.location = self.countsLineEnding
                ? locString.count + 1
                : locString.countExceptLineEnding + 1
        }
        
        guard !self.isCancelled else { return cursor }
        
        // calculate current line
        if self.requiredInfo.contains(.line) {
            cursor.line = self.string.lineNumber(at: location)
        }
        
        guard !self.isCancelled else { return cursor }
        
        // calculate current column
        if self.requiredInfo.contains(.column) {
            let lineStartIndex = self.string.lineStartIndex(at: location)
            cursor.column = self.string.distance(from: lineStartIndex, to: location) + 1
        }
        
        return cursor
    }
    
}
