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
import Synchronization
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
        try await self.withDefaults { defaults in
            let manager = CloudSettingsManager(containerURL: directoryURL, defaults: defaults)
            try await self.saveSettings(using: manager, defaults: defaults)
            let urls = try await manager.archiveURLs()
            let fileURL = try #require(urls.first)
            let saved = try await manager.load(from: fileURL)
            let sourceID = try #require(saved.info.sourceID)
            try await self.withDefaults { otherDefaults in
                let recreated = CloudSettingsManager(containerURL: directoryURL, defaults: otherDefaults)
                try await self.saveSettings(using: recreated, defaults: otherDefaults)
            }
            
            #expect(fileURL.deletingPathExtension().lastPathComponent == "\(sourceID.uuidString)-\(NSUserName())")
        }
    }
    
    
    /// Verifies that replacing a snapshot removes obsolete files and preserves another source's archive.
    ///
    /// - Throws: An error if creating, saving, discovering, or reading the archives fails.
    @Test func savesSeparateArchivesAndReplacesSnapshot() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        try await self.withDefaults { defaults in
            try await self.withDefaults { otherDefaults in
                let hostUUID = UUID()
                let otherHostUUID = UUID()
                let manager = CloudSettingsManager(containerURL: directoryURL, defaults: defaults, hostUUID: hostUUID)
                let otherManager = CloudSettingsManager(containerURL: directoryURL, defaults: otherDefaults, hostUUID: otherHostUUID)
                let fileURL = directoryURL.appending(path: "Settings/\(hostUUID.uuidString)-\(NSUserName())", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
                let otherURL = directoryURL.appending(path: "Settings/\(otherHostUUID.uuidString)-\(NSUserName())", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
                let windowWidth = UserDefaults.standard[.windowWidth]
                try await self.saveSettings(using: manager, defaults: defaults)
                try await self.saveSettings(using: otherManager, defaults: otherDefaults)
                
                let obsoleteName = "Obsolete-\(UUID()).cottheme"
                for url in [fileURL, otherURL] {
                    var document = try await manager.load(from: url)
                    document.themes[obsoleteName] = Data("old".utf8)
                    try document.fileWrapper().write(to: url, options: .atomic, originalContentsURL: url)
                }
                let first = try await manager.load(from: fileURL)
                #expect(first.defaults[DefaultKeys.windowWidth.rawValue] == .double(640))
                #expect(first.info.sourceID == hostUUID)
                #expect(first.info.machineName == Host.current().localizedName)
                #expect(first.info.userName == NSUserName())
                
                defaults[.windowWidth] = 800
                try await self.saveSettings(using: manager, defaults: defaults)
                let updated = try await manager.load(from: fileURL)
                let other = try await manager.load(from: otherURL)
                let urls = try await manager.archiveURLs()
                
                #expect(updated.defaults[DefaultKeys.windowWidth.rawValue] == .double(800))
                #expect(updated.themes[obsoleteName] == nil)
                #expect(!FileManager.default.fileExists(atPath: fileURL.appending(path: "Themes/\(obsoleteName)").path))
                #expect(other.defaults[DefaultKeys.windowWidth.rawValue] == .double(640))
                #expect(other.themes[obsoleteName] != nil)
                #expect(other.info.sourceID == otherHostUUID)
                #expect(other.info.machineName == first.info.machineName)
                #expect(other.info.userName == first.info.userName)
                #expect(Set(urls) == Set([fileURL, otherURL]))
                #expect(UserDefaults.standard[.windowWidth] == windowWidth)
            }
        }
    }
    
    
    /// Verifies that different users on the same Mac have separate archives.
    ///
    /// - Throws: An error if creating, saving, or reading the archives fails.
    @Test func savesSeparateArchivesForDifferentUsers() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        try await self.withDefaults { defaults in
            try await self.withDefaults { otherDefaults in
                let hostUUID = UUID()
                let manager = CloudSettingsManager(containerURL: directoryURL, defaults: defaults, hostUUID: hostUUID, userName: "first-user")
                let otherManager = CloudSettingsManager(containerURL: directoryURL, defaults: otherDefaults, hostUUID: hostUUID, userName: "second-user")
                let fileURL = directoryURL.appending(path: "Settings/\(hostUUID.uuidString)-first-user", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
                let otherURL = directoryURL.appending(path: "Settings/\(hostUUID.uuidString)-second-user", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
                try await self.saveSettings(using: manager, defaults: defaults)
                otherDefaults[.windowWidth] = 800
                try await self.saveSettings(using: otherManager, defaults: otherDefaults)
                let first = try await manager.load(from: fileURL)
                let other = try await manager.load(from: otherURL)
                
                #expect(fileURL != otherURL)
                #expect(first.info.sourceID == hostUUID)
                #expect(other.info.sourceID == hostUUID)
                #expect(first.info.userName == "first-user")
                #expect(other.info.userName == "second-user")
                #expect(first.defaults[DefaultKeys.windowWidth.rawValue] == .double(640))
                #expect(other.defaults[DefaultKeys.windowWidth.rawValue] == .double(800))
            }
        }
    }
    
    
    /// Verifies that discovery is limited to archives directly inside the settings directory.
    ///
    /// - Throws: An error if creating or discovering the archives fails.
    @Test func observedArchivesExcludeOtherFiles() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        let emptyURLs = try await manager.archiveURLs()
        #expect(emptyURLs.isEmpty)
        
        let document = try PortableSettingsDocument(including: [])
        let fileURL = try self.writeArchive(document, in: directoryURL)
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
    
    
    /// Verifies that already canceled observation does not publish an empty result.
    ///
    /// - Throws: An error if creating the container directory fails.
    @Test func canceledObservationDoesNotReturnResults() async throws {
        
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
    
    
    /// Runs a test with an isolated defaults store.
    ///
    /// - Parameter body: The test using the defaults store.
    /// - Throws: An error if creating the defaults store or running the test fails.
    private func withDefaults(_ body: (UserDefaults) async throws -> Void) async throws {
        
        let suiteName = "CloudSettingsManagerTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults[.windowWidth] = 640
        
        try await body(defaults)
    }
    
    
    /// Saves settings through automatic saving and then disables further observation.
    ///
    /// - Parameters:
    ///   - manager: The manager used to save settings.
    ///   - defaults: The defaults store observed by the manager.
    /// - Throws: An error if saving settings fails.
    private func saveSettings(using manager: CloudSettingsManager, defaults: UserDefaults) async throws {
        
        defaults[.syncsSettings] = true
        manager.start()
        await manager.flush()
        let error = manager.error
        defaults[.syncsSettings] = false
        await manager.flush()
        
        if let error { throw error }
    }
    
    
    /// Writes a test archive without starting automatic saving.
    ///
    /// - Parameters:
    ///   - document: The snapshot to write.
    ///   - containerURL: The local test container.
    /// - Returns: The archive's URL.
    /// - Throws: An error if creating the directory or writing the archive fails.
    private func writeArchive(_ document: PortableSettingsDocument, in containerURL: URL) throws -> URL {
        
        let directoryURL = containerURL.appending(component: "Settings", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appending(component: UUID().uuidString, directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        try document.fileWrapper().write(to: fileURL, options: .atomic, originalContentsURL: fileURL)
        
        return fileURL
    }
}
