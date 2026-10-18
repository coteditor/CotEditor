//
//  RMateServerTests.swift
//  RMateTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-18.
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
import Testing
import RMate

@MainActor @Suite(.serialized, .timeLimit(.minutes(1)))
struct RMateServerTests {
    
    /// Tests saving and closing files through a client connection.
    ///
    /// - Throws: An error if the client could not communicate with the server.
    @Test func saveAndClose() async throws {
        
        let recorder = Recorder()
        let server = recorder.makeServer()
        let port = try availablePort()
        server.listen(port: port)
        
        let client = try await RMateClient.connect(port: port)
        #expect(client.greeting == "Test rmate 1")
        
        try client.send(Self.openRequests(tokens: ["a", "b"]))
        try await waitUntil { recorder.files.count == 2 }
        #expect(recorder.files.map(\.metadata.displayName) == ["a", "b"])
        #expect(recorder.files.allSatisfy { $0.isConnected })
        
        let content = Data("日本語\n".utf8)
        try await recorder.files[0].save(content)
        try await client.wait { $0.responses.count == 1 }
        #expect(client.payload == Data("save\ntoken: a\ndata: 10\n".utf8) + content + Data("\n".utf8))
        
        for file in recorder.files {
            file.close()
        }
        try await client.wait { $0.isClosed }
        #expect(client.responses.count == 3)
        #expect(Set(client.responses.dropFirst()) == [
            RMateClient.Response(command: "close", token: "a"),
            RMateClient.Response(command: "close", token: "b"),
        ])
        #expect(recorder.errors.isEmpty)
        #expect(server.error == nil)
    }
    
    
    /// Tests that a file failed to open is closed without affecting the other files.
    ///
    /// - Throws: An error if the client could not communicate with the server.
    @Test func closeOnlyFailedFile() async throws {
        
        let recorder = Recorder(failingNames: ["b"])
        let server = recorder.makeServer()
        let port = try availablePort()
        server.listen(port: port)
        
        let client = try await RMateClient.connect(port: port)
        try client.send(Self.openRequests(tokens: ["a", "b", "c"]))
        try await waitUntil { recorder.files.count == 2 && recorder.errors.count == 1 }
        try await client.wait { $0.responses.count == 1 }
        #expect(client.responses == [RMateClient.Response(command: "close", token: "b")])
        #expect(recorder.errors.first is TestError)
        
        #expect(recorder.files.map(\.metadata.displayName) == ["a", "c"])
        #expect(recorder.files.allSatisfy { $0.isConnected })
        try await recorder.files[0].save(Data("A".utf8))
        try await recorder.files[1].save(Data("C".utf8))
        try await client.wait { $0.responses.count == 3 }
        #expect(client.responses.dropFirst() == [
            RMateClient.Response(command: "save", token: "a", data: Data("A".utf8)),
            RMateClient.Response(command: "save", token: "c", data: Data("C".utf8)),
        ])
        #expect(!client.isClosed)
        
        for file in recorder.files {
            file.close()
        }
        try await client.wait { $0.isClosed }
        #expect(client.responses.count == 5)
        #expect(recorder.errors.count == 1)
        #expect(server.error == nil)
    }
    
    
    /// Tests that files exceeding the limit are closed and reported only once.
    ///
    /// - Throws: An error if the client could not communicate with the server.
    @Test func tooManyFiles() async throws {
        
        let recorder = Recorder()
        let server = recorder.makeServer()
        let port = try availablePort()
        server.listen(port: port)
        
        let tokens = (0..<66).map { "f\($0)" }
        let client = try await RMateClient.connect(port: port)
        try client.send(Self.openRequests(tokens: tokens))
        try await waitUntil { recorder.files.count == 64 }
        try await client.wait { $0.responses.count == 2 }
        #expect(Set(client.responses) == [
            RMateClient.Response(command: "close", token: "f64"),
            RMateClient.Response(command: "close", token: "f65"),
        ])
        #expect(recorder.files.map(\.metadata.displayName) == Array(tokens.prefix(64)))
        #expect(recorder.files.allSatisfy { $0.isConnected })
        #expect(!client.isClosed)
        
        #expect(recorder.errors.count == 1)
        switch try #require(recorder.errors.first as? RMateServer.ReceiveError) {
            case .tooManyFiles(let maximumCount):
                #expect(maximumCount == 64)
            case let error:
                Issue.record("Unexpected error: \(error)")
        }
        
        for file in recorder.files {
            file.close()
        }
        try await client.wait { $0.isClosed }
        #expect(client.responses.count == 66)
        #expect(Set(client.responses.compactMap(\.token)) == Set(tokens))
        #expect(recorder.errors.count == 1)
        #expect(server.error == nil)
    }
    
    
    /// Tests that the connection closes when the only file failed to open.
    ///
    /// - Throws: An error if the client could not communicate with the server.
    @Test func failOnlyFile() async throws {
        
        let recorder = Recorder(failingNames: ["a"])
        let server = recorder.makeServer()
        let port = try availablePort()
        server.listen(port: port)
        
        let client = try await RMateClient.connect(port: port)
        try client.send(Self.openRequests(tokens: ["a"]))
        try await client.wait { $0.isClosed }
        #expect(client.responses == [RMateClient.Response(command: "close", token: "a")])
        #expect(recorder.files.isEmpty)
        #expect(recorder.errors.count == 1)
        #expect(recorder.errors.first is TestError)
        #expect(server.error == nil)
    }
    
    
    /// Tests restarting listening on the same port while keeping the existing connection.
    ///
    /// - Throws: An error if the client could not communicate with the server.
    @Test func relisten() async throws {
        
        let recorder = Recorder()
        let server = recorder.makeServer()
        let port = try availablePort()
        server.listen(port: port)
        
        let client = try await RMateClient.connect(port: port)
        #expect(client.greeting == "Test rmate 1")
        
        server.listen(port: nil)
        server.listen(port: port)
        #expect(server.error == nil)
        
        let newClient = try await RMateClient.connect(port: port)
        #expect(newClient.greeting == "Test rmate 1")
        #expect(server.error == nil)
        
        // the connection accepted before restarting remains available
        try client.send(Self.openRequests(tokens: ["a"]))
        try await waitUntil { recorder.files.count == 1 }
        #expect(recorder.files.first?.isConnected == true)
    }
    
    
    // MARK: Private Methods
    
    /// Makes `open` requests for empty files followed by the end of the requests.
    ///
    /// - Parameter tokens: The tokens of the files to open.
    /// - Returns: The encoded requests.
    private static func openRequests(tokens: [String]) -> Data {
        
        let requests = tokens.map { "open\ntoken: \($0)\ndata-on-save: yes\ndata: 0\n\n" }
        
        return Data((requests.joined() + ".\n").utf8)
    }
}


// MARK: -

private struct TestError: Error { }


/// Records the files and errors passed to the server handlers.
@MainActor private final class Recorder {
    
    private(set) var files: [RMateFile] = []
    private(set) var errors: [any Error] = []
    
    private let failingNames: Set<String>
    
    
    /// Initializes a recorder.
    ///
    /// - Parameter failingNames: The display names of the files that fail to open.
    init(failingNames: Set<String> = []) {
        
        self.failingNames = failingNames
    }
    
    
    /// Makes a server that reports to the receiver.
    ///
    /// - Returns: A new server.
    func makeServer() -> RMateServer {
        
        RMateServer(applicationName: "Test") { file, _ in
            guard !self.failingNames.contains(file.metadata.displayName) else { throw TestError() }
            
            self.files.append(file)
        } onError: { error in
            self.errors.append(error)
        }
    }
}


/// A minimal `rmate` client using a loopback POSIX socket.
private final class RMateClient {
    
    struct Response: Hashable {
        
        var command: String
        var token: String?
        var data: Data?
    }
    
    
    // MARK: Internal Properties
    
    private(set) var received = Data()
    private(set) var isClosed = false
    
    
    // MARK: Private Properties
    
    private let fileDescriptor: Int32
    
    
    // MARK: Lifecycle
    
    /// Connects to the server and waits for the greeting.
    ///
    /// Connection attempts are repeated until the server sends the greeting.
    ///
    /// - Parameter port: The loopback TCP port.
    /// - Returns: A connected client.
    /// - Throws: `TimeoutError` if the server does not accept the connection in time.
    static func connect(port: Int) async throws -> RMateClient {
        
        var client: RMateClient?
        try await waitUntil {
            if client == nil {
                client = RMateClient(port: port)
            }
            guard let current = client else { return false }
            
            try current.receive()
            if current.isClosed {
                client = nil
            }
            return current.greeting != nil
        }
        
        return try #require(client)
    }
    
    
    /// Opens a connection to a loopback port.
    ///
    /// - Parameter port: The loopback TCP port.
    private init?(port: Int) {
        
        let fileDescriptor = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        
        guard fileDescriptor >= 0 else { return nil }
        
        var noSigPipe: Int32 = 1
        _ = unsafe setsockopt(fileDescriptor, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int32>.size))
        
        var address = sockaddr_in(loopbackPort: port)
        let result = withUnsafePointer(to: &address) {
            unsafe $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                unsafe Darwin.connect(fileDescriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        guard result == 0 else {
            Darwin.close(fileDescriptor)
            return nil
        }
        
        self.fileDescriptor = fileDescriptor
    }
    
    
    deinit {
        Darwin.close(self.fileDescriptor)
    }
    
    
    // MARK: Internal Methods
    
    /// The greeting line without its line terminator, or `nil` if not received yet.
    var greeting: String? {
        
        guard let newline = self.received.firstIndex(of: 0x0A) else { return nil }
        
        return String(decoding: self.received[..<newline], as: UTF8.self)
    }
    
    
    /// The data received after the greeting.
    var payload: Data {
        
        guard let newline = self.received.firstIndex(of: 0x0A) else { return Data() }
        
        return Data(self.received[(newline + 1)...])
    }
    
    
    /// The complete responses received after the greeting.
    var responses: [Response] {
        
        let payload = self.payload
        var index = payload.startIndex
        var responses: [Response] = []
        
        /// Reads a line from the current position.
        ///
        /// - Returns: The line without its terminator, or `nil` if the line is incomplete.
        func readLine() -> String? {
            
            guard let newline = payload[index...].firstIndex(of: 0x0A) else { return nil }
            
            defer { index = newline + 1 }
            return String(decoding: payload[index..<newline], as: UTF8.self)
        }
        
        parsing: while let command = readLine() {
            var response = Response(command: command)
            
            while true {
                guard let line = readLine() else { break parsing }
                
                if line.isEmpty { break }
                
                if line.hasPrefix("token: ") {
                    response.token = String(line.dropFirst("token: ".count))
                    
                } else if line.hasPrefix("data: "), let length = Int(line.dropFirst("data: ".count)) {
                    // data is followed by a line terminator
                    guard payload.endIndex - index > length else { break parsing }
                    
                    response.data = Data(payload[index..<(index + length)])
                    index += length + 1
                    break
                }
            }
            responses.append(response)
        }
        
        return responses
    }
    
    
    /// Sends data to the server.
    ///
    /// - Parameter data: The data to send.
    /// - Throws: `POSIXError` if sending failed.
    func send(_ data: Data) throws {
        
        var offset = 0
        while offset < data.count {
            let count = unsafe data[offset...].withUnsafeBytes {
                unsafe Darwin.send(self.fileDescriptor, $0.baseAddress, $0.count, 0)
            }
            
            guard count >= 0 else { throw POSIXError.current }
            
            offset += count
        }
    }
    
    
    /// Waits until the received data satisfies the condition.
    ///
    /// - Parameter condition: The condition to wait for.
    /// - Throws: `POSIXError` if receiving failed, or `TimeoutError` if the condition is not satisfied in time.
    func wait(until condition: (RMateClient) -> Bool) async throws {
        
        try await waitUntil {
            try self.receive()
            return condition(self)
        }
    }
    
    
    // MARK: Private Methods
    
    /// Reads all available data without blocking.
    ///
    /// - Throws: `POSIXError` if receiving failed.
    private func receive() throws {
        
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)
        
        while !self.isClosed {
            let count = buffer.withUnsafeMutableBytes {
                unsafe Darwin.recv(self.fileDescriptor, $0.baseAddress, $0.count, MSG_DONTWAIT)
            }
            
            switch count {
                case 0:
                    self.isClosed = true
                case 1...:
                    self.received.append(contentsOf: buffer[..<count])
                case _ where errno == EAGAIN:
                    return
                default:
                    throw POSIXError.current
            }
        }
    }
}


// MARK: -

private struct TimeoutError: Error { }


/// Polls the condition at a short interval until it is satisfied.
///
/// - Parameters:
///   - timeout: The maximum duration to wait.
///   - condition: The condition to wait for.
/// - Throws: `TimeoutError` if the condition is not satisfied in time, or an error thrown by the condition.
private func waitUntil(timeout: Duration = .seconds(10), _ condition: () throws -> Bool) async throws {
    
    let deadline = ContinuousClock.now + timeout
    
    while try !condition() {
        guard ContinuousClock.now < deadline else { throw TimeoutError() }
        
        try await Task.sleep(for: .milliseconds(10))
    }
}


/// Finds an available loopback TCP port.
///
/// - Returns: The port number.
/// - Throws: `POSIXError` if no port could be assigned.
private func availablePort() throws -> Int {
    
    let fileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
    
    guard fileDescriptor >= 0 else { throw POSIXError.current }
    
    defer { close(fileDescriptor) }
    
    var address = sockaddr_in(loopbackPort: 0)
    var length = socklen_t(MemoryLayout<sockaddr_in>.size)
    try withUnsafeMutablePointer(to: &address) {
        try unsafe $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            guard
                unsafe bind(fileDescriptor, $0, length) == 0,
                unsafe getsockname(fileDescriptor, $0, &length) == 0
            else { throw POSIXError.current }
        }
    }
    
    return Int(UInt16(bigEndian: address.sin_port))
}


private extension sockaddr_in {
    
    /// Initializes an IPv4 loopback address.
    ///
    /// - Parameter port: The TCP port, or `0` to let the system assign one.
    init(loopbackPort port: Int) {
        
        self.init()
        self.sin_len = UInt8(MemoryLayout<Self>.size)
        self.sin_family = sa_family_t(AF_INET)
        self.sin_port = UInt16(port).bigEndian
        self.sin_addr = in_addr(s_addr: UInt32(0x7F00_0001).bigEndian)
    }
}


private extension POSIXError {
    
    /// The error for the current `errno`.
    static var current: POSIXError {
        
        POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }
}
