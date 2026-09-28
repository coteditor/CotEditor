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
    
    
    @Test func failedCreationRemovesPartialWorkingCopy() throws {
        
        let directory = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }
        
        let store = RMateFileStore(directory: directory)
        let metadata = RMateFile.Metadata(displayName: "host:long", path: "/tmp/" + String(repeating: "a", count: 256))
        #expect(throws: CocoaError.self) {
            try store.makeBackingFile(data: Data("unsaved".utf8), metadata: metadata)
        }
        #expect(try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).isEmpty)
    }
}
