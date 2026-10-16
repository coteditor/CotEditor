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
import UniformTypeIdentifiers
import Testing
import Defaults
@testable import CotEditor

@MainActor struct CloudSettingsManagerTests {
    
    /// Verifies that cloud identity changes are observable without enabling automatic saving or retaining the manager.
    ///
    /// - Throws: An error if creating the defaults store or waiting for observation updates fails.
    @Test(.timeLimit(.minutes(1))) func cloudIdentityObservationLifecycle() async throws {
        
        try await self.withDefaults { defaults in
            defaults[.syncsSettings] = false
            var manager: CloudSettingsManager? = CloudSettingsManager(defaults: defaults)
            manager?.start()
            manager?.start()
            weak let weakManager = manager
            var identities = Observations { _ = manager?.ubiquityIdentityToken }.makeAsyncIterator()
            try #require(await identities.next() != nil)
            
            NotificationCenter.default.post(name: .NSUbiquityIdentityDidChange, object: nil)
            
            try #require(await identities.next() != nil)
            #expect(!defaults[.syncsSettings])
            #expect(manager?.hasPendingSave == false)
            
            manager = nil
            #expect(weakManager == nil)
        }
    }
    
    
    /// Verifies the current source's stable URL and replacing its snapshot without changing another copy.
    ///
    /// - Throws: An error if creating, saving, discovering, or reading the archives fails.
    @Test func savesAndReplacesCurrentCopy() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        try await self.withDefaults { defaults in
            let manager = CloudSettingsManager(containerURL: directoryURL, defaults: defaults)
            let fileURL = try await manager.currentArchiveURL()
            let recreated = CloudSettingsManager(containerURL: directoryURL)
            #expect(try await recreated.currentArchiveURL() == fileURL)
            #expect(!FileManager.default.fileExists(atPath: fileURL.deletingLastPathComponent().path))
            try await self.saveSettings(using: manager, defaults: defaults)
            var original = try await manager.load(from: fileURL)
            let sourceID = try #require(original.info.sourceID)
            #expect(fileURL.deletingPathExtension().lastPathComponent == "\(sourceID.uuidString)-\(NSUserName())")
            #expect(original.info.machineName == Host.current().localizedName)
            #expect(original.info.userName == NSUserName())
            
            let obsoleteName = "Obsolete.cottheme"
            original.themes[obsoleteName] = Data("old".utf8)
            try original.fileWrapper().write(to: fileURL, options: .atomic, originalContentsURL: fileURL)
            var otherCopy = original
            otherCopy.info.sourceID = UUID()
            let otherURL = try self.writeArchive(otherCopy, in: directoryURL)
            
            defaults[.windowWidth] = 800
            try await self.saveSettings(using: manager, defaults: defaults)
            let updated = try await manager.load(from: fileURL)
            let other = try await manager.load(from: otherURL)
            
            #expect(updated.defaults[DefaultKeys.windowWidth.rawValue] == .double(800))
            #expect(updated.themes[obsoleteName] == nil)
            #expect(!FileManager.default.fileExists(atPath: fileURL.appending(path: "Themes/\(obsoleteName)").path))
            #expect(updated.info.sourceID == sourceID)
            #expect(other.info == otherCopy.info)
            #expect(other.defaults == original.defaults)
            #expect(other.themes[obsoleteName] != nil)
            for try await archives in manager.archives() {
                #expect(Set(archives.map(\.url)) == Set([fileURL, otherURL]))
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
    }
    
    
    /// Verifies deleting an unreadable copy while preserving other copies.
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
        
        try await manager.delete(fileURL)
        
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        #expect(try await manager.load(from: otherURL).info == original.info)
        var archives: [CloudSettingsManager.Archive] = []
        for try await snapshot in manager.archives() {
            archives = snapshot
        }
        #expect(archives.map(\.url) == [otherURL])
    }
    
    
    /// Verifies that loading and deletion are limited to copies directly inside the settings directory.
    ///
    /// - Parameter path: The invalid copy path relative to the container.
    /// - Throws: An error if creating the container or copy fails.
    @Test(arguments: ["Documents/Other.cotsettings", "Settings/Nested/Other.cotsettings", "Settings/Other.txt"])
    func rejectsInvalidArchiveURL(path: String) async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        let fileURL = directoryURL.appending(path: path, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
        
        await #expect(throws: CloudSettingsError.invalidArchiveURL) {
            try await manager.load(from: fileURL)
        }
        await #expect(throws: CloudSettingsError.invalidArchiveURL) {
            try await manager.delete(fileURL)
        }
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    
    /// Verifies that canceled access neither reads an invalid copy nor deletes it.
    ///
    /// - Parameter deletes: Whether to delete rather than load the copy.
    /// - Throws: An error if creating the archive directory fails.
    @Test(arguments: [false, true])
    func canceledAccessPreservesCopy(deletes: Bool) async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        let fileURL = directoryURL.appending(path: "Settings/Invalid.cotsettings", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
        let task = Task {
            if deletes {
                try await manager.delete(fileURL)
            } else {
                _ = try await manager.load(from: fileURL)
            }
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    
    /// Verifies that unavailable metadata does not hide other archives or apply their settings.
    ///
    /// - Throws: An error if preparing or observing the archives fails.
    @Test func observesMetadataWithoutApplyingSettings() async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let manager = CloudSettingsManager(containerURL: directoryURL)
        var document = try PortableSettingsDocument(including: [])
        document.info.date = Date(timeIntervalSince1970: 1_700_000_000)
        document.info.sourceID = UUID()
        document.defaults = [DefaultKeys.windowWidth.rawValue: .double(1234)]
        let windowWidth = UserDefaults.standard[.windowWidth]
        let fileURL = try self.writeArchive(document, in: directoryURL)
        try FileManager.default.removeItem(at: fileURL.appending(component: "Defaults.plist"))
        let brokenURL = fileURL.deletingLastPathComponent().appending(component: "Broken", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        try FileManager.default.createDirectory(at: brokenURL, withIntermediateDirectories: true)
        try Data("invalid".utf8).write(to: brokenURL.appending(component: PortableSettingsDocument.Info.filename))
        var archives: [CloudSettingsManager.Archive] = []
        
        for try await snapshot in manager.archives() {
            archives = snapshot
        }
        
        #expect(Set(archives.map(\.url)) == Set([fileURL, brokenURL]))
        #expect(archives.first { $0.url == fileURL }?.info == document.info)
        #expect(archives.first { $0.url == brokenURL }?.info == nil)
        #expect(UserDefaults.standard[.windowWidth] == windowWidth)
    }
    
    
    /// Verifies that a query receives early initial results and reports additions and removals until cancellation.
    ///
    /// - Throws: An error if waiting for query results fails.
    @Test func queryReportsArchiveUpdates() async throws {
        
        let directoryURL = URL(filePath: "/Settings", directoryHint: .isDirectory)
        let firstURL = directoryURL.appending(component: "First", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        let secondURL = directoryURL.appending(component: "Second", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        let unrelatedURL = directoryURL.appending(component: "Other.txt")
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
    /// - Throws: An error if waiting for the query fails.
    @Test(arguments: [false, true])
    func canceledQueryStops(cancelsBeforeStarting: Bool) async throws {
        
        let directoryURL = URL(filePath: "/Settings", directoryHint: .isDirectory)
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
        let presenter = SuspendedFilePresenter(fileURL: fileURL.appending(component: PortableSettingsDocument.Info.filename))
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
    
    
    /// Verifies that an unsuccessful query start is reported and cleaned up.
    @Test func failedQueryStartStopsObservation() async {
        
        let directoryURL = URL(filePath: "/Settings", directoryHint: .isDirectory)
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
