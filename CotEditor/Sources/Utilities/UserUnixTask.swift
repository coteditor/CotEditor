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
    
    // MARK: Private Properties
    
    private let task: NSUserUnixTask
    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()
    private var outputBuffer: AsyncStream<Data>?
    private var errorBuffer: AsyncStream<Data>?
    private var isExecuting = false
    
    
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
    /// - Parameter arguments: An array of Strings containing the script arguments.
    func execute(arguments: [String] = []) async throws {
        
        guard !self.isExecuting else { return assertionFailure() }
        
        self.isExecuting = true
        defer { self.isExecuting = false }

        // read output and error asynchronously to safely handle huge output
        self.outputBuffer = self.outputPipe.readingStream
        self.errorBuffer = self.errorPipe.readingStream
        
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
        
        let data = Data(input.utf8)
        
        self.inputPipe.fileHandleForWriting.writeabilityHandler = { handle in
            do {
                try handle.write(contentsOf: data)
                try handle.close()
            } catch {
                assertionFailure(error.localizedDescription)
            }
            handle.writeabilityHandler = nil
        }
    }
    
    
    /// The standard output.
    var output: String? {
        
        get async {
            guard let outputBuffer else { return nil }
            
            // clear output buffer so it is consumed only once
            self.outputBuffer = nil
            
            let data = await outputBuffer.reduce(into: Data()) { $0 += $1 }
            
            return String(data: data, encoding: .utf8)
        }
    }
    
    
    /// The standard error.
    var error: String? {
        
        get async {
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
    
    /// Creates asynchronous stream for the standard output.
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
}
