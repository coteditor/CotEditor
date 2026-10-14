//
//  CloudSettingsManager.swift
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
import Combine
import Observation
import OSLog
import Synchronization
import UniformTypeIdentifiers
import Defaults

enum CloudSettingsError: LocalizedError {
    
    case iCloudUnavailable
    case metadataQueryFailed
    case invalidArchiveURL
    
    
    var errorDescription: String? {
        
        switch self {
            case .iCloudUnavailable:
                String(localized: "CloudSettingsError.iCloudUnavailable.description",
                       defaultValue: "iCloud Drive is not available.",
                       comment: "Refer to the same expression by Apple.")
            case .metadataQueryFailed:
                String(localized: "CloudSettingsError.metadataQueryFailed.description",
                       defaultValue: "Couldn’t find settings copies in iCloud.")
            case .invalidArchiveURL:
                String(localized: "CloudSettingsError.invalidArchiveURL.description",
                       defaultValue: "Couldn’t access the selected settings copy.")
        }
    }
}


@MainActor @Observable final class CloudSettingsManager {
    
    struct Archive: Equatable, Sendable, Identifiable {
        
        var url: URL
        var info: PortableSettingsDocument.Info?
        
        var id: URL  { self.url }
    }
    
    
    // MARK: Public Properties
    
    static let shared = CloudSettingsManager()
    
    private(set) var error: any Error?
    
    /// Whether a settings archive is waiting to be saved or is being written.
    var hasPendingSave: Bool  { self.saveDebouncer.isScheduled || self.saveRequested || self.saveTask != nil }
    
    
    // MARK: Private Properties
    
    private nonisolated static let ubiquityContainerIdentifier = "iCloud.com.coteditor.CotEditor"
    
    private let containerURL: URL?
    private let defaults: UserDefaults
    private var hostUUID: UUID?
    private let userName: String
    private let fileQueue = OperationQueue()
    
    private var enabledObserver: AnyCancellable?
    private var changeObservers: [NotificationCenter.ObservationToken] = []
    private var lastDefaults: [String: PropertyListValue] = [:]
    private var saveTask: Task<Void, Never>?
    private var saveRequested = false
    private var savingActivity: any NSObjectProtocol?
    
    @ObservationIgnored private lazy var saveDebouncer = Debouncer(delay: .seconds(1)) { [weak self] in
        self?.saveIfNeeded()
    }
    
    
    // MARK: Lifecycle
    
    /// Creates a manager for an iCloud container or a local container used for testing.
    ///
    /// - Parameters:
    ///   - containerURL: A local container URL, or `nil` to use CotEditor's iCloud container.
    ///   - defaults: The user defaults store to observe and export.
    ///   - hostUUID: A host UUID used for testing, or `nil` to obtain and cache the current Mac's UUID.
    ///   - userName: The user name used to distinguish archives on the same Mac.
    init(containerURL: URL? = nil, defaults: UserDefaults = .standard, hostUUID: UUID? = nil, userName: String = NSUserName()) {
        
        self.containerURL = containerURL
        self.defaults = defaults
        self.hostUUID = hostUUID
        self.userName = userName
        
        // -> NSFileCoordinator's asynchronous API requires an OperationQueue.
        //    The synchronous API can block Swift concurrency threads while waiting for iCloud.
        self.fileQueue.maxConcurrentOperationCount = 1
        self.fileQueue.qualityOfService = .utility
    }
    
    
    isolated deinit {
        
        self.saveTask?.cancel()
        if let savingActivity {
            ProcessInfo.processInfo.endActivity(savingActivity)
        }
    }
    
    
    // MARK: Public Methods
    
    /// Starts observing whether automatic saving is enabled and changes to portable settings.
    func start() {
        
        guard self.enabledObserver == nil else { return }
        
        self.enabledObserver = self.defaults.publisher(for: .syncsSettings)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateObservation() }
        self.updateObservation()
    }
    
    
    /// Saves any pending changes without waiting for the debounce delay.
    ///
    /// Saving errors are retained in `error`.
    ///
    /// - Parameter timeout: The duration before canceling pending writes.
    func flush(timeout: Duration = .seconds(5)) async {
        
        guard self.enabledObserver != nil else { return }
        
        self.updateObservation()
        self.defaultsDidChange()
        self.saveDebouncer.fire()
        
        let timeoutTask = Task {
            try await Task.sleep(for: timeout)
            self.saveDebouncer.cancel()
            self.saveRequested = false
            self.saveTask?.cancel()
        }
        defer { timeoutTask.cancel() }
        
        while let saveTask = self.saveTask {
            await saveTask.value
            guard !saveTask.isCancelled else { break }
            self.saveDebouncer.fire()
        }
    }
    
    
    /// Observes the available archives and reads their metadata without applying settings.
    ///
    /// - Note: Canceling iteration stops the underlying observation.
    /// - Returns: A stream of the latest archive lists, including metadata as it becomes available.
    func archives() -> AsyncThrowingStream<[Archive], any Error> {
        
        let (stream, continuation) = AsyncThrowingStream<[Archive], any Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let task = Task {
            do {
                var archives: [URL: Archive] = [:]
                try await self.observeArchiveURLs { urls in
                    archives = Dictionary(uniqueKeysWithValues: urls.map { ($0, archives[$0] ?? Archive(url: $0)) })
                    continuation.yield(Array(archives.values))
                    
                    try await withThrowingTaskGroup(of: Archive.self) { group in
                        for url in urls {
                            _ = group.addTaskUnlessCancelled {
                                let infoURL = url.appending(component: PortableSettingsDocument.Info.filename)
                                let info = try? await self.coordinate(intent: .readingIntent(with: infoURL, options: .withoutChanges),
                                                                      body: PortableSettingsDocument.Info.init(contentsOf:))
                                return Archive(url: url, info: info)
                            }
                        }
                        for try await archive in group {
                            try Task.checkCancellation()
                            
                            guard let info = archive.info, info != archives[archive.url]?.info else { continue }
                            
                            archives[archive.url] = archive
                            continuation.yield(Array(archives.values))
                        }
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in task.cancel() }
        
        return stream
    }
    
    
    /// Downloads and reads a settings archive without applying it.
    ///
    /// - Parameter fileURL: An archive URL received by `archives()`.
    /// - Returns: The settings snapshot read from the archive.
    /// - Throws: An error if the URL is outside the settings directory, reading fails, or the operation is canceled.
    func load(from fileURL: URL) async throws -> PortableSettingsDocument {
        
        let directoryURL = try await Self.settingsDirectoryURL(containerURL: self.containerURL)
        
        guard Self.isSettingsArchiveURL(fileURL, in: directoryURL) else { throw CloudSettingsError.invalidArchiveURL }
        
        return try await self.coordinate(intent: .readingIntent(with: fileURL, options: .withoutChanges)) { url in
            try PortableSettingsDocument(contentsOf: url)
        }
    }
    
    
    // MARK: Private Methods
    
    /// The current values of the defaults included in settings archives.
    private var portableDefaults: [String: PropertyListValue] {
        
        let keys = DefaultSettings.portableKeys + [.folderFindSavedScopes]
        
        return self.defaults.dictionaryWithValues(forKeys: keys.map(\.rawValue))
            .compactMapValues(PropertyListValue.init)
    }
    
    
    /// Starts or stops observing changes according to the current automatic saving setting.
    private func updateObservation() {
        
        guard self.enabledObserver != nil, self.defaults[.syncsSettings] else {
            self.stopObservingChanges()
            return
        }
        
        guard self.changeObservers.isEmpty else { return }
        
        self.lastDefaults = self.portableDefaults
        let center = NotificationCenter.default
        self.changeObservers = [
            center.addObserver(of: self.defaults, for: .didChange) { [weak self] _ in
                await self?.defaultsDidChange()
            },
            center.addObserver(of: ThemeManager.shared, for: DidManagerUpdateSettingMessage.self) { [weak self] _ in
                self?.scheduleSave()
            },
            center.addObserver(of: SyntaxManager.shared, for: DidManagerUpdateSettingMessage.self) { [weak self] _ in
                self?.scheduleSave()
            },
            center.addObserver(of: ReplacementManager.shared, for: DidManagerUpdateSettingMessage.self) { [weak self] _ in
                self?.scheduleSave()
            },
            center.addObserver(of: KeyBindingManager.shared, for: KeyBindingManager.DidUpdateSettingsMessage.self) { [weak self] _ in
                self?.scheduleSave()
            },
        ]
        self.scheduleSave(immediately: true)
    }
    
    
    /// Removes settings observers and cancels any pending automatic saving.
    private func stopObservingChanges() {
        
        self.changeObservers.removeAll()
        self.saveDebouncer.cancel()
        self.saveRequested = false
        self.saveTask?.cancel()
        self.error = nil
        self.updateSavingActivity()
    }
    
    
    /// Requests a settings archive only when portable user defaults have changed.
    private func defaultsDidChange() {
        
        guard self.defaults[.syncsSettings], !self.changeObservers.isEmpty else { return }
        
        let defaults = self.portableDefaults
        
        guard defaults != self.lastDefaults else { return }
        
        self.lastDefaults = defaults
        self.scheduleSave()
    }
    
    
    /// Requests an archive of the latest settings, optionally bypassing the debounce delay.
    ///
    /// - Parameter immediately: Whether to start saving without waiting for further changes.
    private func scheduleSave(immediately: Bool = false) {
        
        guard
            self.defaults[.syncsSettings],
            !self.changeObservers.isEmpty
        else { return }
        
        if immediately {
            self.saveDebouncer.cancel()
            self.saveIfNeeded()
        } else {
            self.saveDebouncer.schedule()
        }
        self.updateSavingActivity()
    }
    
    
    /// Saves queued settings snapshots serially after their debounce delay has elapsed.
    private func saveIfNeeded() {
        
        guard self.defaults[.syncsSettings] else { return }
        
        self.saveRequested = true
        
        guard self.saveTask == nil else { return }
        
        self.saveTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            
            defer {
                self.saveTask = nil
                self.updateSavingActivity()
                
                // a new request can arrive while a canceled save is finishing
                if self.saveRequested {
                    self.saveIfNeeded()
                }
            }
            
            while self.defaults[.syncsSettings], self.saveRequested, !Task.isCancelled {
                self.saveRequested = false
                self.saveDebouncer.cancel()
                
                do {
                    let document = try PortableSettingsDocument(including: .all, userDefaults: self.defaults)
                    try await self.save(document)
                    self.error = nil
                } catch {
                    guard !Task.isCancelled else { break }
                    
                    self.error = error
                    Logger.app.error("Failed saving settings to iCloud: \(error)")
                }
            }
        }
    }
    
    
    /// Prevents sudden termination while an automatic settings write is pending or in progress.
    private func updateSavingActivity() {
        
        if self.hasPendingSave {
            if self.savingActivity == nil {
                self.savingActivity = ProcessInfo.processInfo.beginActivity(options: .suddenTerminationDisabled, reason: "Saving settings to iCloud")
            }
        } else if let savingActivity {
            ProcessInfo.processInfo.endActivity(savingActivity)
            self.savingActivity = nil
        }
    }
    
    
    /// Finds archive URLs and observes subsequent changes.
    ///
    /// - Parameter action: Receives the current archive URLs.
    /// - Throws: An error if iCloud is unavailable, discovery fails, or observation is canceled.
    private func observeArchiveURLs(_ action: ([URL]) async throws -> Void) async throws {
        
        let directoryURL = try await Self.settingsDirectoryURL(containerURL: self.containerURL)
        
        if self.containerURL != nil {
            let urls = try await { @concurrent () async throws -> [URL] in
                do {
                    return try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
                } catch CocoaError.fileReadNoSuchFile {
                    return []
                }
            }()
            
            try Task.checkCancellation()
            try await action(urls.map(\.standardizedFileURL).filter { Self.isSettingsArchiveURL($0, in: directoryURL) })
            
            return
        }
        
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        query.predicate = NSPredicate(format: "%K LIKE %@", NSMetadataItemFSNameKey, "*.\(UTType.cotSettings.preferredFilenameExtension!)")
        
        try await Self.queryArchiveURLs(using: query, in: directoryURL, action: action)
    }
    
    
    /// Observes archive URLs until the metadata query is canceled.
    ///
    /// - Parameters:
    ///   - query: The configured metadata query.
    ///   - directoryURL: The directory containing settings archives.
    ///   - action: Receives the current archive URLs.
    /// - Throws: An error if the query cannot start, the action fails, or observation is canceled.
    static func queryArchiveURLs(using query: NSMetadataQuery, in directoryURL: URL, action: ([URL]) async throws -> Void) async throws {
        
        // register observers before starting the query and bridge them with AsyncStream
        // -> messages(of:for:) can miss early notifications and leave already canceled tasks waiting.
        let (notifications, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let center = NotificationCenter.default
        let observer = center.addObserver(of: query, for: .didFinishGathering) { _ in
            continuation.yield(())
        }
        let updateObserver = center.addObserver(forName: .NSMetadataQueryDidUpdate, object: query, queue: nil) { _ in
            continuation.yield(())
        }
        
        defer {
            query.stop()
            center.removeObserver(observer)
            center.removeObserver(updateObserver)
            continuation.finish()
        }
        
        guard query.start() else { throw CloudSettingsError.metadataQueryFailed }
        
        for await _ in notifications {
            try Task.checkCancellation()
            
            query.disableUpdates()
            
            let urls = query.results
                .compactMap { ($0 as? NSMetadataItem)?.value(forAttribute: NSMetadataItemURLKey) as? URL }
                .map(\.standardizedFileURL)
                .filter { Self.isSettingsArchiveURL($0, in: directoryURL) }
            
            query.enableUpdates()
            
            try await action(urls)
        }
        try Task.checkCancellation()
    }
    
    
    /// Returns whether a URL identifies a settings archive directly inside the settings directory.
    ///
    /// - Parameters:
    ///   - fileURL: The URL to validate.
    ///   - directoryURL: The settings directory's URL.
    /// - Returns: Whether the URL has the archive extension and belongs directly to the directory.
    private nonisolated static func isSettingsArchiveURL(_ fileURL: URL, in directoryURL: URL) -> Bool {
        
        fileURL.pathExtension == UTType.cotSettings.preferredFilenameExtension &&
        fileURL.deletingLastPathComponent().standardizedFileURL == directoryURL.standardizedFileURL
    }
    
    
    /// Resolves the settings directory in the currently available container.
    ///
    /// - Parameter containerURL: A local container URL, or `nil` to resolve CotEditor's iCloud container.
    /// - Returns: The settings directory's URL.
    /// - Throws: An error if iCloud is unavailable.
    @concurrent private static func settingsDirectoryURL(containerURL: URL?) async throws(CloudSettingsError) -> URL {
        
        guard
            let url = containerURL ?? FileManager.default.url(forUbiquityContainerIdentifier: Self.ubiquityContainerIdentifier)
        else { throw .iCloudUnavailable }
        
        return url.standardizedFileURL.appending(component: "Settings", directoryHint: .isDirectory)
    }
    
    
    /// Returns the source Mac's host UUID.
    ///
    /// - Note: gethostuuid() can block while waiting for the host UUID, so keep it off the main actor.
    ///
    /// - Returns: The UUID identifying the source Mac.
    /// - Throws: A POSIX error if the host UUID cannot be obtained within one second.
    @concurrent private static func sourceID() async throws(POSIXError) -> UUID {
        
        var bytes: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        var timeout = timespec(tv_sec: 1, tv_nsec: 0)
        let result = withUnsafeMutablePointer(to: &bytes) {
            unsafe $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<uuid_t>.size) {
                unsafe gethostuuid($0, &timeout)
            }
        }
        
        guard result == 0 else { throw POSIXError(.init(rawValue: errno)!) }
        
        return UUID(uuid: bytes)
    }
    
    
    /// Saves the supplied settings snapshot as this environment's archive.
    ///
    /// - Parameter document: The complete settings snapshot to save.
    /// - Throws: An error if iCloud is unavailable, encoding or writing fails, or the operation is canceled.
    private func save(_ document: PortableSettingsDocument) async throws {
        
        let sourceID = if let hostUUID {
            hostUUID
        } else {
            try await Self.sourceID()
        }
        self.hostUUID = sourceID
        
        var document = document
        document.info.sourceID = sourceID
        document.info.userName = self.userName
        
        let directoryURL = try await Self.settingsDirectoryURL(containerURL: self.containerURL)
        try await self.coordinate(intent: .writingIntent(with: directoryURL)) { url in
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        
        let fileURL = directoryURL.appending(component: "\(sourceID.uuidString)-\(self.userName)", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        
        try await self.coordinate(intent: .writingIntent(with: fileURL)) { [document] url in
            // specify the original URL to preserve the previous package if writing fails
            try document.fileWrapper().write(to: url, options: [.atomic, .withNameUpdating], originalContentsURL: url)
            
            // -> This archive always represents the latest settings from this Mac.
            for version in NSFileVersion.unresolvedConflictVersionsOfItem(at: url) ?? [] {
                version.isResolved = true
                do {
                    try version.remove()
                } catch {
                    Logger.app.error("Failed deleting a resolved settings conflict version: \(error)")
                }
            }
        }
    }
    
    
    /// Performs file access on the serial file queue while forwarding task cancellation.
    ///
    /// - Parameters:
    ///   - intent: The read or write access to coordinate.
    ///   - body: The file operation using the coordinator's current URL.
    /// - Returns: The result of the file operation.
    /// - Throws: An error if coordination or the operation fails, or the task is canceled.
    private func coordinate<Value: Sendable>(intent: NSFileAccessIntent, body: @escaping @Sendable (URL) throws -> Value) async throws -> Value {
        
        let access = Mutex((coordinator: NSFileCoordinator(), isCancelled: false))
        
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                access.withLock { state in
                    guard !state.isCancelled else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    
                    state.coordinator.coordinate(with: [intent], queue: self.fileQueue) { error in
                        continuation.resume(with: Result {
                            if access.withLock(\.isCancelled) { throw CancellationError() }
                            if let error { throw error }
                            return try body(intent.url)
                        })
                    }
                }
            }
        } onCancel: {
            access.withLock { state in
                state.isCancelled = true
                state.coordinator.cancel()
            }
        }
    }
}
