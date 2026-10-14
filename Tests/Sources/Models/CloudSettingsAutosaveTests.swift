//
//  CloudSettingsAutosaveTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-14.
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

// The observer integration tests post notifications from shared setting managers.
@MainActor @Suite(.serialized) struct CloudSettingsAutosaveTests {

    /// Verifies exposing localized descriptions through Foundation's error bridging.
    ///
    /// - Parameter error: The settings storage error to describe.
    @Test(arguments: [CloudSettingsError.iCloudUnavailable, .metadataQueryFailed, .invalidArchiveURL])
    func localizedErrorDescriptions(error: CloudSettingsError) {
        
        #expect((error as NSError).localizedDescription == error.errorDescription)
        #expect(error.errorDescription?.isEmpty == false)
    }
    
    /// Verifies enabling, disabling, and resuming automatic saving without removing the previous copy.
    ///
    /// - Throws: An error if preparing or reading the archives fails.
    @Test func followsEnabledSetting() async throws {
        
        try await self.withManager(enabled: false) { manager, defaults, fileURL in
            await manager.flush()
            #expect(!FileManager.default.fileExists(atPath: fileURL.path))
            defaults[.syncsSettings] = true
            let saved = await Task.waitFor { FileManager.default.fileExists(atPath: fileURL.path) && !manager.hasPendingSave }
            try #require(saved)
            var original = try PortableSettingsDocument(contentsOf: fileURL)
            original.info.date = Date(timeIntervalSince1970: 0)
            try original.fileWrapper().write(to: fileURL, options: .atomic, originalContentsURL: fileURL)
            defaults[.syncsSettings] = false
            defaults[.windowWidth] = 800
            await manager.flush()
            #expect(try PortableSettingsDocument(contentsOf: fileURL).info == original.info)
            defaults[.syncsSettings] = true
            await manager.flush()
            #expect(try PortableSettingsDocument(contentsOf: fileURL).defaults[DefaultKeys.windowWidth.rawValue] == .double(800))
            #expect(manager.error == nil)
        }
    }
    
    
    /// Verifies filtering unrelated defaults, debouncing portable defaults, and exporting saved search scopes.
    ///
    /// - Throws: An error if preparing or reading the archives fails.
    @Test func observesPortableDefaults() async throws {
        
        try await self.withManager { manager, defaults, fileURL in
            await manager.flush()
            var original = try PortableSettingsDocument(contentsOf: fileURL)
            original.info.date = Date(timeIntervalSince1970: 0)
            try original.fileWrapper().write(to: fileURL, options: .atomic, originalContentsURL: fileURL)
            defaults[.lastVersion] = "999999"
            await manager.flush()
            #expect(try PortableSettingsDocument(contentsOf: fileURL).info == original.info)
            defaults[.windowWidth] = 700
            let scheduled = await Task.waitFor { manager.hasPendingSave }
            try #require(scheduled)
            #expect(try PortableSettingsDocument(contentsOf: fileURL).defaults[DefaultKeys.windowWidth.rawValue] == .double(640))
            for width in 701...800 {
                defaults[.windowWidth] = Double(width)
            }
            defaults[.folderFindSavedScopes] = ["Sample": Data("scope".utf8)]
            let saved = await Task.waitFor {
                (try? PortableSettingsDocument(contentsOf: fileURL).defaults[DefaultKeys.windowWidth.rawValue]) == .double(800) && !manager.hasPendingSave
            }
            try #require(saved)
            let document = try PortableSettingsDocument(contentsOf: fileURL)
            #expect(document.defaults[DefaultKeys.folderFindSavedScopes.rawValue] == .dictionary(["Sample": .data(Data("scope".utf8))]))
            #expect(document.defaults[DefaultKeys.lastVersion.rawValue] == nil)
            #expect(document.defaults[DefaultKeys.syncsSettings.rawValue] == nil)
        }
    }
    
    
    /// Verifies observing each setting manager's updates while preserving the archive contents.
    ///
    /// - Parameter kind: The setting manager notification to post.
    /// - Throws: An error if preparing or reading the archives fails.
    @Test(arguments: ["theme", "syntax", "replacement", "keyBindings"])
    func observesSettingManagers(kind: String) async throws {
        
        try await self.withManager { manager, _, fileURL in
            await manager.flush()
            var original = try PortableSettingsDocument(contentsOf: fileURL)
            original.info.date = Date(timeIntervalSince1970: 0)
            try original.fileWrapper().write(to: fileURL, options: .atomic, originalContentsURL: fileURL)
            let center = NotificationCenter.default
            let change = SettingChange.updated(from: "Sample", to: "Sample")
            switch kind {
                case "theme": center.post(DidManagerUpdateSettingMessage(change: change), subject: ThemeManager.shared)
                case "syntax": center.post(DidManagerUpdateSettingMessage(change: change), subject: SyntaxManager.shared)
                case "replacement": center.post(DidManagerUpdateSettingMessage(change: change), subject: ReplacementManager.shared)
                default: center.post(KeyBindingManager.DidUpdateSettingsMessage(), subject: KeyBindingManager.shared)
            }
            #expect(manager.hasPendingSave)
            await manager.flush()
            let saved = try PortableSettingsDocument(contentsOf: fileURL)
            #expect(saved.info.date > original.info.date)
            #expect(saved.defaults == original.defaults)
        }
    }
    
    
    /// Verifies retaining the previous copy after failure and clearing the error after a successful retry.
    ///
    /// - Throws: An error if preparing or reading the archives fails.
    @Test func retriesAfterWriteFailure() async throws {
        
        try await self.withManager { manager, defaults, fileURL in
            await manager.flush()
            let original = try PortableSettingsDocument(contentsOf: fileURL)
            let directoryURL = fileURL.deletingLastPathComponent()
            defer { try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path) }
            try FileManager.default.setAttributes([.posixPermissions: 0o500], ofItemAtPath: directoryURL.path)
            defaults[.windowWidth] = 800
            await manager.flush()
            #expect(manager.error.map { $0 is CocoaError } == true)
            #expect(manager.error?.localizedDescription != nil)
            #expect(!manager.hasPendingSave)
            let unchanged = try PortableSettingsDocument(contentsOf: fileURL)
            #expect(unchanged.info == original.info)
            #expect(unchanged.defaults == original.defaults)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path)
            defaults[.windowWidth] = 900
            await manager.flush()
            #expect(manager.error == nil)
            #expect(try PortableSettingsDocument(contentsOf: fileURL).defaults[DefaultKeys.windowWidth.rawValue] == .double(900))
        }
    }
    
    
    /// Verifies that disabling a pending write preserves the previous archive without reporting cancellation.
    ///
    /// - Throws: An error if preparing the presenter, waiting for cancellation, or reading the archive fails.
    @Test func disablingKeepsPreviousArchive() async throws {
        
        try await self.withManager { manager, defaults, fileURL in
            await manager.flush()
            let original = try PortableSettingsDocument(contentsOf: fileURL)
            let presenter = SuspendedSettingsPresenter(fileURL: fileURL)
            NSFileCoordinator.addFilePresenter(presenter)
            defer {
                presenter.resume()
                NSFileCoordinator.removeFilePresenter(presenter)
            }
            defaults[.windowWidth] = 800
            let saving = Task { await manager.flush() }
            try #require(await Task.waitFor { presenter.isWaiting })
            defaults[.syncsSettings] = false
            await manager.flush()
            await saving.value
            
            #expect(!manager.hasPendingSave)
            #expect(manager.error == nil)
            let saved = try PortableSettingsDocument(contentsOf: fileURL)
            #expect(saved.info == original.info)
            #expect(saved.defaults == original.defaults)
        }
    }
    
    
    /// Verifies flushing a defaults change even before its asynchronous notification is delivered.
    ///
    /// - Throws: An error if preparing or reading the archives fails.
    @Test func flushesLatestSettings() async throws {
        
        try await self.withManager { manager, defaults, fileURL in
            await manager.flush()
            defaults[.windowWidth] = 800
            await manager.flush()
            let saved = try PortableSettingsDocument(contentsOf: fileURL)
            #expect(!manager.hasPendingSave)
            #expect(saved.defaults[DefaultKeys.windowWidth.rawValue] == .double(800))
        }
    }
    
    
    /// Verifies that termination stops waiting for coordinated access and preserves the previous archive.
    ///
    /// - Throws: An error if preparing the presenter, waiting for termination, or reading the archive fails.
    @Test(.timeLimit(.minutes(1))) func terminationDoesNotWaitForFileAccess() async throws {
        
        try await self.withManager { manager, defaults, fileURL in
            await manager.flush()
            let original = try PortableSettingsDocument(contentsOf: fileURL)
            let presenter = SuspendedSettingsPresenter(fileURL: fileURL)
            NSFileCoordinator.addFilePresenter(presenter)
            defer {
                presenter.resume()
                NSFileCoordinator.removeFilePresenter(presenter)
            }
            defaults[.windowWidth] = 800
            let saving = Task { await manager.flush(timeout: .seconds(60)) }
            defer { saving.cancel() }
            try #require(await Task.waitFor { presenter.isWaiting })
            
            var completed = false
            let termination = Task {
                await manager.flush(timeout: .milliseconds(100))
                completed = true
            }
            defer { termination.cancel() }
            try #require(await Task.waitFor { completed })
            #expect(presenter.isWaiting)
            try #require(await Task.waitFor { !manager.hasPendingSave })
            await saving.value
            await termination.value
            
            #expect(manager.error == nil)
            #expect(defaults[.syncsSettings])
            let saved = try PortableSettingsDocument(contentsOf: fileURL)
            #expect(saved.info == original.info)
            #expect(saved.defaults == original.defaults)
        }
    }
    
    
    /// Verifies serial saving when settings change while the previous snapshot is waiting for coordinated access.
    ///
    /// - Parameter restarts: Whether to stop and restart automatic saving while the first write is suspended.
    /// - Throws: An error if preparing or reading the archives fails.
    @Test(arguments: [false, true])
    func savesChangesReceivedDuringSaving(restarts: Bool) async throws {
        
        try await self.withManager { manager, defaults, fileURL in
            await manager.flush()
            let presenter = SuspendedSettingsPresenter(fileURL: fileURL)
            NSFileCoordinator.addFilePresenter(presenter)
            defer {
                presenter.resume()
                NSFileCoordinator.removeFilePresenter(presenter)
            }
            defaults[.windowWidth] = 800
            let saving = Task { await manager.flush() }
            let waiting = await Task.waitFor { presenter.isWaiting }
            try #require(waiting)
            if restarts {
                defaults[.syncsSettings] = false
                await manager.flush()
                defaults[.syncsSettings] = true
                manager.start()
            }
            defaults[.windowWidth] = 900
            let queued = restarts ? Task { await manager.flush() } : nil
            NotificationCenter.default.post(KeyBindingManager.DidUpdateSettingsMessage(), subject: KeyBindingManager.shared)
            await Task.yield()
            presenter.resume()
            await saving.value
            await queued?.value
            #expect(!manager.hasPendingSave)
            #expect(try PortableSettingsDocument(contentsOf: fileURL).defaults[DefaultKeys.windowWidth.rawValue] == .double(900))
        }
    }
    
    
    /// Runs a test with an isolated defaults store and a local settings container, then drains canceled writes.
    ///
    /// - Parameters:
    ///   - enabled: Whether automatic saving is enabled before the manager starts.
    ///   - body: The test using the manager, its defaults, and the expected archive URL.
    /// - Throws: An error if preparing the environment or running the test fails.
    private func withManager(enabled: Bool = true, body: (CloudSettingsManager, UserDefaults, URL) async throws -> Void) async throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let suiteName = "CloudSettingsAutosaveTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.register(defaults: Dictionary(uniqueKeysWithValues: DefaultSettings.defaults.compactMap { key, value in
            value.map { (key.rawValue, $0) }
        }))
        defaults[.syncsSettings] = enabled
        defaults[.windowWidth] = 640
        let hostUUID = UUID()
        let fileURL = directoryURL.appending(path: "Settings/\(hostUUID.uuidString)-tester", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        let manager = CloudSettingsManager(containerURL: directoryURL, defaults: defaults, hostUUID: hostUUID, userName: "tester")
        manager.start()
        var failure: (any Error)?
        do {
            try await body(manager, defaults, fileURL)
        } catch {
            failure = error
        }
        defaults[.syncsSettings] = false
        await manager.flush()
        #expect(!manager.hasPendingSave)
        if let failure { throw failure }
    }
}


/// A presenter that suspends the first writer until the test allows it to proceed.
private final class SuspendedSettingsPresenter: NSObject, NSFilePresenter {
    
    let presentedItemURL: URL?
    let presentedItemOperationQueue = OperationQueue()
    private let state = Mutex<(writer: (@Sendable ((@Sendable () -> Void)?) -> Void)?, resumed: Bool)>((nil, false))
    
    /// Whether a coordinated write is currently suspended.
    var isWaiting: Bool {
        
        self.state.withLock { $0.writer != nil }
    }
    
    /// Creates a presenter for the archive being saved.
    ///
    /// - Parameter fileURL: The archive URL to coordinate.
    init(fileURL: URL) {
        
        self.presentedItemURL = fileURL
        super.init()
    }
    
    
    /// Holds the first coordinated writer until the test resumes it.
    ///
    /// - Parameter writer: The accessor to invoke when the presented item can be written.
    func relinquishPresentedItem(toWriter writer: @escaping @Sendable ((@Sendable () -> Void)?) -> Void) {
        
        let resumed = self.state.withLock {
            guard !$0.resumed else { return true }
            $0.writer = writer
            return false
        }
        if resumed { writer(nil) }
    }
    
    
    /// Allows the suspended writer and all subsequent writers to proceed.
    func resume() {
        
        let writer = self.state.withLock {
            let writer = $0.writer
            $0.writer = nil
            $0.resumed = true
            return writer
        }
        writer?(nil)
    }
}
