//
//  RMateServer.swift
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
public import Observation

/// A local server for `rmate` clients.
@MainActor @Observable public final class RMateServer {
    
    public enum ListenError: Error {
        
        case invalidPort
        case failed(underlying: any Error)
    }
    
    
    public enum ReceiveError: Error {
        
        case fileTooLarge(maximumSize: Int)
    }
    
    
    // MARK: Public Properties
    
    public nonisolated static let defaultPort = 52698
    
    public private(set) var error: ListenError?
    
    
    // MARK: Private Properties
    
    private let applicationName: String
    private let onOpen: @MainActor (RMateFile, RMateOpenRequest) throws -> Void
    private let onError: @MainActor (any Error) -> Void
    private var listener: NetworkListener<TCP>?
    private var listeningTask: Task<Void, Never>?
    private var connections: [ObjectIdentifier: RMateConnection] = [:]
    
    
    // MARK: Lifecycle
    
    /// Initializes an `rmate` server.
    ///
    /// - Parameters:
    ///   - applicationName: The application name sent in the greeting.
    ///   - onOpen: The handler to open a received file.
    ///   - onError: The handler for receive errors and errors thrown by `onOpen`.
    public init(applicationName: String, onOpen: @MainActor @escaping (RMateFile, RMateOpenRequest) throws -> Void, onError: @MainActor @escaping (any Error) -> Void) {
        
        self.applicationName = applicationName
        self.onOpen = onOpen
        self.onError = onError
    }
    
    
    isolated deinit {
        
        self.listeningTask?.cancel()
        for connection in self.connections.values {
            connection.disconnect()
        }
    }
    
    
    // MARK: Public Methods
    
    /// Starts or stops accepting connections.
    ///
    /// - Note: Existing connections remain open.
    ///
    /// - Parameter port: The loopback TCP port, or `nil` to stop accepting connections.
    public func listen(port: Int?) {
        
        self.listeningTask?.cancel()
        self.listeningTask = nil
        self.listener = nil
        self.error = nil
        
        guard let port else { return }
        
        guard
            let number = UInt16(exactly: port), number > 0,
            let port = NWEndpoint.Port(rawValue: number)
        else {
            self.error = .invalidPort
            return
        }
        
        do {
            let parameters = NWParametersBuilder {
                TCP()
                    .keepalive(idleTimeInSeconds: 30, count: 3, intervalInSeconds: 10)
                    .retransmitConnectionDropTime(30)
            }
            .localEndpoint(.hostPort(host: .ipv4(.loopback), port: port))
            
            let listener = try NetworkListener(using: parameters)
            self.listener = listener
            
            listener.onStateUpdate { [weak self] listener, state in
                guard let self, self.listener === listener else { return }
                
                switch state {
                    case .waiting(let error), .failed(let error):
                        self.error = .failed(underlying: error)
                        self.listeningTask?.cancel()
                    default: break
                }
            }
            
            self.listeningTask = Task { [weak self, listener] in
                do {
                    try await listener.run { [weak self, weak listener] connection in
                        guard
                            let self,
                            self.listener === listener,
                            !Task.isCancelled,
                            self.connections.count < 64
                        else { return }
                        
                        let session = RMateConnection(connection: connection, onOpen: self.onOpen, onError: self.onError)
                        self.connections[ObjectIdentifier(session)] = session
                        session.onClose = { [weak self] id in self?.connections[id] = nil }
                        
                        // keep existing connections alive when the listener is stopped
                        session.start(applicationName: self.applicationName)
                    }
                } catch {
                    guard let self, self.listener === listener, !Task.isCancelled else { return }
                    
                    self.error = .failed(underlying: error)
                }
            }
        } catch {
            self.error = .failed(underlying: error)
        }
    }
}
