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
//  © 2014-2019 1024jp
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



// MARK: -

final class EditorInfoCountOperation: Operation {
    
    struct Result {
        
        var length = 0
        var characters = 0
        var lines = 0
        var words = 0
        var location = 1  // caret location from the beginning of document
        var line = 1      // current line
        var column = 1    // caret location from the beginning of line
        var unicode: String?  // Unicode of selected single character (or surrogate-pair)
        
        var selectedLength = 0
        var selectedCharacters = 0
        var selectedLines = 0
        var selectedWords = 0
    }
    
    
    // MARK: Public Properties
    
    private(set) var result = Result()
    
    
    // MARK: Private Properties
    
    private let string: String
    private let lineEnding: LineEnding
    private let selectedRange: Range<String.Index>
    
    private let requiredInfo: EditorInfoTypes
    private let countsLineEnding: Bool
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(string: String, lineEnding: LineEnding, selectedRange: Range<String.Index>, requiredInfo: EditorInfoTypes = .all, countsLineEnding: Bool) {
        
        assert(selectedRange.upperBound <= string.endIndex)
        assert((string as AnyObject).className != "NSBigMutableString")
        
        self.string = string
        self.lineEnding = lineEnding
        self.selectedRange = selectedRange
        self.requiredInfo = requiredInfo
        self.countsLineEnding = countsLineEnding
        
        super.init()
    }
    
    
    
    // MARK: Operation Methods
    
    override func main() {
        
        guard !self.string.isEmpty else { return }
        
        let selectedString = self.string[self.selectedRange]
        let hasSelection = !self.selectedRange.isEmpty
        let cursorLocation = self.selectedRange.lowerBound
        
        // count length
        if self.requiredInfo.contains(.length) {
            let isSingleLineEnding = (self.lineEnding.length == 1)
            self.result.length = isSingleLineEnding
                ? (self.string as NSString).length
                : (self.string.replacingLineEndings(with: self.lineEnding) as NSString).length
            
            if hasSelection {
                self.result.selectedLength = isSingleLineEnding
                    ? (selectedString as NSString).length
                    : (selectedString.replacingLineEndings(with: self.lineEnding) as NSString).length
            }
        }
        
        guard !self.isCancelled else { return }
        
        // count characters
        if self.requiredInfo.contains(.characters) {
            self.result.characters = self.countsLineEnding
                ? self.string.count
                : self.string.countExceptLineEnding
            
            if hasSelection {
                self.result.selectedCharacters = self.countsLineEnding
                    ? selectedString.count
                    : selectedString.countExceptLineEnding
            }
        }
        
        guard !self.isCancelled else { return }
        
        // count lines
        if self.requiredInfo.contains(.lines) {
            self.result.lines = self.string.numberOfLines
            
            if hasSelection {
                self.result.selectedLines = selectedString.numberOfLines
            }
        }
        
        guard !self.isCancelled else { return }
        
        // count words
        if self.requiredInfo.contains(.words) {
            self.result.words = self.string.numberOfWords
            
            if hasSelection {
                self.result.selectedWords = selectedString.numberOfWords
            }
        }
        
        guard !self.isCancelled else { return }
        
        // calculate current location
        if self.requiredInfo.contains(.location) {
            let locString = self.string[..<cursorLocation]
            self.result.location = self.countsLineEnding
                ? locString.count + 1
                : locString.countExceptLineEnding + 1
        }
        
        guard !self.isCancelled else { return }
        
        // calculate current line
        if self.requiredInfo.contains(.line) {
            self.result.line = self.string.lineNumber(at: cursorLocation)
        }
        
        guard !self.isCancelled else { return }
        
        // calculate current column
        if self.requiredInfo.contains(.column) {
            let lineStartIndex = self.string.lineRange(at: cursorLocation).lowerBound
            self.result.column = self.string.distance(from: lineStartIndex, to: cursorLocation) + 1
        }
        
        // unicode
        if self.requiredInfo.contains(.unicode) {
            if selectedString.unicodeScalars.count == 1 {
                self.result.unicode = selectedString.unicodeScalars.first?.codePoint
            }
        }
    }
    
}
