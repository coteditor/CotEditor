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
import Observation
import Synchronization
import UniformTypeIdentifiers
import Testing
import Defaults
@testable import CotEditor

@MainActor struct CloudSettingsManagerTests {
    
    /// Verifies that cloud identity changes are observable without enabling automatic saving or retaining the manager.
    ///
    /// - Parameter usesTypedMessage: Whether to post a typed message rather than a legacy notification.
    /// - Throws: An error if creating the defaults store or waiting for observation updates fails.
    @Test(.serialized, .timeLimit(.minutes(1)), arguments: [false, true])
    func cloudIdentityObservationLifecycle(usesTypedMessage: Bool) async throws {
        
        try await self.withDefaults { defaults in
            defaults[.syncsSettings] = false
            var manager: CloudSettingsManager? = CloudSettingsManager(defaults: defaults)
            manager?.start()
            manager?.start()
            weak let weakManager = manager
            var identities = Observations { _ = manager?.ubiquityIdentityToken }.makeAsyncIterator()
            try #require(await identities.next() != nil)
            
            if usesTypedMessage {
                NotificationCenter.default.post(FileManager.UbiquityIdentityDidChangeMessage())
            } else {
                NotificationCenter.default.post(name: .NSUbiquityIdentityDidChange, object: nil)
            }
            
            try #require(await identities.next() != nil)
            #expect(!defaults[.syncsSettings])
            #expect(manager?.hasPendingSave == false)
            
            manager = nil
            #expect(weakManager == nil)
        }
    }
    
    
    /// Verifies that the source identifier survives recreating a manager.
    ///
    /// - Throws: An error if creating, saving, or reading the archives fails.
    @Test func sourceIDIsStable() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        try await self.withDefaults { defaults in
            let manager = CloudSettingsManager(containerURL: directoryURL, defaults: defaults)
            try await self.saveSettings(using: manager, defaults: defaults)
            var archives: [CloudSettingsManager.Archive] = []
            for try await snapshot in manager.archives() {
                archives = snapshot
            }
            let fileURL = try #require(archives.first?.url)
            let saved = try await manager.load(from: fileURL)
            let sourceID = try #require(saved.info.sourceID)
            try await self.withDefaults { otherDefaults in
                let recreated = CloudSettingsManager(containerURL: directoryURL, defaults: otherDefaults)
                try await self.saveSettings(using: recreated, defaults: otherDefaults)
                for try await snapshot in recreated.archives() {
                    archives = snapshot
                }
            }
            
            #expect(archives.map(\.url) == [fileURL])
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
                var archives: [CloudSettingsManager.Archive] = []
                for try await snapshot in manager.archives() {
                    archives = snapshot
                }
                
                #expect(updated.defaults[DefaultKeys.windowWidth.rawValue] == .double(800))
                #expect(updated.themes[obsoleteName] == nil)
                #expect(!FileManager.default.fileExists(atPath: fileURL.appending(path: "Themes/\(obsoleteName)").path))
                #expect(other.defaults[DefaultKeys.windowWidth.rawValue] == .double(640))
                #expect(other.themes[obsoleteName] != nil)
                #expect(other.info.sourceID == otherHostUUID)
                #expect(other.info.machineName == first.info.machineName)
                #expect(other.info.userName == first.info.userName)
                #expect(Set(archives.map(\.url)) == Set([fileURL, otherURL]))
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
                #expect(try await manager.currentArchiveURL() == fileURL)
                #expect(try await otherManager.currentArchiveURL() == otherURL)
                #expect(!FileManager.default.fileExists(atPath: fileURL.deletingLastPathComponent().path))
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
        var archives: [CloudSettingsManager.Archive] = []
        for try await snapshot in manager.archives() {
            archives = snapshot
        }
        #expect(archives.isEmpty)
        
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
        
        for try await snapshot in manager.archives() {
            archives = snapshot
        }
        #expect(Set(archives.map(\.url)) == Set([fileURL, legacyURL]))
        let legacy = try await manager.load(from: legacyURL)
        #expect(legacy.info.sourceID == legacyID)
        await #expect(throws: CloudSettingsError.invalidArchiveURL) {
            try await manager.load(from: unrelatedURL)
        }
    }
    
    
    /// Verifies deleting an unreadable copy while preserving other copies and the current settings.
    ///
    /// - Throws: An error if preparing, deleting, or observing copies fails.
    @Test func deletesUnreadableCopy() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        let document = try PortableSettingsDocument(including: [])
        let otherURL = try self.writeArchive(document, in: directoryURL)
        let original = try await manager.load(from: otherURL)
        let fileURL = otherURL.deletingLastPathComponent().appending(component: "Broken", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
        try Data("invalid".utf8).write(to: fileURL.appending(component: PortableSettingsDocument.Info.filename))
        let windowWidth = UserDefaults.standard[.windowWidth]
        
        try await manager.delete(fileURL)
        
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        #expect(try await manager.load(from: otherURL).info == original.info)
        #expect(UserDefaults.standard[.windowWidth] == windowWidth)
        var archives: [CloudSettingsManager.Archive] = []
        for try await snapshot in manager.archives() {
            archives = snapshot
        }
        #expect(archives.map(\.url) == [otherURL])
    }
    
    
    /// Verifies that deletion is limited to settings copies directly inside the settings directory.
    ///
    /// - Parameter path: The invalid copy path relative to the container.
    /// - Throws: An error if creating the container or copy fails.
    @Test(arguments: ["Documents/Other.cotsettings", "Settings/Nested/Other.cotsettings", "Settings/Other.txt"])
    func rejectsInvalidDeletionURL(path: String) async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        let fileURL = directoryURL.appending(path: path, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
        
        await #expect(throws: CloudSettingsError.invalidArchiveURL) {
            try await manager.delete(fileURL)
        }
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    
    /// Verifies that an already canceled deletion preserves the copy.
    ///
    /// - Throws: An error if preparing the copy fails.
    @Test func canceledDeletionPreservesCopy() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        let fileURL = try self.writeArchive(PortableSettingsDocument(including: []), in: directoryURL)
        let task = Task {
            try await manager.delete(fileURL)
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
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
            for try await _ in manager.archives() {
                Issue.record("Canceled observation must not publish archives.")
            }
        }
        task.cancel()
        
        try await task.value
    }
    
    
    /// Verifies that unavailable metadata does not hide other archives or apply their settings.
    ///
    /// - Throws: An error if preparing or observing the archives fails.
    @Test func observesMetadataWithoutApplyingSettings() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        var document = try PortableSettingsDocument(including: [], sourceID: UUID())
        document.defaults = [DefaultKeys.windowWidth.rawValue: .double(1234)]
        let windowWidth = UserDefaults.standard[.windowWidth]
        let fileURL = try self.writeArchive(document, in: directoryURL)
        try FileManager.default.removeItem(at: fileURL.appending(component: "Defaults.plist"))
        let brokenURL = fileURL.deletingLastPathComponent().appending(component: "Broken", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        try FileManager.default.createDirectory(at: brokenURL, withIntermediateDirectories: true)
        try Data("invalid".utf8).write(to: brokenURL.appending(component: PortableSettingsDocument.Info.filename))
        var snapshots: [[CloudSettingsManager.Archive]] = []
        
        for try await archives in manager.archives() {
            snapshots.append(archives)
        }
        
        let initial = try #require(snapshots.first)
        let final = try #require(snapshots.last)
        #expect(Set(initial.map(\.url)) == Set([fileURL, brokenURL]))
        #expect(final.first { $0.url == fileURL }?.info?.machineName == document.info.machineName)
        #expect(final.first { $0.url == fileURL }?.info?.sourceID != nil)
        #expect(final.first { $0.url == brokenURL }?.info == nil)
        #expect(UserDefaults.standard[.windowWidth] == windowWidth)
    }
    
    
    /// Verifies that a query receives early initial results and reports additions and removals until cancellation.
    ///
    /// - Throws: An error if preparing files or waiting for query results fails.
    @Test func queryReportsArchiveUpdates() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let firstURL = directoryURL.appending(component: "First", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        let secondURL = directoryURL.appending(component: "Second", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        let unrelatedURL = directoryURL.appending(component: "Other.txt")
        try FileManager.default.createDirectory(at: firstURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondURL, withIntermediateDirectories: true)
        try Data().write(to: unrelatedURL)
        let query = TestMetadataQuery(urls: [firstURL, unrelatedURL])
        var snapshots: [[URL]] = []
        let task = Task {
            try await CloudSettingsManager.queryArchiveURLs(using: query, in: directoryURL) { urls in
                snapshots.append(urls)
                switch snapshots.count {
                    case 1:
                        query.urls = [firstURL, secondURL]
                        NotificationCenter.default.post(name: .NSMetadataQueryDidUpdate, object: query)
                    case 2:
                        query.urls = [secondURL]
                        NotificationCenter.default.post(name: .NSMetadataQueryDidUpdate, object: query)
                    default:
                        break
                }
            }
        }
        defer { task.cancel() }
        try #require(await Task.waitFor { snapshots.count == 3 })
        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        
        #expect(snapshots == [[firstURL], [firstURL, secondURL], [secondURL]])
        #expect(query.wasStopped)
    }
    
    
    /// Verifies that observation cancellation stops the query before or during the initial gathering.
    ///
    /// - Parameter cancelsBeforeStarting: Whether to cancel before the task starts.
    /// - Throws: An error if preparing files or waiting for the query fails.
    @Test(arguments: [false, true])
    func canceledQueryStops(cancelsBeforeStarting: Bool) async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let query = TestMetadataQuery(urls: [], postsInitialResults: false)
        var receivedResults = false
        let task = Task {
            try await CloudSettingsManager.queryArchiveURLs(using: query, in: directoryURL) { _ in
                receivedResults = true
            }
        }
        defer { task.cancel() }
        if !cancelsBeforeStarting {
            try #require(await Task.waitFor { query.wasStarted })
        }
        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        
        #expect(!receivedResults)
        #expect(query.wasStopped)
    }
    
    
    /// Verifies that canceling consumption terminates the producer while metadata access is waiting.
    ///
    /// - Throws: An error if preparing the archive, consuming the stream, or waiting for cleanup fails.
    @Test func canceledStreamStopsMetadataReading() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        var manager: CloudSettingsManager? = CloudSettingsManager(containerURL: directoryURL)
        let document = try PortableSettingsDocument(including: [])
        let fileURL = try self.writeArchive(document, in: directoryURL)
        let presenter = SuspendedMetadataPresenter(fileURL: fileURL.appending(component: PortableSettingsDocument.Info.filename))
        NSFileCoordinator.addFilePresenter(presenter)
        defer {
            presenter.resume()
            NSFileCoordinator.removeFilePresenter(presenter)
        }
        weak let weakManager = manager
        let stream = try #require(manager).archives()
        manager = nil
        var receivedResults = false
        let task = Task {
            for try await _ in stream {
                receivedResults = true
            }
        }
        defer { task.cancel() }
        try #require(await Task.waitFor { presenter.isWaiting && receivedResults })
        task.cancel()
        try await task.value
        
        try #require(await Task.waitFor { weakManager == nil })
    }
    
    
    /// Verifies that discovery failures reach the stream consumer.
    ///
    /// - Throws: An error if preparing the unreadable directory fails.
    @Test func streamReportsDiscoveryError() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        let settingsURL = directoryURL.appending(component: "Settings", directoryHint: .isDirectory)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: settingsURL.path)
            try? FileManager.default.removeItem(at: directoryURL)
        }
        try FileManager.default.createDirectory(at: settingsURL, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: settingsURL.path)
        let manager = CloudSettingsManager(containerURL: directoryURL)
        
        await #expect(throws: CocoaError.self) {
            for try await _ in manager.archives() {
                Issue.record("Failed discovery must not publish archives.")
            }
        }
    }
    
    
    /// Verifies that a slow consumer receives only the latest complete archive list.
    ///
    /// - Throws: An error if creating the archive, waiting for completion, or consuming the stream fails.
    @Test func streamBuffersLatestSnapshot() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let sourceID = UUID()
        var manager: CloudSettingsManager? = CloudSettingsManager(containerURL: directoryURL)
        let document = try PortableSettingsDocument(including: [], sourceID: sourceID)
        let fileURL = try self.writeArchive(document, in: directoryURL)
        weak let weakManager = manager
        let stream = try #require(manager).archives()
        manager = nil
        
        // wait until the producer finishes before consuming the buffered snapshots
        try #require(await Task.waitFor { weakManager == nil })
        var snapshots: [[CloudSettingsManager.Archive]] = []
        for try await archives in stream {
            snapshots.append(archives)
        }
        
        #expect(snapshots.count == 1)
        let archive = try #require(snapshots.first?.first)
        #expect(archive.url == fileURL)
        #expect(archive.info?.sourceID == sourceID)
    }
    
    
    /// Verifies that an unsuccessful query start is reported and cleaned up.
    ///
    /// - Throws: An error if preparing the directory fails.
    @Test func failedQueryStartStopsObservation() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let query = TestMetadataQuery(urls: [], startsSuccessfully: false)
        
        await #expect(throws: CloudSettingsError.metadataQueryFailed) {
            try await CloudSettingsManager.queryArchiveURLs(using: query, in: directoryURL) { _ in
                Issue.record("A failed query must not return results.")
            }
        }
        #expect(query.wasStopped)
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


private final class TestMetadataQuery: NSMetadataQuery {
    
    var urls: [URL]
    private let postsInitialResults: Bool
    private let startsSuccessfully: Bool
    private(set) var wasStarted = false
    private(set) var wasStopped = false
    
    override var results: [Any]  { self.urls.map(TestMetadataItem.init(fileURL:)) }
    
    
    /// Creates a query that supplies file metadata without depending on Spotlight indexing.
    ///
    /// - Parameters:
    ///   - urls: The URLs represented by the query results.
    ///   - postsInitialResults: Whether start() posts the initial gathering notification.
    ///   - startsSuccessfully: Whether start() succeeds.
    init(urls: [URL], postsInitialResults: Bool = true, startsSuccessfully: Bool = true) {
        
        self.urls = urls
        self.postsInitialResults = postsInitialResults
        self.startsSuccessfully = startsSuccessfully
        super.init()
    }
    
    
    override func start() -> Bool {
        
        self.wasStarted = true
        if self.startsSuccessfully && self.postsInitialResults {
            NotificationCenter.default.post(name: .NSMetadataQueryDidFinishGathering, object: self)
        }
        return self.startsSuccessfully
    }
    
    
    override func stop() {
        
        self.wasStopped = true
    }
    
    
    override func disableUpdates() {}
    
    
    override func enableUpdates() {}
}


private final class TestMetadataItem: NSMetadataItem {
    
    private let fileURL: URL
    
    
    /// Creates a metadata item with a known URL independent of Spotlight indexing.
    ///
    /// - Parameter fileURL: The URL returned by the metadata item.
    init(fileURL: URL) {
        
        self.fileURL = fileURL
        super.init()
    }
    
    
    override func value(forAttribute key: String) -> Any? {
        
        key == NSMetadataItemURLKey ? self.fileURL : nil
    }
}


/// A presenter that holds a coordinated metadata read until the test resumes it.
private final class SuspendedMetadataPresenter: NSObject, NSFilePresenter {
    
    let presentedItemURL: URL?
    let presentedItemOperationQueue = OperationQueue()
    private let reader = Mutex<(@Sendable ((@Sendable () -> Void)?) -> Void)?>(nil)
    
    /// Whether a coordinated metadata read is currently suspended.
    var isWaiting: Bool {
        
        self.reader.withLock { $0 != nil }
    }
    
    
    /// Creates a presenter for the archive's information file.
    ///
    /// - Parameter fileURL: The URL of the information file.
    init(fileURL: URL) {
        
        self.presentedItemURL = fileURL
        super.init()
    }
    
    
    /// Suspends the coordinated reader.
    ///
    /// - Parameter reader: The accessor to invoke when the information file can be read.
    func relinquishPresentedItem(toReader reader: @escaping @Sendable ((@Sendable () -> Void)?) -> Void) {
        
        self.reader.withLock { $0 = reader }
    }
    
    
    /// Allows the suspended reader to proceed.
    func resume() {
        
        let reader = self.reader.withLock {
            let reader = $0
            $0 = nil
            return reader
        }
        reader?(nil)
    }
}
