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
//  © 2022 1024jp
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
import class AppKit.NSTextStorage
import Combine

struct LineEndingLocation: Equatable {
    
    var lineEnding: LineEnding
    var location: Int
    
    var range: NSRange  { NSRange(location: self.location, length: self.lineEnding.length) }
}



final class LineEndingScanner {
    
    @Published private(set) var inconsistentLineEndings: [LineEndingLocation] = []
    
    
    // MARK: Private Properties
    
    private let textStorage: NSTextStorage
    private var documentLineEnding: LineEnding  { didSet { self.inconsistentLineEndings = self.scan() } }
    
    private var lineEndingObserver: AnyCancellable?
    private var storageObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(textStorage: NSTextStorage, lineEnding: LineEnding) {
        
        self.textStorage = textStorage
        self.documentLineEnding = lineEnding
        
        self.inconsistentLineEndings = self.scan()
        
        self.storageObserver = NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: textStorage)
            .compactMap { $0.object as? NSTextStorage }
            .filter { $0.editedMask.contains(.editedCharacters) }
            .sink { [weak self] in self?.invalidate(in: $0.editedRange, changeInLength: $0.changeInLength) }
    }
    
    
    func observe(lineEnding publisher: Published<LineEnding>.Publisher) {
        
        self.lineEndingObserver = publisher
            .removeDuplicates()
            .sink { [weak self] in self?.documentLineEnding = $0 }
    }
    
    
    
    // MARK: Private Methods
    
    /// Update inconsistent line endings asuming the textStorage was edited.
    ///
    /// - Parameters:
    ///   - editedRange: The edited range.
    ///   - delta: The change in length.
    private func invalidate(in editedRange: NSRange, changeInLength delta: Int) {
        
        // expand range to scan by considering the possibility that a part of CRLF was edited
        let scanRange = NSRange(max(editedRange.lowerBound - 1, 0)..<min(editedRange.upperBound + 1, self.textStorage.length))
        
        let shiftedLineEndings = self.inconsistentLineEndings
            .filter { $0.location >= (scanRange.upperBound - delta) }
            .map { LineEndingLocation(lineEnding: $0.lineEnding, location: $0.location + delta) }
        let editedLineEndings = self.scan(in: scanRange)
        
        self.inconsistentLineEndings.removeAll { $0.location >= scanRange.lowerBound }
        self.inconsistentLineEndings += editedLineEndings + shiftedLineEndings
    }
    
    
    /// Scan line endings inconsistent with the document line endings.
    ///
    /// - Parameter range: The range to scan.
    /// - Returns: The inconsistent line endings with its location.
    private func scan(in range: NSRange? = nil) -> [LineEndingLocation] {
        
        self.textStorage.string.lineEndingRanges(in: range)
            .filter { $0.key != self.documentLineEnding }
            .flatMap { (key, value) in value.map { LineEndingLocation(lineEnding: key, location: $0.location) } }
            .sorted(\.location)
    }
    
}
