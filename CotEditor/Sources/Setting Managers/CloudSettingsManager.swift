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
import Synchronization
import UniformTypeIdentifiers

enum CloudSettingsError: Error {
    
    case iCloudUnavailable
    case metadataQueryFailed
    case invalidArchiveURL
    case unresolvedConflict
}


@MainActor final class CloudSettingsManager {
    
    // MARK: Public Properties
    
    static let shared = CloudSettingsManager()
    
    
    // MARK: Private Properties
    
    private nonisolated static let ubiquityContainerIdentifier = "iCloud.com.coteditor.CotEditor"
    
    private let containerURL: URL?
    private var hostUUID: UUID?
    private let userName: String
    private let fileQueue = OperationQueue()
    
    
    // MARK: Lifecycle
    
    /// Creates a manager for an iCloud container or a local container used for testing.
    ///
    /// - Parameters:
    ///   - containerURL: A local container URL, or `nil` to use CotEditor's iCloud container.
    ///   - hostUUID: A host UUID used for testing, or `nil` to obtain and cache the current Mac's UUID.
    ///   - userName: The user name used to distinguish archives on the same Mac.
    init(containerURL: URL? = nil, hostUUID: UUID? = nil, userName: String = NSUserName()) {
        
        self.containerURL = containerURL
        self.hostUUID = hostUUID
        self.userName = userName
        
        // -> NSFileCoordinator's asynchronous API requires an OperationQueue.
        //    The synchronous API can block Swift concurrency threads while waiting for iCloud.
        self.fileQueue.maxConcurrentOperationCount = 1
        self.fileQueue.qualityOfService = .utility
    }
    
    
    // MARK: Public Methods
    
    /// Finds settings archives without downloading or applying their contents.
    ///
    /// - Returns: URLs of the settings archives currently discoverable in the container.
    /// - Throws: An error if iCloud is unavailable, discovery fails, or the operation is canceled.
    func archiveURLs() async throws -> [URL] {
        
        let directoryURL = try await Self.settingsDirectoryURL(containerURL: self.containerURL)
        let urls: [URL]
        if self.containerURL != nil {
            urls = try await { @concurrent () async throws -> [URL] in
                do {
                    return try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
                } catch CocoaError.fileReadNoSuchFile {
                    return []
                }
            }()
            
        } else {
            let query = NSMetadataQuery()
            query.searchScopes = [NSMetadataQueryUbiquitousDataScope]
            query.predicate = NSPredicate(format: "%K LIKE %@", NSMetadataItemFSNameKey, "*.\(UTType.cotSettings.preferredFilenameExtension!)")
            
            // register an observer before starting the query and bridge it with AsyncStream
            // -> messages(of:for:) can miss early notifications and leave already canceled tasks waiting.
            let (notifications, continuation) = AsyncStream<Void>.makeStream(bufferingPolicy: .bufferingOldest(1))
            let observer = NotificationCenter.default.addObserver(of: query, for: .didFinishGathering) { _ in
                continuation.yield(())
            }
            defer {
                query.stop()
                NotificationCenter.default.removeObserver(observer)
                continuation.finish()
            }
            guard query.start() else { throw CloudSettingsError.metadataQueryFailed }
            
            for await _ in notifications { break }
            
            query.disableUpdates()
            urls = query.results.compactMap { ($0 as? NSMetadataItem)?.value(forAttribute: NSMetadataItemURLKey) as? URL }
        }
        
        try Task.checkCancellation()
        
        return urls
            .map(\.standardizedFileURL)
            .filter { Self.isSettingsArchiveURL($0, in: directoryURL) }
    }
    
    
    /// Downloads and reads a settings archive without applying it.
    ///
    /// - Parameter fileURL: An archive URL returned by `archiveURLs()`.
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
    /// - Returns: The saved archive's URL.
    /// - Throws: An error if iCloud is unavailable, encoding or writing fails, a conflict exists, or the operation is canceled.
    func save(_ document: PortableSettingsDocument) async throws -> URL {
        
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
        
        return try await self.coordinate(intent: .writingIntent(with: fileURL, options: .forReplacing)) { [document] url in
            guard NSFileVersion.unresolvedConflictVersionsOfItem(at: url)?.isEmpty ?? true else {
                throw CloudSettingsError.unresolvedConflict
            }
            
            // specify the original URL to preserve the previous package if writing fails
            try document.fileWrapper().write(to: url, options: [.atomic, .withNameUpdating], originalContentsURL: url)
            return url
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
