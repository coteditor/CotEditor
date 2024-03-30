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
//  © 2014-2024 1024jp
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

actor EditorCounter {
    
    struct Result: Equatable {
        
        struct Count: Equatable {
            
            var entire: Int?
            var selected = 0
        }
        
        var characters = Count()
        var lines = Count()
        var words = Count()
        
        /// Cursor location from the beginning of the content.
        var location: Int?
        /// Current line.
        var line: Int?
        /// Cursor location from the beginning of the line.
        var column: Int?
        
        /// The first selected character (only when selection is a single character).
        var character: Character?
    }
    
    
    struct Types: OptionSet {
        
        let rawValue: Int
        
        static let characters = Self(rawValue: 1 << 0)
        static let lines      = Self(rawValue: 1 << 1)
        static let words      = Self(rawValue: 1 << 2)
        static let location   = Self(rawValue: 1 << 3)
        static let line       = Self(rawValue: 1 << 4)
        static let column     = Self(rawValue: 1 << 5)
        static let character  = Self(rawValue: 1 << 6)
        
        static let all: Self = [.characters, .lines, .words, .location, .line, .column, .character]
        static let count: Self = [.characters, .lines, .words]
    }
    
    
    // MARK: Public Properties
    
    private(set) var result = Result()
    private(set) var types: Types = []
    
    
    // MARK: Public Methods
    
    func update(types: Types) {
        
        self.types = types
    }
    
    
    /// Update the given types by counting the given string.
    ///
    /// - Parameters:
    ///   - string: The string to count.
    func count(string: String) throws {
        
        guard !self.types.isDisjoint(with: .count) else { return }
        
        if self.types.contains(.characters) {
            try Task.checkCancellation()
            self.result.characters.entire = string.count
        }
        
        if self.types.contains(.lines) {
            try Task.checkCancellation()
            self.result.lines.entire = string.numberOfLines
        }
        
        if self.types.contains(.words) {
            try Task.checkCancellation()
            self.result.words.entire = string.numberOfWords
        }
    }
    
    
    /// Update the given types by counting the given string.
    ///
    /// - Parameters:
    ///   - selectedRanges: The editor's selected ranges.
    ///   - string: The string to count.
    func move(selectedRanges: [Range<String.Index>], string: String) throws {
        
        guard !self.types.isEmpty else { return }
        
        let selectedStrings = selectedRanges.map { string[$0] }
        
        if self.types.contains(.characters) {
            try Task.checkCancellation()
            self.result.characters.selected = selectedStrings.map(\.count).reduce(0, +)
        }
        
        if self.types.contains(.lines) {
            try Task.checkCancellation()
            self.result.lines.selected = string.numberOfLines(in: selectedRanges)
        }
        
        if self.types.contains(.words) {
            try Task.checkCancellation()
            self.result.words.selected = selectedStrings.map(\.numberOfWords).reduce(0, +)
        }
        
        if self.types.contains(.location) {
            try Task.checkCancellation()
            self.result.location = string.distance(from: string.startIndex, to: selectedRanges[0].lowerBound)
        }
        
        if self.types.contains(.line) {
            try Task.checkCancellation()
            self.result.line = string.lineNumber(at: selectedRanges[0].lowerBound)
        }
        
        if self.types.contains(.column) {
            try Task.checkCancellation()
            self.result.column = string.columnNumber(at: selectedRanges[0].lowerBound)
        }
        
        if self.types.contains(.character) {
            self.result.character = (selectedStrings.first?.compareCount(with: 1) == .equal)
                ? selectedStrings.first?.first
                : nil
        }
    }
}


extension EditorCounter.Result.Count {
    
    var formatted: String? {
        
        if let entire, self.selected > 0 {
            "\(entire.formatted()) (\(self.selected.formatted()))"
        } else {
            self.entire?.formatted()
        }
    }
}
