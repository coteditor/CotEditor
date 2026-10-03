//
//  RMateFileStore.swift
//  RMate
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

public import Foundation

/// Stores local working copies of remote files and their metadata.
public struct RMateFileStore: Sendable {
    
    // MARK: Private Properties
    
    private let directory: URL
    
    
    // MARK: Lifecycle
    
    /// Initializes a store for remote file working copies.
    ///
    /// - Parameter directory: The directory in which to store working copies.
    public init(directory: URL) {
        
        self.directory = directory
    }
    
    
    // MARK: Public Methods
    
    /// Creates a working copy of a remote file.
    ///
    /// - Parameters:
    ///   - data: The file content.
    ///   - metadata: The remote file metadata.
    /// - Returns: The working copy URL.
    /// - Throws: An error if writing the content or metadata failed.
    public func makeBackingFile(data: Data, metadata: RMateFile.Metadata) throws -> URL {
        
        let directory = self.directory.appending(component: UUID().uuidString, directoryHint: .isDirectory)
        
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        
        var name = (metadata.path as NSString).lastPathComponent
        if name.isEmpty || name == "." || name == ".." || name == "/" {
            name = "Untitled.txt"
        }
        
        // keep the content in a subdirectory to avoid filename conflicts with remote.json
        let url = directory.appending(component: "content", directoryHint: .isDirectory).appending(component: name)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(metadata).write(to: directory.appending(component: "remote.json"), options: .atomic)
            try data.write(to: url, options: .atomic)
            
            return url
        } catch {
            try? self.removeBackingFile(at: url)
            throw error
        }
    }
    
    
    /// Returns whether the URL is a remote file working copy.
    ///
    /// - Parameter url: A local document URL.
    /// - Returns: `true` if the URL is in the working copy directory.
    public func isBackingFile(_ url: URL) -> Bool {
        
        self.backingDirectory(for: url) != nil
    }
    
    
    /// Reads the remote file metadata for a working copy.
    ///
    /// - Parameter url: The working copy URL.
    /// - Returns: The file metadata, or `nil` for a local document.
    /// - Throws: An error if reading or decoding the metadata failed.
    public func metadata(for url: URL) throws -> RMateFile.Metadata? {
        
        guard let directory = self.backingDirectory(for: url) else { return nil }
        
        let url = directory.appending(component: "remote.json")
        
        return try JSONDecoder().decode(RMateFile.Metadata.self, from: Data(contentsOf: url))
    }
    
    
    /// Removes a working copy and its metadata, leaving URLs outside the store unchanged.
    ///
    /// - Parameter url: The working copy URL.
    /// - Throws: An error if moving or removing the working copy failed.
    public func removeBackingFile(at url: URL) throws {
        
        guard let directory = self.backingDirectory(for: url) else { return }
        
        let pendingDirectory = self.pendingDeletionDirectory
        try FileManager.default.createDirectory(at: pendingDirectory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        
        let values = try pendingDirectory.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard values.isDirectory == true, values.isSymbolicLink == false else {
            throw CocoaError(.fileWriteFileExists, userInfo: [NSURLErrorKey: pendingDirectory])
        }
        
        // retain the deletion intent if removing the directory is interrupted
        let discardedDirectory = pendingDirectory.appending(component: directory.lastPathComponent, directoryHint: .isDirectory)
        try FileManager.default.moveItem(at: directory, to: discardedDirectory)
        do {
            try FileManager.default.removeItem(at: discardedDirectory)
        } catch CocoaError.fileNoSuchFile {
            // the startup cleanup may have already removed the directory
        }
    }
    
    
    /// Retries removing working copies that were already discarded.
    ///
    /// - Throws: An error if reading the deletion directory or removing a discarded copy failed.
    public func removeDiscardedFiles() throws {
        
        let directory = self.pendingDeletionDirectory
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey]
        let urls: [URL]
        do {
            let values = try directory.resourceValues(forKeys: keys)
            
            guard values.isDirectory == true, values.isSymbolicLink == false else { return }
            
            urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: Array(keys))
            
        } catch CocoaError.fileReadNoSuchFile {
            return
        }
        
        var failure: (any Error)?
        for url in urls where UUID(uuidString: url.lastPathComponent) != nil {
            do {
                let values = try url.resourceValues(forKeys: keys)
                
                guard values.isDirectory == true, values.isSymbolicLink == false else { continue }
                
                try FileManager.default.removeItem(at: url)
                
            } catch CocoaError.fileNoSuchFile, CocoaError.fileReadNoSuchFile {
                // a copy can also be removed when its document closes
                
            } catch {
                failure = failure ?? error
            }
        }
        
        if let failure {
            throw failure
        }
    }
    
    
    // MARK: Private Methods
    
    /// The directory containing working copies that are no longer needed.
    private var pendingDeletionDirectory: URL {
        
        self.directory.appending(component: "Pending Deletion", directoryHint: .isDirectory)
    }
    
    
    /// Returns the directory containing a working copy and its metadata.
    ///
    /// - Parameter url: A local document URL.
    /// - Returns: The working copy directory, or `nil` if the URL does not belong to the store.
    private func backingDirectory(for url: URL) -> URL? {
        
        let directory = url.deletingLastPathComponent().deletingLastPathComponent()
        
        guard directory.deletingLastPathComponent().standardizedFileURL.pathComponents == self.directory.standardizedFileURL.pathComponents else { return nil }
        
        return directory
    }
}
