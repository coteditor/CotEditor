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
//  © 2020-2023 1024jp
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
import Combine

final class URLDetector {
    
    // MARK: Private Properties
    
    private let textStorage: NSTextStorage
    private var editedRanges = EditedRangeSet()
    private let delay: TimeInterval = 0.5
    
    private var textEditingObserver: AnyCancellable?
    private var task: Task<Void, any Error>?
    
    
    // MARK: Lifecycle
    
    init(textStorage: NSTextStorage) {
        
        self.textStorage = textStorage
    }
    
    
    deinit {
        self.task?.cancel()
    }
    
    
    // MARK: Public Methods
    
    /// Whether the auto URL detection is enabled.
    var isEnabled: Bool = false {
        
        didSet {
            guard oldValue != isEnabled else { return }
            
            if isEnabled {
                self.editedRanges.append(editedRange: self.textStorage.range)
                self.observeTextStorage(self.textStorage)
                self.task = Task { try await self.detectInvalidRanges() }
                
            } else {
                self.textEditingObserver?.cancel()
                self.task?.cancel()
                self.editedRanges.clear()
                self.textStorage.removeAttribute(.link, range: self.textStorage.range)
            }
        }
    }
    
    
    // MARK: Private Methods
    
    /// Observe the changes of the given textStorage to detect URLs around the edited area.
    ///
    /// - Parameter textStorage: The text storage to observe.
    private func observeTextStorage(_ textStorage: NSTextStorage) {
        
        // -> `NotificationCenter.default.notifications(named:)` cannot obtain the notification at the timing when the correspondent .editedMask and .editedRange exist. (macOS 13, 2023-02)
        self.textEditingObserver = NotificationCenter.default.publisher(for: NSTextStorage.didProcessEditingNotification, object: textStorage)
            .map { $0.object as! NSTextStorage }
            .filter { $0.editedMask.contains(.editedCharacters) }
            .sink { [unowned self] in
                self.editedRanges.append(editedRange: $0.editedRange, changeInLength: $0.changeInLength)
                self.task?.cancel()
                self.task = Task { try await self.detectInvalidRanges(after: self.delay) }
            }
    }
    
    
    /// Update URLs around the edited ranges.
    ///
    /// - Parameter delay: The debounce delay in seconds.
    @MainActor private func detectInvalidRanges(after delay: Double = 0) async throws {
        
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        guard let invalidRange = self.editedRanges.ranges.union else { return }
        
        let string = self.textStorage.string
        let lowerBound = max(invalidRange.lowerBound - 1, 0)
        let upperBound = min(invalidRange.upperBound + 1, string.length)
        let parseRange = (string as NSString).lineRange(for: NSRange(lowerBound..<upperBound))
        
        try await self.textStorage.linkURLs(in: parseRange)
        self.editedRanges.clear()
    }
}


extension NSTextStorage {
    
    /// Link detected URLs in the content.
    ///
    /// - Parameter range: The range where links are detected, or nil to detect all.
    /// - Throws: `CancellationError`
    @MainActor func linkURLs(in range: NSRange? = nil) async throws {
        
        guard self.length > 0 else { return }
        
        let string = self.string.immutable
        let range = range ?? self.range
        
        let links: [ValueRange<URL>] = try await Task.detached {
            try (try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue))
                .cancellableMatches(in: string, range: range)
                .compactMap { (result) in
                    guard let url = result.url else { return nil }
                    return ValueRange(value: url, range: result.range)
                }
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
