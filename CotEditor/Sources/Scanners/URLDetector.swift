//
//  URLDetector.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-15.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2025 1024jp
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

import AppKit.NSTextStorage
import EditedRangeSet
import StringUtils
import ValueRange

@MainActor final class URLDetector {
    
    // MARK: Private Properties
    
    private let textStorage: NSTextStorage
    private var editedRanges: EditedRangeSet
    private let delay: Duration = .seconds(0.5)
    
    private var textEditingObserver: (any NSObjectProtocol)?
    private var task: Task<Void, any Error>?
    
    
    // MARK: Lifecycle
    
    init(textStorage: NSTextStorage) {
        
        self.textStorage = textStorage
        
        self.editedRanges = EditedRangeSet(range: textStorage.range)
        self.textEditingObserver = self.observeTextStorage(textStorage)
        self.task = Task { try await self.detectInvalidRanges() }
    }
    
    
    // MARK: Public Methods
    
    /// Stops the detection and removes highlights.
    func cancel() {
        
        if let textEditingObserver {
            NotificationCenter.default.removeObserver(textEditingObserver, name: NSTextStorage.didProcessEditingNotification, object: self.textStorage)
            self.textEditingObserver = nil
        }
        
        self.task?.cancel()
        self.task = nil
        
        self.textStorage.removeAttribute(.link, range: self.textStorage.range)
    }
    
    
    // MARK: Private Methods
    
    /// Observes the changes of the given textStorage to detect URLs around the edited area.
    /// 
    /// - Parameter textStorage: The text storage to observe.
    /// - Returns: The notification observer.
    private func observeTextStorage(_ textStorage: NSTextStorage) -> any NSObjectProtocol {
        
        NotificationCenter.default.addObserver(forName: NSTextStorage.didProcessEditingNotification, object: textStorage, queue: .main) { [weak self] notification in
            let textStorage = notification.object as! NSTextStorage
            
            guard textStorage.editedMask.contains(.editedCharacters) else { return }
            
            MainActor.assumeIsolated {
                self?.invalidate(in: textStorage.editedRange, changeInLength: textStorage.changeInLength)
            }
        }
    }
    
    
    /// Updates edited ranges by assuming the textStorage was edited.
    ///
    /// - Parameters:
    ///   - editedRange: The edited range.
    ///   - delta: The change in length.
    private func invalidate(in editedRange: NSRange, changeInLength delta: Int) {
        
        self.editedRanges.append(editedRange: editedRange, changeInLength: delta)
        
        self.task?.cancel()
        self.task = Task {
            try await Task.sleep(for: self.delay, tolerance: self.delay * 0.5)
            try await self.detectInvalidRanges()
        }
    }
    
    
    /// Updates URLs around the edited ranges.
    private func detectInvalidRanges() async throws {
        
        guard let invalidRange = self.editedRanges.range else { return }
        
        let string = self.textStorage.string as NSString
        let lowerBound = max(invalidRange.lowerBound - 1, 0)
        let upperBound = min(invalidRange.upperBound + 1, string.length)
        let parseRange = string.lineRange(for: NSRange(lowerBound..<upperBound))
        
        try await self.textStorage.linkURLs(in: parseRange)
        
        self.editedRanges.clear()
    }
}


extension NSTextStorage {
    
    /// Links detected URLs in the contents.
    ///
    /// - Parameter range: The range where links are detected, or nil to detect all.
    /// - Throws: `CancellationError`
    @MainActor final func linkURLs(in range: NSRange? = nil) async throws {
        
        guard self.length > 0 else { return }
        
        let string = self.string.immutable
        let range = range ?? self.range
        
        let links: [ValueRange<URL>] = try await Task.detached {
            try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                .cancellableMatches(in: string, range: range)
                .compactMap { match in match.url.map { ValueRange(value: $0, range: match.range) } }
        }.value
        
        try Task.checkCancellation()
        
        assert(self.string.length == string.length, "textStorage was edited after starting URL detection")
        
        guard !links.isEmpty || self.hasAttribute(.link) else { return }
        
        self.beginEditing()
        self.removeAttribute(.link, range: range)
        for link in links {
            self.addAttribute(.link, value: link.value, range: link.range)
        }
        self.endEditing()
    }
}
