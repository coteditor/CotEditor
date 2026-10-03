//
//  RMateFileStoreTests.swift
//  RMateTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-09-28.
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
import Testing
import RMate

struct RMateFileStoreTests {
    
    /// Tests creating, restoring, and removing a working copy.
    ///
    /// - Parameters:
    ///   - filename: The remote filename.
    ///   - directoryHint: The directory hint for the store URL.
    /// - Throws: An error if creating, reading, or removing the working copy failed.
    @Test(arguments: ["test.txt", "remote.json", "日本語.txt"], [URL.DirectoryHint.isDirectory, .inferFromPath])
    func workingCopyRoundTrip(filename: String, directoryHint: URL.DirectoryHint) throws {
        
        let path = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString).path(percentEncoded: false)
        let directory = URL(filePath: path, directoryHint: directoryHint)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let store = RMateFileStore(directory: directory)
        let metadata = RMateFile.Metadata(displayName: "host:\(filename)", path: "/tmp/\(filename)")
        let data = Data([0, 10, 13, 255]) + Data("日本語".utf8)
        let url = try store.makeBackingFile(data: data, metadata: metadata)
        #expect(url.lastPathComponent == filename)
        #expect(try Data(contentsOf: url) == data)
        
        let reopenedStore = RMateFileStore(directory: directory)
        #expect(reopenedStore.isBackingFile(url))
        let restoredMetadata = try #require(try reopenedStore.metadata(for: url))
        #expect(restoredMetadata.displayName == metadata.displayName)
        #expect(restoredMetadata.path == metadata.path)
        
        let attributes = try FileManager.default.attributesOfItem(atPath: url.deletingLastPathComponent().deletingLastPathComponent().path(percentEncoded: false))
        #expect(attributes[.posixPermissions] as? Int == 0o700)
        
        try reopenedStore.removeBackingFile(at: url)
        #expect(!FileManager.default.fileExists(atPath: url.deletingLastPathComponent().deletingLastPathComponent().path(percentEncoded: false)))
    }
    
    
    @Test func readsExistingWorkingCopy() throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let backingDirectory = directory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        let contentDirectory = backingDirectory.appending(component: "content", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: contentDirectory, withIntermediateDirectories: true)
        try Data(#"{"displayName":"host:test.txt","path":"/tmp/test.txt"}"#.utf8)
            .write(to: backingDirectory.appending(component: "remote.json"))
        let url = contentDirectory.appending(component: "test.txt")
        try Data("old".utf8).write(to: url)
        
        let store = RMateFileStore(directory: directory)
        #expect(store.isBackingFile(url))
        let metadata = try #require(try store.metadata(for: url))
        #expect(metadata.displayName == "host:test.txt")
        #expect(metadata.path == "/tmp/test.txt")
    }
    
    
    @Test func removalKeepsOtherFiles() throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let store = RMateFileStore(directory: directory)
        let metadata = RMateFile.Metadata(displayName: "host:test.txt", path: "/tmp/test.txt")
        let firstURL = try store.makeBackingFile(data: Data("first".utf8), metadata: metadata)
        let secondURL = try store.makeBackingFile(data: Data("second".utf8), metadata: metadata)
        #expect(firstURL != secondURL)
        
        try store.removeBackingFile(at: firstURL)
        #expect(!FileManager.default.fileExists(atPath: firstURL.deletingLastPathComponent().deletingLastPathComponent().path(percentEncoded: false)))
        #expect(try Data(contentsOf: secondURL) == Data("second".utf8))
        #expect(try store.metadata(for: secondURL)?.path == metadata.path)
        
        let localURL = directory.appending(component: "local.txt")
        try Data("local".utf8).write(to: localURL)
        #expect(!store.isBackingFile(localURL))
        #expect(try store.metadata(for: localURL) == nil)
        try store.removeBackingFile(at: localURL)
        #expect(try Data(contentsOf: localURL) == Data("local".utf8))
    }
    
    
    /// Tests discarding a partial working copy when writing its content fails.
    ///
    /// - Throws: An error if reading or removing the test directory failed.
    @Test func failedCreationRemovesPartialWorkingCopy() throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let store = RMateFileStore(directory: directory)
        let metadata = RMateFile.Metadata(displayName: "host:long", path: "/tmp/" + String(repeating: "a", count: 256))
        #expect(throws: CocoaError.self) {
            try store.makeBackingFile(data: Data("unsaved".utf8), metadata: metadata)
        }
        #expect(try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).map(\.lastPathComponent) == ["Pending Deletion"])
        #expect(try FileManager.default.contentsOfDirectory(at: directory.appending(component: "Pending Deletion"), includingPropertiesForKeys: nil).isEmpty)
    }
    
    
    /// Tests removing complete and partially removed discarded copies without affecting working copies.
    ///
    /// - Throws: An error if creating, reading, or removing the test files failed.
    @Test func discardedFilesCleanup() throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let store = RMateFileStore(directory: directory)
        let metadata = RMateFile.Metadata(displayName: "host:test.txt", path: "/tmp/test.txt")
        let workingURL = try store.makeBackingFile(data: Data("unsaved".utf8), metadata: metadata)
        let discardedURL = try store.makeBackingFile(data: Data("discarded".utf8), metadata: metadata)
        let discardedDirectory = discardedURL.deletingLastPathComponent().deletingLastPathComponent()
        let pendingDirectory = directory.appending(component: "Pending Deletion", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: pendingDirectory, withIntermediateDirectories: false)
        try FileManager.default.moveItem(at: discardedDirectory, to: pendingDirectory.appending(component: discardedDirectory.lastPathComponent))
        
        let partialDirectory = pendingDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: partialDirectory, withIntermediateDirectories: false)
        try Data("partial".utf8).write(to: partialDirectory.appending(component: "remote.json"))
        
        let reopenedStore = RMateFileStore(directory: directory)
        try reopenedStore.removeDiscardedFiles()
        #expect(try FileManager.default.contentsOfDirectory(at: pendingDirectory, includingPropertiesForKeys: nil).isEmpty)
        #expect(try Data(contentsOf: workingURL) == Data("unsaved".utf8))
        #expect(try reopenedStore.metadata(for: workingURL)?.path == metadata.path)
        
        try reopenedStore.removeDiscardedFiles()
        #expect(try FileManager.default.contentsOfDirectory(at: pendingDirectory, includingPropertiesForKeys: nil).isEmpty)
    }
    
    
    /// Tests leaving existing and malformed copies outside the deletion directory untouched.
    ///
    /// - Parameter metadata: Existing or malformed metadata for an unmarked working copy.
    /// - Throws: An error if creating, reading, or removing the test files failed.
    @Test(arguments: [#"{"displayName":"host:old.txt","path":"/tmp/old.txt"}"#, "invalid metadata"])
    func cleanupKeepsUnmarkedFiles(metadata: String) throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let backingDirectory = directory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        let contentDirectory = backingDirectory.appending(component: "content", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: contentDirectory, withIntermediateDirectories: true)
        let metadataURL = backingDirectory.appending(component: "remote.json")
        try Data(metadata.utf8).write(to: metadataURL)
        let contentURL = contentDirectory.appending(component: "old.txt")
        try Data("recoverable".utf8).write(to: contentURL)
        let localURL = directory.appending(component: "local.txt")
        try Data("local".utf8).write(to: localURL)
        try FileManager.default.createDirectory(at: directory.appending(component: "Pending Deletion"), withIntermediateDirectories: false)
        
        try RMateFileStore(directory: directory).removeDiscardedFiles()
        #expect(try Data(contentsOf: contentURL) == Data("recoverable".utf8))
        #expect(try Data(contentsOf: metadataURL) == Data(metadata.utf8))
        #expect(try Data(contentsOf: localURL) == Data("local".utf8))
    }
    
    
    /// Tests leaving unknown directory names, regular files, and symbolic links in the deletion directory untouched.
    ///
    /// - Throws: An error if creating, reading, or removing the test files failed.
    @Test func cleanupKeepsUnrecognizedEntries() throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let pendingDirectory = directory.appending(component: "Pending Deletion", directoryHint: .isDirectory)
        let nestedDirectory = pendingDirectory.appending(component: "Unrecognized").appending(component: UUID().uuidString)
        try FileManager.default.createDirectory(at: nestedDirectory, withIntermediateDirectories: true)
        let nestedURL = nestedDirectory.appending(component: "local.txt")
        try Data("nested".utf8).write(to: nestedURL)
        let fileURL = pendingDirectory.appending(component: UUID().uuidString)
        try Data("file".utf8).write(to: fileURL)
        
        let localDirectory = directory.appending(component: "Local", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: localDirectory, withIntermediateDirectories: false)
        let localURL = localDirectory.appending(component: "local.txt")
        try Data("local".utf8).write(to: localURL)
        let linkURL = pendingDirectory.appending(component: UUID().uuidString)
        try FileManager.default.createSymbolicLink(at: linkURL, withDestinationURL: localDirectory)
        
        try RMateFileStore(directory: directory).removeDiscardedFiles()
        #expect(try Data(contentsOf: nestedURL) == Data("nested".utf8))
        #expect(try Data(contentsOf: fileURL) == Data("file".utf8))
        #expect(try Data(contentsOf: localURL) == Data("local".utf8))
        #expect(try linkURL.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
    }
    
    
    /// Tests preventing cleanup and disposal from following a symbolic link to the deletion directory.
    ///
    /// - Throws: An error if creating, reading, or removing the test files failed.
    @Test func symbolicDeletionDirectoryKeepsFiles() throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let store = RMateFileStore(directory: directory)
        let metadata = RMateFile.Metadata(displayName: "host:test.txt", path: "/tmp/test.txt")
        let workingURL = try store.makeBackingFile(data: Data("unsaved".utf8), metadata: metadata)
        let localDirectory = directory.appending(component: "Local", directoryHint: .isDirectory)
        let nestedDirectory = localDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: nestedDirectory, withIntermediateDirectories: true)
        let localURL = nestedDirectory.appending(component: "local.txt")
        try Data("local".utf8).write(to: localURL)
        let pendingDirectory = directory.appending(component: "Pending Deletion", directoryHint: .isDirectory)
        try FileManager.default.createSymbolicLink(at: pendingDirectory, withDestinationURL: localDirectory)
        
        try store.removeDiscardedFiles()
        #expect(throws: CocoaError.self) {
            try store.removeBackingFile(at: workingURL)
        }
        #expect(try Data(contentsOf: workingURL) == Data("unsaved".utf8))
        #expect(try store.metadata(for: workingURL)?.path == metadata.path)
        #expect(try Data(contentsOf: localURL) == Data("local".utf8))
        #expect(try pendingDirectory.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true)
    }
    
    
    /// Tests that cleanup does not create missing storage directories.
    ///
    /// - Parameter createsRoot: Whether to create the store directory before cleanup.
    /// - Throws: An error if creating or removing the test directory failed.
    @Test(arguments: [false, true])
    func cleanupDoesNotCreateStorage(createsRoot: Bool) throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        if createsRoot {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        }
        
        try RMateFileStore(directory: directory).removeDiscardedFiles()
        #expect(FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)) == createsRoot)
        #expect(!FileManager.default.fileExists(atPath: directory.appending(component: "Pending Deletion").path(percentEncoded: false)))
    }
    
    
    /// Tests retaining the working copy and its metadata when moving it to the deletion directory fails.
    ///
    /// - Throws: An error if creating, reading, or removing the test files failed.
    @Test func failedDiscardKeepsWorkingCopy() throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let store = RMateFileStore(directory: directory)
        let metadata = RMateFile.Metadata(displayName: "host:test.txt", path: "/tmp/test.txt")
        let url = try store.makeBackingFile(data: Data("unsaved".utf8), metadata: metadata)
        let backingDirectory = url.deletingLastPathComponent().deletingLastPathComponent()
        let destinationDirectory = directory.appending(component: "Pending Deletion").appending(component: backingDirectory.lastPathComponent)
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        let existingURL = destinationDirectory.appending(component: "existing.txt")
        try Data("existing".utf8).write(to: existingURL)
        
        #expect(throws: CocoaError.self) {
            try store.removeBackingFile(at: url)
        }
        #expect(try Data(contentsOf: url) == Data("unsaved".utf8))
        #expect(try store.metadata(for: url)?.displayName == metadata.displayName)
        #expect(try store.metadata(for: url)?.path == metadata.path)
        #expect(try Data(contentsOf: existingURL) == Data("existing".utf8))
    }
    
    
    /// Tests retaining a discarded copy after a deletion failure and removing it on a later retry.
    ///
    /// - Throws: An error if creating, reading, or removing the test files failed.
    @Test func failedRemovalIsRetried() throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let store = RMateFileStore(directory: directory)
        let metadata = RMateFile.Metadata(displayName: "host:test.txt", path: "/tmp/test.txt")
        let url = try store.makeBackingFile(data: Data("discarded".utf8), metadata: metadata)
        let backingDirectory = url.deletingLastPathComponent().deletingLastPathComponent()
        let pendingDirectory = directory.appending(component: "Pending Deletion", directoryHint: .isDirectory)
        let discardedDirectory = pendingDirectory.appending(component: backingDirectory.lastPathComponent, directoryHint: .isDirectory)
        let discardedURL = discardedDirectory.appending(path: "content/test.txt")
        defer {
            try? FileManager.default.setAttributes([.immutable: false], ofItemAtPath: url.path(percentEncoded: false))
            try? FileManager.default.setAttributes([.immutable: false], ofItemAtPath: discardedURL.path(percentEncoded: false))
        }
        try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: url.path(percentEncoded: false))
        
        #expect(throws: CocoaError.self) {
            try store.removeBackingFile(at: url)
        }
        #expect(!FileManager.default.fileExists(atPath: backingDirectory.path(percentEncoded: false)))
        #expect(try Data(contentsOf: discardedURL) == Data("discarded".utf8))
        
        let otherDirectory = pendingDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: otherDirectory, withIntermediateDirectories: false)
        try Data("other".utf8).write(to: otherDirectory.appending(component: "test.txt"))
        let reopenedStore = RMateFileStore(directory: directory)
        #expect(throws: CocoaError.self) {
            try reopenedStore.removeDiscardedFiles()
        }
        #expect(!FileManager.default.fileExists(atPath: otherDirectory.path(percentEncoded: false)))
        #expect(try Data(contentsOf: discardedURL) == Data("discarded".utf8))
        
        try FileManager.default.setAttributes([.immutable: false], ofItemAtPath: discardedURL.path(percentEncoded: false))
        try reopenedStore.removeDiscardedFiles()
        #expect(try FileManager.default.contentsOfDirectory(at: pendingDirectory, includingPropertiesForKeys: nil).isEmpty)
    }
}
