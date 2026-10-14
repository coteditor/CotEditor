//
//  CloudSettingsManagerTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-13.
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
import Defaults
@testable import CotEditor

@MainActor struct CloudSettingsManagerTests {
    
    /// Verifies that the source identifier survives recreating a manager.
    ///
    /// - Throws: An error if creating, saving, or reading the archives fails.
    @Test func sourceIDIsStable() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        let document = try PortableSettingsDocument(including: [])
        let fileURL = try await manager.save(document)
        let saved = try await manager.load(from: fileURL)
        let sourceID = try #require(saved.info.sourceID)
        let recreated = CloudSettingsManager(containerURL: directoryURL)
        let recreatedURL = try await recreated.save(document)
        
        #expect(recreatedURL == fileURL)
        #expect(fileURL.deletingPathExtension().lastPathComponent == "\(sourceID.uuidString)-\(NSUserName())")
    }
    
    
    /// Verifies that replacing a snapshot removes obsolete files and preserves another source's archive.
    ///
    /// - Throws: An error if creating, saving, discovering, or reading the archives fails.
    @Test func savesSeparateArchivesAndReplacesSnapshot() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let hostUUID = UUID()
        let otherHostUUID = UUID()
        let manager = CloudSettingsManager(containerURL: directoryURL, hostUUID: hostUUID)
        let otherManager = CloudSettingsManager(containerURL: directoryURL, hostUUID: otherHostUUID)
        var document = try PortableSettingsDocument(including: [])
        document.info.date = Date(timeIntervalSince1970: 1_700_000_000)
        document.defaults = [DefaultKeys.windowWidth.rawValue: .double(640)]
        document.themes = ["Old.cottheme": Data("old".utf8)]
        document.info.sourceID = UUID()
        let windowWidth = UserDefaults.standard[.windowWidth]
        
        let fileURL = try await manager.save(document)
        let otherURL = try await otherManager.save(document)
        let first = try await manager.load(from: fileURL)
        
        #expect(fileURL != otherURL)
        #expect(first.defaults == document.defaults)
        #expect(first.info.sourceID == hostUUID)
        #expect(first.info.machineName == document.info.machineName)
        #expect(first.info.userName == document.info.userName)
        #expect(first.info.date == document.info.date)
        #expect(UserDefaults.standard[.windowWidth] == windowWidth)
        
        document.defaults[DefaultKeys.windowWidth.rawValue] = .double(800)
        document.themes = [:]
        let updatedURL = try await manager.save(document)
        let updated = try await manager.load(from: updatedURL)
        let other = try await manager.load(from: otherURL)
        let urls = try await manager.archiveURLs()
        
        #expect(updatedURL == fileURL)
        #expect(updated.defaults == document.defaults)
        #expect(updated.themes.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: fileURL.appending(path: "Themes/Old.cottheme").path))
        #expect(other.defaults[DefaultKeys.windowWidth.rawValue] == .double(640))
        #expect(other.themes["Old.cottheme"] != nil)
        #expect(other.info.sourceID == otherHostUUID)
        #expect(other.info.machineName == first.info.machineName)
        #expect(other.info.userName == first.info.userName)
        #expect(Set(urls) == Set([fileURL, otherURL]))
    }
    
    
    /// Verifies that different users on the same Mac have separate archives.
    ///
    /// - Throws: An error if creating, saving, or reading the archives fails.
    @Test func savesSeparateArchivesForDifferentUsers() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let hostUUID = UUID()
        let manager = CloudSettingsManager(containerURL: directoryURL, hostUUID: hostUUID, userName: "first-user")
        let otherManager = CloudSettingsManager(containerURL: directoryURL, hostUUID: hostUUID, userName: "second-user")
        var document = try PortableSettingsDocument(including: [])
        document.defaults = ["Sample": .string("first")]
        let fileURL = try await manager.save(document)
        document.defaults = ["Sample": .string("second")]
        let otherURL = try await otherManager.save(document)
        let first = try await manager.load(from: fileURL)
        let other = try await manager.load(from: otherURL)
        
        #expect(fileURL != otherURL)
        #expect(first.info.sourceID == hostUUID)
        #expect(other.info.sourceID == hostUUID)
        #expect(first.info.userName == "first-user")
        #expect(other.info.userName == "second-user")
        #expect(first.defaults["Sample"] == .string("first"))
        #expect(other.defaults["Sample"] == .string("second"))
    }
    
    
    /// Verifies that discovery is limited to archives directly inside the settings directory.
    ///
    /// - Throws: An error if creating or discovering the archives fails.
    @Test func archiveURLsExcludeOtherFiles() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        let emptyURLs = try await manager.archiveURLs()
        #expect(emptyURLs.isEmpty)
        
        let document = try PortableSettingsDocument(including: [])
        let fileURL = try await manager.save(document)
        let legacyID = UUID()
        var legacyDocument = document
        legacyDocument.info.sourceID = legacyID
        let legacyURL = directoryURL.appending(path: "Settings/\(legacyID.uuidString)", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        try legacyDocument.fileWrapper().write(to: legacyURL, options: .atomic, originalContentsURL: nil)
        let unrelatedURL = directoryURL.appending(path: "Documents/Other.cotsettings")
        try FileManager.default.createDirectory(at: unrelatedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try document.fileWrapper().write(to: unrelatedURL, options: .atomic, originalContentsURL: nil)
        try Data().write(to: directoryURL.appending(path: "Settings/Notes.txt"))
        
        let urls = try await manager.archiveURLs()
        #expect(Set(urls) == Set([fileURL, legacyURL]))
        let legacy = try await manager.load(from: legacyURL)
        #expect(legacy.info.sourceID == legacyID)
        await #expect(throws: CloudSettingsError.invalidArchiveURL) {
            try await manager.load(from: unrelatedURL)
        }
    }
    
    
    /// Verifies that an already canceled save leaves the previous archive intact.
    ///
    /// - Throws: An error if creating or reading the archive fails.
    @Test func canceledSaveKeepsPreviousArchive() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        var document = try PortableSettingsDocument(including: [])
        document.defaults = ["Sample": .string("old")]
        let fileURL = try await manager.save(document)
        document.defaults = ["Sample": .string("new")]
        let task = Task { [document] in
            try await manager.save(document)
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        let saved = try await manager.load(from: fileURL)
        #expect(saved.defaults["Sample"] == .string("old"))
    }
    
    
    /// Verifies that an already canceled load does not read an invalid archive.
    ///
    /// - Throws: An error if creating the archive directory fails.
    @Test func canceledLoadDoesNotReadArchive() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        let fileURL = directoryURL.appending(path: "Settings/Invalid.cotsettings", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
        let task = Task {
            try await manager.load(from: fileURL)
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
    
    
    /// Verifies that an already canceled search does not return an empty result.
    ///
    /// - Throws: An error if creating the container directory fails.
    @Test func canceledSearchDoesNotReturnResults() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        let task = Task {
            try await manager.archiveURLs()
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
    
    
    /// Verifies that a failed write preserves the last successfully saved archive.
    ///
    /// - Throws: An error if preparing or reading the archive fails.
    @Test func failedSaveKeepsPreviousArchive() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        let settingsURL = directoryURL.appending(path: "Settings")
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: settingsURL.path)
            try? FileManager.default.removeItem(at: directoryURL)
        }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        var document = try PortableSettingsDocument(including: [])
        document.defaults = ["Sample": .string("old")]
        let fileURL = try await manager.save(document)
        try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: settingsURL.path)
        document.defaults = ["Sample": .string("new")]
        
        await #expect(throws: CocoaError.self) {
            try await manager.save(document)
        }
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: settingsURL.path)
        let saved = try await manager.load(from: fileURL)
        #expect(saved.defaults["Sample"] == .string("old"))
    }
}
