//
//  RMateConnection.swift
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

import Foundation
import Network

/// A connection to an `rmate` client.
@MainActor final class RMateConnection: RMateFileConnection {
    
    // MARK: Internal Properties
    
    private(set) var isConnected = true
    
    var onClose: (@MainActor (_ connectionIdentifier: ObjectIdentifier) -> Void)?
    
    
    // MARK: Private Properties
    
    private let onOpen: @MainActor (RMateFile, RMateOpenRequest) throws -> Void
    private let onError: @MainActor (any Error) -> Void
    private let connection: NetworkConnection<TCP>
    private var receiveTask: Task<Void, Never>?
    private var sendTasks: [UUID: Task<Void, any Error>] = [:]
    private var parser = RMateParser()
    private var files: [ObjectIdentifier: RMateFile] = [:]
    private var pendingCloseCount = 0
    
    
    // MARK: Lifecycle
    
    /// Initializes a connection to an `rmate` client.
    ///
    /// - Parameters:
    ///   - connection: The accepted TCP connection.
    ///   - onOpen: The handler to open a received file.
    ///   - onError: The handler for receive errors and errors thrown by `onOpen`.
    init(connection: NetworkConnection<TCP>, onOpen: @MainActor @escaping (RMateFile, RMateOpenRequest) throws -> Void, onError: @MainActor @escaping (any Error) -> Void) {
        
        self.connection = connection
        self.onOpen = onOpen
        self.onError = onError
    }
    
    
    isolated deinit {
        
        self.receiveTask?.cancel()
        for task in self.sendTasks.values {
            task.cancel()
        }
    }
    
    
    // MARK: Public Methods
    
    /// Starts receiving requests and sends the `rmate` greeting.
    ///
    /// - Parameter applicationName: The application name sent in the greeting.
    func start(applicationName: String) {
        
        self.receiveTask = Task { [weak self, connection] in
            defer { self?.disconnect() }
            
            do {
                try await connection.send(Data("\(applicationName) rmate 1\n".utf8))
                
                while !Task.isCancelled {
                    let (data, metadata) = try await connection.receive(atLeast: 1, atMost: 64 * 1024)
                    
                    guard let self, self.isConnected else { return }
                    
                    do {
                        for message in try self.parser.append(data) {
                            try self.open(message)
                        }
                    } catch {
                        self.disconnect()
                        
                        switch error {
                            case RMateParser.ParseError.fileTooLarge:
                                self.onError(RMateServer.ReceiveError.fileTooLarge(maximumSize: RMateParser.maximumDataLength))
                            case is RMateParser.ParseError:
                                break
                            default:
                                self.onError(error)
                        }
                        return
                    }
                    
                    if metadata.endOfStream || self.isFinished {
                        return
                    }
                }
            } catch {
                // the deferred disconnect handles connection errors
            }
        }
    }
    
    
    /// Sends the file content to the client.
    ///
    /// - Parameters:
    ///   - data: The file content to send.
    ///   - file: The associated remote file.
    /// - Throws: An error if the connection is lost or the content could not be sent.
    func save(_ data: Data, for file: RMateFile) async throws {
        
        guard self.isConnected else { throw URLError(.networkConnectionLost) }
        
        let message = RMateMessage(command: "save", headers: ["token": file.token], data: data)
        
        do {
            try await self.send(message)
        } catch {
            self.disconnect()
            throw error
        }
        
        // -> rmate does not acknowledge whether the client wrote the received data to disk.
        guard self.isConnected else { throw URLError(.networkConnectionLost) }
    }
    
    
    /// Notifies the client that a file was closed.
    ///
    /// - Parameter file: The file to close.
    func close(_ file: RMateFile) {
        
        guard self.files.removeValue(forKey: ObjectIdentifier(file)) != nil, self.isConnected else { return }
        
        let message = RMateMessage(command: "close", headers: ["token": file.token])
        self.pendingCloseCount += 1
        
        Task {
            defer {
                self.pendingCloseCount -= 1
                if self.isFinished {
                    self.disconnect()
                }
            }
            
            do {
                try await self.send(message)
            } catch {
                self.disconnect()
            }
        }
    }
    
    
    /// Closes the connection and notifies the open files.
    func disconnect() {
        
        guard self.isConnected else { return }
        
        self.isConnected = false
        self.receiveTask?.cancel()
        self.receiveTask = nil
        for task in self.sendTasks.values {
            task.cancel()
        }
        self.sendTasks.removeAll()
        
        for file in self.files.values {
            file.onDisconnect?()
        }
        self.files.removeAll()
        
        self.onClose?(ObjectIdentifier(self))
        self.onClose = nil
    }
    
    
    // MARK: Private Methods
    
    /// Whether all requests are received, all files are closed, and all close notifications are sent.
    private var isFinished: Bool {
        
        self.parser.isFinished && self.files.isEmpty && self.pendingCloseCount == 0
    }
    
    
    /// Sends a message in a task that can be canceled when the connection closes.
    ///
    /// - Parameter message: The message to send.
    /// - Throws: An error if the connection is lost or sending is canceled.
    private func send(_ message: RMateMessage) async throws {
        
        guard self.isConnected else { throw URLError(.networkConnectionLost) }
        
        let id = UUID()
        let task = Task { @concurrent [connection] in try await connection.send(message.encoded()) }
        self.sendTasks[id] = task
        defer { self.sendTasks[id] = nil }
        
        try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }
    
    
    /// Passes a received file to the open handler.
    ///
    /// - Parameter message: The open request.
    /// - Throws: `RMateParser.ParseError` or an error from the open handler.
    private func open(_ message: RMateMessage) throws {
        
        guard
            self.files.count < 64,
            let token = message.headers["token"],
            message.headers["data-on-save"] == "yes"
        else { throw RMateParser.ParseError.invalidMessage }
        
        let metadata = RMateFile.Metadata(displayName: message.headers["display-name"] ?? token,
                                          path: message.headers["real-path"] ?? token)
        let file = RMateFile(metadata: metadata, token: token, connection: self)
        self.files[ObjectIdentifier(file)] = file
        
        try self.onOpen(file, RMateOpenRequest(message: message))
    }
}
