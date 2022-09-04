//
//  EditorCounter.swift
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
    
    static let cursors: Self = [.location, .line, .column]
}


struct EditorCountResult: Equatable {
    
    struct Count: Equatable {
        
        var entire: Int?
        var selected = 0
    }
    
    var characters = Count()
    var lines = Count()
    var words = Count()
    
    var location: Int?  // cursor location from the beginning of document
    var line: Int?   // current line
    var column: Int?   // cursor location from the beginning of line
    
    var unicode: String?  // Unicode of selected single character (or surrogate-pair)
}


extension EditorCountResult.Count {
    
    var formatted: String? {
        
        if self.selected == 0 {
            return self.entire?.formatted()
        } else {
            return "\(self.entire?.formatted() ?? "-") (\(self.selected.formatted()))"
        }
    }
    
}



// MARK: -

final class EditorCounter {
    
    // MARK: Private Properties
    
    let string: String
    let selectedRange: Range<String.Index>
    
    let requiredInfo: EditorInfoTypes
    let countsWholeText: Bool
    
    
    
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
        
        let selectedString = self.string[self.selectedRange]
        
        if self.countsWholeText {
            if self.requiredInfo.contains(.characters) {
                try Task.checkCancellation()
                result.characters.entire = self.string.count
            }
            
            if self.requiredInfo.contains(.lines) {
                try Task.checkCancellation()
                result.lines.entire = self.string.numberOfLines
            }
            
            if self.requiredInfo.contains(.words) {
                try Task.checkCancellation()
                result.words.entire = self.string.numberOfWords
            }
        }
        
        if self.requiredInfo.contains(.characters) {
            try Task.checkCancellation()
            result.characters.selected = selectedString.count
        }
        
        if self.requiredInfo.contains(.lines) {
            try Task.checkCancellation()
            result.lines.selected = selectedString.numberOfLines
        }
        
        if self.requiredInfo.contains(.words) {
            try Task.checkCancellation()
            result.words.selected = selectedString.numberOfWords
        }
        
        if self.requiredInfo.contains(.location) {
            try Task.checkCancellation()
            result.location = self.string.distance(from: self.string.startIndex,
                                                   to: self.selectedRange.lowerBound)
        }
        
        if self.requiredInfo.contains(.line) {
            try Task.checkCancellation()
            result.line = self.string.lineNumber(at: self.selectedRange.lowerBound)
        }
        
        if self.requiredInfo.contains(.column) {
            try Task.checkCancellation()
            result.column = self.string.columnNumber(at: self.selectedRange.lowerBound)
        }
        
        if self.requiredInfo.contains(.unicode) {
            result.unicode = (selectedString.compareCount(with: 1) == .equal)
                ? selectedString.first?.unicodeScalars.map(\.codePoint).joined(separator: ", ")
                : nil
        }
        
        return result
    }
    
}
