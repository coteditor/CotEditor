//
//  FolderFindTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-17.
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

import AppKit
import Foundation
import Testing
import FolderFind
import TextFind
import UniformTypeIdentifiers
@testable import CotEditor

@MainActor struct FolderFindTests {
    
    @Test(.timeLimit(.minutes(1)))
    func findUpdatesStateWithSummary() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle\nhay\n".utf8).write(to: rootURL.appending(path: "a.txt"))
        
        let model = try Self.makeModel(rootURL: rootURL)
        model.find(findString: "needle", usesRegularExpression: false, ignoresCase: false, includesHiddenFiles: false)
        
        let summary = try await Self.finishedSummary(from: model)
        
        #expect(summary.metrics.findString == "needle")
        #expect(summary.metrics.matchCount == 1)
        #expect(summary.metrics.skippedItemCount == 0)
        
        model.findStringDidChange(to: "hay")
        
        #expect(model.state == .finished(summary))
        
        model.findStringDidChange(to: "")
        
        #expect(model.state == .finished(summary))
        
        model.find(findString: "", usesRegularExpression: false, ignoresCase: false, includesHiddenFiles: false)
        
        #expect(model.state == .idle)
    }
    
    
    @Test(.timeLimit(.minutes(1)))
    func removeResultUpdatesStateWithSummary() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle\nneedle\n".utf8).write(to: rootURL.appending(path: "a.txt"))
        
        let model = try Self.makeModel(rootURL: rootURL)
        model.find(findString: "needle", usesRegularExpression: false, ignoresCase: false, includesHiddenFiles: false)
        
        let summary = try await Self.finishedSummary(from: model)
        let file = try #require(summary.files.first)
        let match = try #require(file.matches.first)
        
        model.removeResult(for: .match(fileID: file.id, matchID: match.id))
        
        switch model.state {
            case .finished(let summary):
                #expect(summary.metrics.matchCount == 1)
                #expect(summary.files.first?.matches.count == 1)
            default:
                Issue.record("Unexpected state: \(model.state)")
                throw WaitError.unexpectedState
        }
        
        model.removeResult(for: .file(file.id))
        
        switch model.state {
            case .finished(let summary):
                #expect(summary.metrics.matchCount == 0)
                #expect(summary.files.isEmpty)
            default:
                Issue.record("Unexpected state: \(model.state)")
                throw WaitError.unexpectedState
        }
    }
    
    
    @Test(.timeLimit(.minutes(1)))
    func editingIndependentDocumentUpdatesMatchRanges() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        let fileURL = rootURL.appending(path: "a.txt").standardizedFileURL
        try Data("hay\nneedle\n".utf8).write(to: fileURL)
        
        let model = try Self.makeModel(rootURL: rootURL)
        model.find(findString: "needle", usesRegularExpression: false, ignoresCase: false, includesHiddenFiles: false)
        
        let summary = try await Self.finishedSummary(from: model)
        #expect(summary.files.first?.matches.map(\.range) == [NSRange(location: 4, length: 6)])
        
        // edit the file in a document that is not part of the directory document
        let document = try Document(contentsOf: fileURL, ofType: UTType.plainText.identifier)
        NSDocumentController.shared.addDocument(document)
        defer { document.close() }
        
        document.textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "!!")
        
        for await state in Observations({ model.state }) {
            guard
                case .finished(let updated) = state,
                updated.files.first?.matches.map(\.range) == [NSRange(location: 6, length: 6)]
            else { continue }
            
            break
        }
    }
    
    
    @Test(.timeLimit(.minutes(1)))
    func invalidRegularExpressionFails() async throws {
        
        let rootURL = try Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        
        try Data("needle\n".utf8).write(to: rootURL.appending(path: "a.txt"))
        
        let model = try Self.makeModel(rootURL: rootURL)
        model.find(findString: "[", usesRegularExpression: true, ignoresCase: false, includesHiddenFiles: false)
        
        let error = try await Self.failedError(from: model)
        
        switch error {
            case .invalidQuery(let error):
                switch error {
                    case .regularExpression:
                        break
                    default:
                        Issue.record("Unexpected query error: \(error)")
                }
            default:
                Issue.record("Unexpected error: \(error)")
        }
    }
    
    
    @Test func missingFolderFails() {
        
        let model = FolderFinder(document: DirectoryDocument())
        
        model.find(findString: "needle", usesRegularExpression: false, ignoresCase: false, includesHiddenFiles: false)
        
        #expect(model.state == .failed(.folderUnavailable))
    }
    
    
    @Test func emptyFindStringResetsState() {
        
        let model = FolderFinder(document: DirectoryDocument())
        
        model.find(findString: "", usesRegularExpression: false, ignoresCase: false, includesHiddenFiles: false)
        
        #expect(model.state == .idle)
    }
    
    
    // MARK: Private Methods
    
    /// Creates a folder find model.
    ///
    /// - Parameter rootURL: The folder URL for the directory document.
    /// - Returns: A folder find model.
    private static func makeModel(rootURL: URL) throws -> FolderFinder {
        
        let document = DirectoryDocument()
        document.fileURL = rootURL
        try document.read(from: rootURL, ofType: UTType.folder.identifier)
        
        return FolderFinder(document: document)
    }
    
    
    /// Waits until the model finishes a search.
    ///
    /// - Parameter model: The model to observe.
    /// - Returns: The search summary.
    private static func finishedSummary(from model: FolderFinder) async throws -> FolderFind.Summary {
        
        for await state in Observations({ model.state }) {
            switch state {
                case .finished(let summary):
                    return summary
                case .failed(let error):
                    Issue.record("Search failed: \(error)")
                    throw WaitError.unexpectedState
                case .idle, .searching:
                    continue
            }
        }
        
        throw WaitError.unexpectedState
    }
    
    
    /// Waits until the model fails a search.
    ///
    /// - Parameter model: The model to observe.
    /// - Returns: The failure error.
    private static func failedError(from model: FolderFinder) async throws -> FolderFinder.Error {
        
        for await state in Observations({ model.state }) {
            switch state {
                case .failed(let error):
                    return error
                case .finished:
                    Issue.record("Search unexpectedly finished.")
                    throw WaitError.unexpectedState
                case .idle, .searching:
                    continue
            }
        }
        
        throw WaitError.unexpectedState
    }
    
    
    /// Creates a temporary directory for a test.
    ///
    /// - Returns: The created directory URL.
    private static func makeTemporaryDirectory() throws -> URL {
        
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        
        return url
    }
}


private enum WaitError: Error {
    
    case unexpectedState
}
