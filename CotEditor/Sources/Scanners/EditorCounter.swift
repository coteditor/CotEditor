//
//  EditorCounter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-12-18.
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

import Foundation
import Observation
import StringUtils

@MainActor protocol EditorSource: AnyObject {
    
    var string: String? { get }
    var selectedRanges: [NSRange] { get }
}


struct EditorCount: Equatable {
    
    var entire: Int?
    var selected = 0
    
    
    var formatted: String? {
        
        if let entire, self.selected > 0 {
            "\(entire.formatted()) (\(self.selected.formatted()))"
        } else {
            self.entire?.formatted()
        }
    }
}


@MainActor final class EditorCounter {
    
    @Observable final class Result {
        
        var characters = EditorCount()
        var lines = EditorCount()
        var words = EditorCount()
        
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
    
    let result: Result = .init()
    
    weak var source: (any EditorSource)?  // weak to avoid cycle retain
    
    var updatesAll = false  { didSet { self.updateTypes() } }
    var statusBarRequirements: Types = []  { didSet { self.updateTypes() } }
    
    
    // MARK: Private Properties
    
    private var types: Types = []
    
    private var contentTask: Task<Void, any Error>?
    private var selectionTask: Task<Void, any Error>?
    
    
    // MARK: Public Methods
    
    /// Cancels all remaining tasks.
    func cancel() {
        
        self.contentTask?.cancel()
        self.contentTask = nil
        self.selectionTask?.cancel()
        self.selectionTask = nil
    }
    
    
    /// Updates content counts.
    func invalidateContent() {
        
        self.contentTask?.cancel()
        
        guard !self.types.isDisjoint(with: .count) else { return }
        
        self.contentTask = Task {
            try await Task.sleep(for: .milliseconds(20), tolerance: .milliseconds(20))  // debounce
            
            guard let string = self.source?.string?.immutable else { return }
            
            if self.types.contains(.characters) {
                try Task.checkCancellation()
                self.result.characters.entire = await Task.detached { string.count }.value
            }
            
            if self.types.contains(.lines) {
                try Task.checkCancellation()
                self.result.lines.entire = await Task.detached { string.numberOfLines }.value
            }
            
            if self.types.contains(.words) {
                try Task.checkCancellation()
                self.result.words.entire = await Task.detached { string.numberOfWords }.value
            }
        }
    }
    
    
    /// Updates selection-related values.
    func invalidateSelection() {
        
        self.selectionTask?.cancel()
        
        guard !self.types.isEmpty else { return }
        
        self.selectionTask = Task {
            try await Task.sleep(for: .milliseconds(200), tolerance: .milliseconds(40))  // debounce
            
            guard
                let string = self.source?.string?.immutable,
                let selectedRanges = self.source?.selectedRanges.compactMap({ Range($0, in: string) })
            else { return }
            
            let selectedStrings = selectedRanges.map { string[$0] }
            let location = selectedRanges.first?.lowerBound ?? string.startIndex
            
            if self.types.contains(.character) {
                self.result.character = (selectedStrings.first?.compareCount(with: 1) == .equal)
                    ? selectedStrings.first?.first
                    : nil
            }
            
            if self.types.contains(.characters) {
                try Task.checkCancellation()
                self.result.characters.selected = await Task.detached { selectedStrings.map(\.count).reduce(0, +) }.value
            }
            
            if self.types.contains(.lines) {
                try Task.checkCancellation()
                self.result.lines.selected = await Task.detached { string.numberOfLines(in: selectedRanges) }.value
            }
            
            if self.types.contains(.words) {
                try Task.checkCancellation()
                self.result.words.selected = await Task.detached { selectedStrings.map(\.numberOfWords).reduce(0, +) }.value
            }
            
            if self.types.contains(.location) {
                try Task.checkCancellation()
                self.result.location = await Task.detached { string.distance(from: string.startIndex, to: location) }.value
            }
            
            if self.types.contains(.line) {
                try Task.checkCancellation()
                self.result.line = await Task.detached { string.lineNumber(at: location) }.value
            }
            
            if self.types.contains(.column) {
                try Task.checkCancellation()
                self.result.column = await Task.detached { string.columnNumber(at: location) }.value
            }
        }
    }
    
    
    // MARK: Private Methods
    
    /// Update types to count.
    private func updateTypes() {
        
        let oldValue = self.types
        
        self.types = self.updatesAll ? .all : self.statusBarRequirements
        
        if self.types.isEmpty {
            self.cancel()
            return
        }
        
        if !self.types.intersection(.count).isSubset(of: oldValue.intersection(.count)) {
            self.invalidateContent()
        }
        self.invalidateSelection()
    }
}
