//
//  WikiLinkDetector.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by Claude Code on 2025-01-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 CotEditor Project
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

/// Detects and links wiki-style [[Note Title]] links in text storage
/// Follows the same pattern as URLDetector for consistency
@MainActor final class WikiLinkDetector {
    
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
        
        // Remove wiki link attributes from text storage
        self.textStorage.removeAttribute(.link, range: self.textStorage.range, predicate: { value in
            guard let url = value as? URL else { return false }
            return url.scheme == "wiki" || (url.scheme == "https" && url.host == "wiki.local")
        })
    }
    
    
    // MARK: Private Methods
    
    /// Observes the changes of the given textStorage to detect wiki links around the edited area.
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
    
    
    /// Updates wiki links around the edited ranges.
    private func detectInvalidRanges() async throws {
        
        guard let invalidRange = self.editedRanges.range else { return }
        
        let string = self.textStorage.string as NSString
        let lowerBound = max(invalidRange.lowerBound - 1, 0)
        let upperBound = min(invalidRange.upperBound + 1, string.length)
        let parseRange = string.lineRange(for: NSRange(lowerBound..<upperBound))
        
        try await self.textStorage.linkWikiLinks(in: parseRange)
        
        self.editedRanges.clear()
    }
}


extension NSTextStorage {
    
    /// Links detected wiki links in the contents using .link attributes.
    ///
    /// - Parameter range: The range where wiki links are detected, or nil to detect all.
    /// - Throws: `CancellationError`
    @MainActor final func linkWikiLinks(in range: NSRange? = nil) async throws {
        
        guard self.length > 0 else { return }
        
        let string = self.string.immutable
        let range = range ?? self.range
        
        let wikiLinks: [ValueRange<URL>] = try await Task.detached {
            // Use WikiLinkParser to find links, then convert to URLs
            let links = WikiLinkParser.findWikiLinks(in: string, range: range)
            return links.compactMap { wikiLink in
                // Create wiki:// URL for consistency with link handling
                let safeTitle = wikiLink.title
                    .replacingOccurrences(of: "/", with: "-")
                    .replacingOccurrences(of: " ", with: "_")
                    .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "untitled"
                
                // Use https scheme with special domain to avoid URL validation issues
                guard let url = URL(string: "https://wiki.local/\(safeTitle)") else { return nil }
                return ValueRange(value: url, range: wikiLink.range)
            }
        }.value
        
        try Task.checkCancellation()
        
        assert(self.string.length == string.length, "textStorage was edited after starting wiki link detection")
        
        // Remove existing wiki links in the range
        self.removeAttribute(.link, range: range) { value in
            guard let url = value as? URL else { return false }
            return url.scheme == "wiki" || (url.scheme == "https" && url.host == "wiki.local")
        }
        
        // Add new wiki links if any found
        guard !wikiLinks.isEmpty else { return }
        
        self.beginEditing()
        for wikiLink in wikiLinks {
            self.addAttribute(.link, value: wikiLink.value, range: wikiLink.range)
        }
        self.endEditing()
    }
}


extension NSTextStorage {
    
    /// Removes attributes with a predicate.
    /// 
    /// - Parameters:
    ///   - name: The attribute name to remove.
    ///   - range: The range to remove from.
    ///   - predicate: Predicate to test attribute values.
    func removeAttribute(_ name: NSAttributedString.Key, range: NSRange, predicate: (Any) -> Bool) {
        var rangesToRemove: [NSRange] = []
        
        self.enumerateAttribute(name, in: range) { value, range, _ in
            if let value = value, predicate(value) {
                rangesToRemove.append(range)
            }
        }
        
        for range in rangesToRemove {
            self.removeAttribute(name, range: range)
        }
    }
}