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

actor UserUnixTask {
    
    // MARK: Private Types
    
    private enum State {
        
        case ready
        case executing
        case finished
    }
    
    
    // MARK: Private Properties
    
    private let task: NSUserUnixTask
    private var outputBuffer: AsyncThrowingStream<Data, any Error>?
    private var errorBuffer: AsyncThrowingStream<Data, any Error>?
    private var state: State = .ready
    
    
    // MARK: Public Methods
    
    /// Creates a Unix script task with a script file in the user domain.
    ///
    /// - Parameter url: The script file URL.
    /// - Throws: An error if the script task cannot be created.
    init(url: URL) throws {
        
        self.task = try NSUserUnixTask(url: url)
    }
    
    
    /// Executes the user script.
    ///
    /// - Parameters:
    ///   - arguments: An array of strings containing the script arguments.
    ///   - input: The string to send to the standard input, or `nil` for no input.
    ///   - capturesOutput: Whether to capture the standard output.
    /// - Throws: An error if executing the script or writing its input fails.
    func execute(arguments: [String] = [], input: String? = nil, capturesOutput: Bool = true) async throws {
        
        guard self.state == .ready else { return assertionFailure("The task can be executed only once.") }
        
        self.state = .executing
        
        // use /dev/null for streams that do not need a pipe
        let inputData = input.map { Data($0.utf8) } ?? Data()
        let inputPipe = inputData.isEmpty ? nil : Pipe()
        let outputPipe = capturesOutput ? Pipe() : nil
        let errorPipe = Pipe()
        self.task.standardInput = inputPipe?.fileHandleForReading
        self.task.standardOutput = outputPipe?.fileHandleForWriting
        self.task.standardError = errorPipe.fileHandleForWriting
        
        // read output and error asynchronously to safely handle huge output
        self.outputBuffer = outputPipe?.readingStream
        self.errorBuffer = errorPipe.readingStream
        
        let inputWriter = inputPipe.map { $0.write(inputData) }
        defer {
            // stop pending writes on failure or cancellation
            inputWriter?.channel.close(flags: .stop)
            try? inputPipe?.fileHandleForReading.close()
            try? outputPipe?.fileHandleForWriting.close()
            try? errorPipe.fileHandleForWriting.close()
            self.state = .finished
        }
        
        do {
            try await self.task.execute(withArguments: arguments)
        } catch let error as POSIXError where error.code == .ENOTBLK {  // on user cancellation
            return
        }
        
        if let inputWriter {
            // allow child processes to finish reading; EPIPE ends the write once all readers close
            try? inputPipe?.fileHandleForReading.close()
            for try await _ in inputWriter.completion { }
            try Task.checkCancellation()
        }
    }
    
    
    /// The standard output.
    ///
    /// - Throws: An error if reading the output fails or is canceled.
    /// - Note: Available only after `execute()` finishes; consumed on first read.
    var output: String? {
        
        get async throws {
            guard self.state == .finished else {
                assertionFailure("Output must be read after executing the task.")
                return nil
            }
            
            guard let outputBuffer else { return nil }
            
            // clear output buffer so it is consumed only once
            self.outputBuffer = nil
            
            let data = try await outputBuffer.reduce(into: Data()) { $0 += $1 }
            try Task.checkCancellation()
            
            return String(data: data, encoding: .utf8)
        }
    }
    
    
    /// The standard error.
    ///
    /// - Note: Available only after `execute()` finishes; consumed on first read.
    /// - Throws: An error if reading the error output fails or is canceled.
    var error: String? {
        
        get async throws {
            guard self.state == .finished else {
                assertionFailure("Error output must be read after executing the task.")
                return nil
            }
            
            guard let errorBuffer else { return nil }
            
            // clear error buffer so it is consumed only once
            self.errorBuffer = nil
            
            let data = try await errorBuffer.reduce(into: Data()) { $0 += $1 }
            try Task.checkCancellation()
            
            guard !data.isEmpty else { return nil }
            
            return String(data: data, encoding: .utf8)
        }
    }
}


private extension Pipe {
    
    /// An asynchronous stream of data read from the pipe.
    var readingStream: AsyncThrowingStream<Data, any Error> {
        
        AsyncThrowingStream { [handle = self.fileHandleForReading] continuation in
            let queue = DispatchQueue.global(qos: .utility)
            let channel = DispatchIO(type: .stream, fileDescriptor: handle.fileDescriptor, queue: queue) { error in
                if error != 0 {
                    continuation.finish(throwing: POSIXError(.init(rawValue: error)!))
                }
                try? handle.close()
            }
            channel.setLimit(lowWater: 1)
            
            continuation.onTermination = { _ in
                channel.close(flags: .stop)
            }
            channel.read(offset: 0, length: Int.max, queue: queue) { done, data, error in
                guard error == 0 else {
                    continuation.finish(throwing: POSIXError(.init(rawValue: error)!))
                    return
                }
                if let data, !data.isEmpty {
                    continuation.yield(Data(data))
                }
                if done {
                    continuation.finish()
                }
            }
        }
    }
    
    
    /// Writes data asynchronously and closes the writing end when finished.
    ///
    /// - Parameter data: The data to write.
    /// - Returns: The channel to stop if the reader finishes early and a stream reporting completion or an unexpected write error.
    func write(_ data: Data) -> (channel: DispatchIO, completion: AsyncThrowingStream<Void, any Error>) {
        
        let handle = self.fileHandleForWriting
        let queue = DispatchQueue.global(qos: .utility)
        let (completion, continuation) = AsyncThrowingStream<Void, any Error>.makeStream()
        let channel = DispatchIO(type: .stream, fileDescriptor: handle.fileDescriptor, queue: queue) { error in
            if error != 0 {
                continuation.finish(throwing: POSIXError(.init(rawValue: error)!))
            }
            try? handle.close()
        }
        let data = data.withUnsafeBytes { DispatchData(bytes: $0) }
        
        channel.write(offset: 0, data: data, queue: queue) { done, _, error in
            guard done else { return }
            
            channel.close()
            
            switch error {
                case 0, POSIXErrorCode.EPIPE.rawValue, POSIXErrorCode.ECANCELED.rawValue:
                    // the script may close stdin early, or execution may stop pending writes
                    continuation.finish()
                default:
                    continuation.finish(throwing: POSIXError(.init(rawValue: error)!))
            }
        }
        
        return (channel, completion)
    }
}
