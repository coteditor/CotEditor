//
//  UserUnixTask.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2026 1024jp
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

actor UserUnixTask {
    
    // MARK: Private Types
    
    private enum State: Equatable {
        
        case ready
        case executing
        case finished
    }
    
    private struct InputState: Sendable {
        
        var offset: Data.Index = 0
        var isFinished = false
    }
    
    
    // MARK: Private Properties
    
    /// Chunk size for piping input; matches a typical macOS pipe buffer.
    private static let inputChunkSize = 64 * 1024
    
    private let task: NSUserUnixTask
    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()
    private var outputBuffer: AsyncStream<Data>?
    private var errorBuffer: AsyncStream<Data>?
    private var state: State = .ready
    private var hasInput = false
    
    
    // MARK: Public Methods
    
    /// Creates an Unix script task with a script file in the user domain.
    ///
    /// - Parameter url: The script file URL.
    init(url: URL) throws {
        
        self.task = try NSUserUnixTask(url: url)
        self.task.standardInput = self.inputPipe.fileHandleForReading
        self.task.standardOutput = self.outputPipe.fileHandleForWriting
        self.task.standardError = self.errorPipe.fileHandleForWriting
    }
    
    
    /// Executes the user script.
    ///
    /// - Parameters:
    ///   - arguments: An array of Strings containing the script arguments.
    ///   - capturesOutput: Whether to capture the standard output.
    func execute(arguments: [String] = [], capturesOutput: Bool = true) async throws {
        
        guard self.state == .ready else { return assertionFailure("The task can be executed only once.") }
        
        self.state = .executing
        defer { self.state = .finished }
        
        // read output and error asynchronously to safely handle huge output
        if capturesOutput {
            self.outputBuffer = self.outputPipe.readingStream
        } else {
            self.outputBuffer = nil
            self.outputPipe.drain()
        }
        self.errorBuffer = self.errorPipe.readingStream
        
        // close the writing end so that scripts reading stdin receive EOF
        if !self.hasInput {
            try self.inputPipe.fileHandleForWriting.close()
        }
        
        do {
            try await self.task.execute(withArguments: arguments)
        } catch let error as POSIXError where error.code == .ENOTBLK {  // on user cancellation
            return
        } catch {
            throw error
        }
    }
    
    
    /// Sends the input as the standard input to the script.
    ///
    /// - Parameter input: The string to input.
    func pipe(input: String) {
        
        guard
            self.state == .ready,
            !self.hasInput
        else { return assertionFailure("Input must be piped only once before executing the task.") }
        
        self.hasInput = true
        let data = Data(input.utf8)
        
        guard !data.isEmpty else {
            do {
                try self.inputPipe.fileHandleForWriting.close()
            } catch {
                assertionFailure(error.localizedDescription)
            }
            return
        }
        
        // write input in chunks so the pipe buffer doesn’t block on large input
        let chunkSize = Self.inputChunkSize
        let inputState = Mutex(InputState())
        self.inputPipe.fileHandleForWriting.writeabilityHandler = { handle in
            let shouldClose = inputState.withLock { state in
                guard !state.isFinished else { return false }
                
                let endIndex = min(state.offset + chunkSize, data.endIndex)
                
                do {
                    try handle.write(contentsOf: data[state.offset..<endIndex])
                    state.offset = endIndex
                } catch {
                    assertionFailure(error.localizedDescription)
                    state.offset = data.endIndex
                }
                
                if state.offset == data.endIndex {
                    state.isFinished = true
                    return true
                }
                
                return false
            }
            
            if shouldClose {
                handle.writeabilityHandler = nil
                try? handle.close()
            }
        }
    }
    
    
    /// The standard output.
    ///
    /// - Note: Available only after `execute()` finishes; consumed on first read.
    var output: String? {
        
        get async {
            guard self.state == .finished else {
                assertionFailure("Output must be read after executing the task.")
                return nil
            }
            
            guard let outputBuffer else { return nil }
            
            // clear output buffer so it is consumed only once
            self.outputBuffer = nil
            
            let data = await outputBuffer.reduce(into: Data()) { $0 += $1 }
            
            return String(data: data, encoding: .utf8)
        }
    }
    
    
    /// The standard error.
    ///
    /// - Note: Available only after `execute()` finishes; consumed on first read.
    var error: String? {
        
        get async {
            guard self.state == .finished else {
                assertionFailure("Error output must be read after executing the task.")
                return nil
            }
            
            guard let errorBuffer else { return nil }
            
            // clear error buffer so it is consumed only once
            self.errorBuffer = nil
            
            let data = await errorBuffer.reduce(into: Data()) { $0 += $1 }
            
            guard !data.isEmpty else { return nil }
            
            return String(data: data, encoding: .utf8)
        }
    }
}


private extension Pipe {
    
    /// An asynchronous stream of data read from the pipe.
    var readingStream: AsyncStream<Data> {
        
        AsyncStream { continuation in
            self.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                    continuation.finish()
                } else {
                    continuation.yield(data)
                }
            }
        }
    }
    
    
    /// Reads and discards the pipe output.
    func drain() {
        
        self.fileHandleForReading.readabilityHandler = { handle in
            // read and discard available data; finish on EOF
            if handle.availableData.isEmpty {
                handle.readabilityHandler = nil
            }
        }
    }
}
