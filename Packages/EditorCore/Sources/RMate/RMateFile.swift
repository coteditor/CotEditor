//
//  RMateFile.swift
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

/// A connection that saves and closes remote files.
@MainActor protocol RMateFileConnection: AnyObject {
    
    var isConnected: Bool { get }
    
    
    /// Sends the file content to the client.
    ///
    /// - Parameters:
    ///   - data: The file content to send.
    ///   - file: The remote file to update.
    /// - Throws: An error if the content could not be sent.
    func save(_ data: Data, for file: RMateFile) async throws
    
    
    /// Notifies the client that a file was closed.
    ///
    /// - Parameter file: The file to close.
    func close(_ file: RMateFile)
}


/// A file opened by an `rmate` client.
@MainActor public final class RMateFile {
    
    public struct Metadata: Codable, Sendable {
        
        public var displayName: String
        public var path: String
        
        
        /// Initializes file metadata.
        ///
        /// - Parameters:
        ///   - displayName: The name shown by the editor.
        ///   - path: The remote file path.
        public init(displayName: String, path: String) {
            
            self.displayName = displayName
            self.path = path
        }
    }
    
    
    // MARK: Public Properties
    
    public let metadata: Metadata
    
    /// The handler called when the connection is lost.
    public var onDisconnect: (@MainActor () -> Void)?
    
    
    // MARK: Internal Properties
    
    let token: String
    
    
    // MARK: Private Properties
    
    private weak var connection: (any RMateFileConnection)?
    
    
    // MARK: Lifecycle
    
    /// Initializes a disconnected file from stored metadata.
    ///
    /// - Parameter metadata: The stored document name and remote path.
    public convenience init(metadata: Metadata) {
        
        self.init(metadata: metadata, token: "", connection: nil)
    }
    
    
    /// Initializes a remote file.
    ///
    /// - Parameters:
    ///   - metadata: The file metadata.
    ///   - token: The file identifier used by the client.
    ///   - connection: The client connection, or `nil` if disconnected.
    init(metadata: Metadata, token: String = "", connection: (any RMateFileConnection)?) {
        
        self.metadata = metadata
        self.token = token
        self.connection = connection
    }
    
    
    // MARK: Public Methods
    
    /// Whether the client is connected.
    public var isConnected: Bool {
        
        self.connection?.isConnected == true
    }
    
    
    /// Sends the file content to the client.
    ///
    /// - Parameter data: The file content to send.
    /// - Throws: An error if the connection is lost or the content could not be sent.
    public func save(_ data: Data) async throws {
        
        guard let connection else { throw URLError(.networkConnectionLost) }
        
        try await connection.save(data, for: self)
    }
    
    
    /// Closes the file and notifies the client.
    ///
    /// - Note: This does not call `onDisconnect`.
    public func close() {
        
        self.connection?.close(self)
        self.connection = nil
    }
}
