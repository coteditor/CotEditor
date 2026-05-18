//
//  DocumentHistory.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import UniformTypeIdentifiers
import URLUtils

struct DocumentHistory {
    
    struct Entry {
        
        var bookmarkData: Data
        var opensAsPlainText: Bool
        var fileType: UTType?
    }
    
    
    struct ResolvedEntry {
        
        var url: URL
        var bookmarkData: Data?
        var fileType: UTType?
    }
    
    
    struct Item {
        
        var index: Int
        var entry: Entry
        var url: URL
    }
    
    
    var entries: [Entry] = []
    var currentIndex: Int?
    var resolveEntry: (Entry) throws -> ResolvedEntry = { try $0.resolve() }
    
    
    /// Records a document URL in the history.
    ///
    /// - Parameters:
    ///   - fileURL: The document URL to record.
    ///   - opensAsPlainText: Whether the document should be opened as plain text.
    ///   - fileType: The type of the document.
    mutating func record(fileURL: URL, opensAsPlainText: Bool, fileType: UTType?) {
        
        guard let entry = try? Entry(fileURL: fileURL, opensAsPlainText: opensAsPlainText, fileType: fileType) else { return }
        
        self.record(entry, resolvedURL: fileURL)
    }
    
    
    /// Records a document entry in the history.
    ///
    /// - Parameters:
    ///   - entry: The document history entry to record.
    ///   - resolvedURL: The resolved URL of the entry.
    mutating func record(_ entry: Entry, resolvedURL: URL) {
        
        if let currentIndex {
            let isCurrentItem = (try? self.resolveEntry(self.entries[currentIndex]).url) == resolvedURL
            
            self.entries.removeSubrange(self.entries.index(after: currentIndex)..<self.entries.endIndex)
            
            if isCurrentItem {
                self.entries[currentIndex] = entry
                return
            }
        }
        
        self.entries.append(entry)
        self.currentIndex = self.entries.index(before: self.entries.endIndex)
    }
    
    
    /// Returns whether the history has an item in the given direction.
    ///
    /// - Parameter forward: Whether to evaluate the forward direction.
    /// - Returns: `true` if the history can navigate in the given direction.
    func canNavigate(forward: Bool) -> Bool {
        
        guard let currentIndex else { return false }
        
        return forward
            ? currentIndex < self.entries.index(before: self.entries.endIndex)
            : currentIndex > self.entries.startIndex
    }
    
    
    /// Returns the next item in the given direction.
    ///
    /// - Parameter forward: Whether to resolve the forward direction.
    /// - Returns: The next history item, if found.
    mutating func nextItem(forward: Bool) -> Item? {
        
        let offset = forward ? 1 : -1
        while let currentIndex {
            let index = currentIndex + offset
            guard self.entries.indices.contains(index) else { return nil }
            
            if let item = self.item(at: index) {
                return item
            }
        }
        
        return nil
    }
    
    
    /// Returns the menu items in the given direction.
    ///
    /// - Parameter forward: Whether to list the forward direction.
    /// - Returns: The history items for a menu.
    mutating func menuItems(forward: Bool) -> [Item] {
        
        guard let currentIndex else { return [] }
        
        let offset = forward ? 1 : -1
        var index = currentIndex + offset
        var items: [Item] = []
        while self.entries.indices.contains(index) {
            if let item = self.item(at: index) {
                items.append(item)
                index += offset
            } else if !forward {
                // -> Removing an earlier entry shifts the indexes of already resolved backward items.
                for itemIndex in items.indices where items[itemIndex].index > index {
                    items[itemIndex].index -= 1
                }
                index += offset
            }
        }
        
        return items
    }
    
    
    /// Returns the item at the given index.
    ///
    /// - Note: If the entry can't be resolved, it is removed from the history.
    ///
    /// - Parameter index: The index to resolve.
    /// - Returns: The resolved history item, or `nil` if the entry was invalid.
    mutating func item(at index: Int) -> Item? {
        
        guard self.entries.indices.contains(index) else { return nil }
        
        let resolvedEntry: ResolvedEntry
        do {
            resolvedEntry = try self.resolveEntry(self.entries[index])
        } catch {
            self.removeEntry(at: index)
            return nil
        }
        
        var entry = self.entries[index]
        entry.bookmarkData = resolvedEntry.bookmarkData ?? entry.bookmarkData
        entry.fileType = resolvedEntry.fileType ?? entry.fileType
        self.entries[index] = entry
        
        return Item(index: index, entry: entry, url: resolvedEntry.url)
    }
    
    
    /// Selects the given item as the current item.
    ///
    /// - Parameter item: The item to select.
    mutating func select(_ item: Item) {
        
        guard self.entries.indices.contains(item.index) else { return }
        
        self.currentIndex = item.index
    }
    
    
    /// Removes the entry at the given index.
    ///
    /// - Parameter index: The index to remove.
    private mutating func removeEntry(at index: Int) {
        
        self.entries.remove(at: index)
        
        guard let currentIndex else { return }
        
        if self.entries.isEmpty {
            self.currentIndex = nil
        } else if index < currentIndex {
            self.currentIndex = self.entries.index(before: currentIndex)
        } else if index == currentIndex {
            self.currentIndex = min(currentIndex, self.entries.index(before: self.entries.endIndex))
        }
    }
}


private extension DocumentHistory.Entry {
    
    /// Initializes a history entry for the given document URL.
    ///
    /// - Parameters:
    ///   - fileURL: The document URL to bookmark.
    ///   - opensAsPlainText: Whether the document should be opened as plain text.
    ///   - fileType: The type of the document.
    init(fileURL: URL, opensAsPlainText: Bool, fileType: UTType? = nil) throws {
        
        let bookmarkData = try fileURL.bookmarkData(options: .withSecurityScope)
        
        self.init(bookmarkData: bookmarkData, opensAsPlainText: opensAsPlainText, fileType: fileType)
    }
    
    
    /// Resolves the bookmarked URL.
    ///
    /// - Returns: The resolved entry information.
    /// - Throws: An error if the bookmark cannot be resolved.
    func resolve() throws -> DocumentHistory.ResolvedEntry {
        
        var isStale = false
        let url = try URL(resolvingBookmarkData: self.bookmarkData, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
        
        guard url.isReachable else { throw CocoaError(.fileReadNoSuchFile) }
        
        let bookmarkData = isStale ? try? url.bookmarkData(options: .withSecurityScope) : nil
        let fileType = (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType
        
        return DocumentHistory.ResolvedEntry(url: url, bookmarkData: bookmarkData, fileType: fileType)
    }
}
