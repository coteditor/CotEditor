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
//  © 2014-2026 1024jp
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
import LineEnding
import StringUtils

@MainActor final class EditorCounter {
    
    @MainActor @Observable final class Result {
        
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
    
    
    struct Count: Equatable {
        
        var entire: Int?
        var selected = 0
    }
    
    
    struct Types: OptionSet {
        
        var rawValue: Int
        
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
    
    
    @MainActor protocol Source: AnyObject {
        
        var string: String { get }
        var selectedRanges: [NSValue] { get }
    }
    
    
    // MARK: Public Properties
    
    let result: Result = .init()
    
    var source: () -> any Source? = { nil }
    var lineRangeCalculator: any LineRangeCalculating?
    
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
        
        self.contentTask = Task(priority: .utility) {
            try await Task.sleep(for: .milliseconds(20), tolerance: .milliseconds(20))  // debounce
            
            guard let source = self.source() else { return }
            
            let string = source.string.immutable
            
            try await withThrowingDiscardingTaskGroup { group in
                if self.types.contains(.characters) {
                    group.addTask {
                        try Task.checkCancellation()
                        let count = string.count
                        try await MainActor.run {
                            try Task.checkCancellation()
                            self.result.characters.entire = count
                        }
                    }
                }
                
                if self.types.contains(.lines) {
                    if let lineRangeCalculator = self.lineRangeCalculator {
                        self.result.lines.entire = lineRangeCalculator.numberOfLines
                    } else {
                        group.addTask {
                            try Task.checkCancellation()
                            let count = string.numberOfLines
                            try await MainActor.run {
                                try Task.checkCancellation()
                                self.result.lines.entire = count
                            }
                        }
                    }
                }
                
                if self.types.contains(.words) {
                    group.addTask {
                        try Task.checkCancellation()
                        let count = string.numberOfWords
                        try await MainActor.run {
                            try Task.checkCancellation()
                            self.result.words.entire = count
                        }
                    }
                }
            }
        }
    }
    
    
    /// Updates selection-related values.
    func invalidateSelection() {
        
        self.selectionTask?.cancel()
        
        guard !self.types.isEmpty else { return }
        
        self.selectionTask = Task(priority: .utility) {
            try await Task.sleep(for: .milliseconds(200), tolerance: .milliseconds(40))  // debounce
            
            guard let source = self.source() else { return }
            
            let string = source.string.immutable
            let selectedNSRanges = source.selectedRanges.map(\.rangeValue)
            let selectedRanges = selectedNSRanges.compactMap { Range($0, in: string) }
            let selectedStrings = selectedRanges.map { string[$0] }
            let location = selectedRanges.first?.lowerBound ?? string.startIndex
            
            if self.types.contains(.character) {
                self.result.character = (selectedStrings.first?.compareCount(with: 1) == .equal)
                    ? selectedStrings.first?.first
                    : nil
            }
            
            try await withThrowingDiscardingTaskGroup { group in
                if self.types.contains(.characters) {
                    group.addTask {
                        try Task.checkCancellation()
                        let count = selectedStrings.map(\.count).reduce(0, +)
                        try await MainActor.run {
                            try Task.checkCancellation()
                            self.result.characters.selected = count
                        }
                    }
                }
                
                if self.types.contains(.lines) {
                    if let lineRangeCalculator = self.lineRangeCalculator {
                        self.result.lines.selected = lineRangeCalculator.numberOfLines(in: selectedNSRanges)
                    } else {
                        group.addTask {
                            try Task.checkCancellation()
                            let count = string.numberOfLines(in: selectedRanges)
                            try await MainActor.run {
                                try Task.checkCancellation()
                                self.result.lines.selected = count
                            }
                        }
                    }
                }
                
                if self.types.contains(.words) {
                    group.addTask {
                        try Task.checkCancellation()
                        let count = selectedStrings.map(\.numberOfWords).reduce(0, +)
                        try await MainActor.run {
                            try Task.checkCancellation()
                            self.result.words.selected = count
                        }
                    }
                }
                
                if self.types.contains(.location) {
                    group.addTask {
                        try Task.checkCancellation()
                        let offset = string.distance(from: string.startIndex, to: location)
                        try await MainActor.run {
                            try Task.checkCancellation()
                            self.result.location = offset
                        }
                    }
                }
                
                if self.types.contains(.line) {
                    if let lineRangeCalculator = self.lineRangeCalculator, let nsLocation = selectedNSRanges.first?.location {
                        self.result.line = lineRangeCalculator.lineNumber(at: nsLocation)
                    } else {
                        group.addTask {
                            try Task.checkCancellation()
                            let line = string.lineNumber(at: location)
                            try await MainActor.run {
                                try Task.checkCancellation()
                                self.result.line = line
                            }
                        }
                    }
                }
                
                if self.types.contains(.column) {
                    group.addTask {
                        try Task.checkCancellation()
                        let column = string.columnNumber(at: location)
                        try await MainActor.run {
                            try Task.checkCancellation()
                            self.result.column = column
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: Private Methods
    
    /// Update types to count.
    private func updateTypes() {
        
        let oldValue = self.types
        
        self.types = self.updatesAll ? .all : self.statusBarRequirements
        
        guard self.types != oldValue else { return }
        
        if self.types.isEmpty {
            self.cancel()
            return
        }
        
        let added = self.types.subtracting(oldValue)
        
        if !added.isDisjoint(with: .count) {
            self.invalidateContent()
        }
        if !added.isEmpty {
            self.invalidateSelection()
        }
    }
}
