//
//  DocumentHistoryTests.swift
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
import Testing
@testable import CotEditor

struct DocumentHistoryTests {
    
    @Test func navigatesPreviousAndForward() throws {
        
        var history = self.makeHistory(["A.txt", "B.txt", "C.txt"], currentIndex: 2)
        
        let nextPreviousItem = history.nextItem(forward: false)
        let previousItem = try #require(nextPreviousItem)
        #expect(previousItem.url.lastPathComponent == "B.txt")
        history.select(previousItem)
        
        let nextForwardItem = history.nextItem(forward: true)
        let forwardItem = try #require(nextForwardItem)
        #expect(forwardItem.url.lastPathComponent == "C.txt")
    }
    
    
    @Test func discardsForwardItemsWhenRecordingAfterGoingBack() throws {
        
        var history = self.makeHistory(["A.txt", "B.txt", "C.txt"], currentIndex: 2)
        let nextPreviousItem = history.nextItem(forward: false)
        let previousItem = try #require(nextPreviousItem)
        history.select(previousItem)
        
        history.record(self.historyEntry("D.txt"), resolvedURL: self.historyURL("D.txt"))
        
        #expect(!history.canNavigate(forward: true))
        #expect(history.menuItems(forward: false).map(\.url.lastPathComponent) == ["B.txt", "A.txt"])
    }
    
    
    @Test func doesNotRecordConsecutiveDuplicateItems() {
        
        var history = self.makeHistory()
        
        history.record(self.historyEntry("A.txt"), resolvedURL: self.historyURL("A.txt"))
        history.record(self.historyEntry("A.txt", opensAsPlainText: true), resolvedURL: self.historyURL("A.txt"))
        
        #expect(history.entries.count == 1)
        #expect(history.entries.first?.opensAsPlainText == true)
        #expect(!history.canNavigate(forward: false))
        #expect(!history.canNavigate(forward: true))
    }
    
    
    @Test func menuItemsAreOrderedFromNearest() {
        
        var history = self.makeHistory(["A.txt", "B.txt", "C.txt", "D.txt"], currentIndex: 2)
        
        #expect(history.menuItems(forward: false).map(\.url.lastPathComponent) == ["B.txt", "A.txt"])
        #expect(history.menuItems(forward: true).map(\.url.lastPathComponent) == ["D.txt"])
    }
    
    
    @Test func prunesUnresolvableItems() throws {
        
        var history = self.makeHistory(["A.txt", "B.txt", "C.txt"], currentIndex: 0, unresolvedNames: ["B.txt"])
        
        let nextForwardItem = history.nextItem(forward: true)
        let forwardItem = try #require(nextForwardItem)
        
        #expect(forwardItem.url.lastPathComponent == "C.txt")
        #expect(history.entries.map { self.historyName($0) } == ["A.txt", "C.txt"])
    }
    
    
    @Test func menuItemsKeepIndexesAfterPruningEarlierItems() throws {
        
        var history = self.makeHistory(["A.txt", "B.txt", "C.txt", "D.txt"], currentIndex: 3, unresolvedNames: ["B.txt"])
        
        let items = history.menuItems(forward: false)
        let item = try #require(items.first { $0.url.lastPathComponent == "C.txt" })
        
        #expect(history.entries.map { self.historyName($0) } == ["A.txt", "C.txt", "D.txt"])
        #expect(item.index == 1)
        #expect(history.item(at: item.index)?.url.lastPathComponent == "C.txt")
    }
    
    
    @Test func updatesResolvedMetadata() throws {
        
        let updatedBookmarkData = Data("B-updated.txt".utf8)
        var history = self.makeHistory(["A.txt", "B.txt"], currentIndex: 0) { entry in
            let name = self.historyName(entry)
            return .init(url: self.historyURL(name), bookmarkData: updatedBookmarkData, fileType: .png)
        }
        
        let nextForwardItem = history.nextItem(forward: true)
        let item = try #require(nextForwardItem)
        
        #expect(item.entry.bookmarkData == updatedBookmarkData)
        #expect(item.entry.fileType == .png)
        #expect(history.entries[1].bookmarkData == updatedBookmarkData)
        #expect(history.entries[1].fileType == .png)
    }
    
    
    // MARK: Private Methods
    
    private func makeHistory(
        _ names: [String] = [],
        currentIndex: Int? = nil,
        unresolvedNames: Set<String> = [],
        resolveEntry: ((DocumentHistory.Entry) throws -> DocumentHistory.ResolvedEntry)? = nil
    ) -> DocumentHistory {
        
        let entries = names.map { self.historyEntry($0) }
        
        return DocumentHistory(entries: entries, currentIndex: currentIndex) { entry in
            if let resolveEntry {
                return try resolveEntry(entry)
            }
            
            let name = self.historyName(entry)
            if unresolvedNames.contains(name) {
                throw CocoaError(.fileReadNoSuchFile)
            }
            
            return .init(url: self.historyURL(name), bookmarkData: nil, fileType: entry.fileType)
        }
    }
    
    
    private func historyEntry(_ name: String, opensAsPlainText: Bool = false) -> DocumentHistory.Entry {
        
        .init(bookmarkData: Data(name.utf8), opensAsPlainText: opensAsPlainText, fileType: .plainText)
    }
    
    
    private func historyName(_ entry: DocumentHistory.Entry) -> String {
        
        String(bytes: entry.bookmarkData, encoding: .utf8) ?? ""
    }
    
    
    private func historyURL(_ name: String) -> URL {
        
        URL(fileURLWithPath: "/tmp").appending(path: name, directoryHint: .notDirectory)
    }
}
