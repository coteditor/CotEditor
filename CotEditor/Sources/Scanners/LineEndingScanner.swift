//
//  LineEndingScanner.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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

import Combine
import Foundation
import Observation
import AppKit.NSTextStorage
import LineEnding
import ValueRange

@Observable final class LineEndingScanner: LineRangeCalculating {
    
    var baseLineEnding: LineEnding  { didSet { self.invalidateLineEnding() } }
    
    private(set) var lineEndings: [ValueRange<LineEnding>]
    private(set) var inconsistentLineEndings: [ValueRange<LineEnding>]
    
    var length: Int  { self.textStorage.length }
    
    
    // MARK: Private Properties
    
    private let textStorage: NSTextStorage
    
    private var storageObserver: AnyCancellable?
    
    
    // MARK: Lifecycle
    
    required init(textStorage: NSTextStorage, lineEnding: LineEnding) {
        
        self.textStorage = textStorage
        self.baseLineEnding = lineEnding
        
        let lineEndings = textStorage.string.lineEndingRanges()
        self.lineEndings = lineEndings
        self.inconsistentLineEndings = lineEndings.filter { $0.value != lineEnding }
        
        self.storageObserver = NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: textStorage)
            .map { $0.object as! NSTextStorage }
            .filter { $0.editedMask.contains(.editedCharacters) }
            .sink { [weak self] in self?.invalidate(in: $0.editedRange, changeInLength: $0.changeInLength) }
    }
    
    
    // MARK: Public Methods
    
    /// Cancels all observations.
    func cancel() {
        
        self.storageObserver?.cancel()
    }
    
    
    /// Returns whether the character at the given index is a line ending inconsistent with the `baseLineEnding`.
    ///
    /// - Parameter characterIndex: The index of character to test.
    /// - Returns: A boolean indicating whether the character is an inconsistent line ending.
    func isInvalidLineEnding(at characterIndex: Int) -> Bool {
        
        self.inconsistentLineEndings.contains { $0.lowerBound == characterIndex }
    }
    
    
    // MARK: Private Methods
    
    /// Updates inconsistent line endings by assuming the textStorage was edited.
    ///
    /// - Parameters:
    ///   - editedRange: The edited range.
    ///   - delta: The change in length.
    private func invalidate(in editedRange: NSRange, changeInLength delta: Int) {
        
        var scanRange: NSRange = .notFound
        let insertedLineEndings = self.textStorage.string.lineEndingRanges(in: editedRange, effectiveRange: &scanRange)
        let inconsistentLineEndings = insertedLineEndings.filter { $0.value != self.baseLineEnding }
        
        self.lineEndings.replace(items: insertedLineEndings, in: scanRange, changeInLength: delta)
        self.inconsistentLineEndings.replace(items: inconsistentLineEndings, in: scanRange, changeInLength: delta)
    }
    
    
    /// Updates `inconsistentLineEndings` with the current base line ending.
    private func invalidateLineEnding() {
        
        self.inconsistentLineEndings = self.lineEndings.filter { $0.value != self.baseLineEnding }
    }
}
