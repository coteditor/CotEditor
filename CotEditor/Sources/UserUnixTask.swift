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
//  © 2022 1024jp
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

final actor UserUnixTask {
    
    // MARK: Private Properties
    
    private let task: NSUserUnixTask
    private let inputPipe = Pipe()
    private let outputPipe = Pipe()
    private let errorPipe = Pipe()
    private var buffer: AsyncStream<Data>?
    
    
    
    // MARK: Public Methods
    
    /// Create an Unix script task with a script file in the user domain.
    ///
    /// - Parameter url: The script file URL.
    init(url: URL) throws {
        
        self.task = try NSUserUnixTask(url: url)
        self.task.standardInput = self.inputPipe.fileHandleForReading
        self.task.standardOutput = self.outputPipe.fileHandleForWriting
        self.task.standardError = self.errorPipe.fileHandleForWriting
    }
    
    
    /// Execute the user script.
    ///
    /// - Parameter arguments: An array of Strings containing the script arguments.
    func execute(arguments: [String] = []) async throws {
        
        // read output asynchronously for safe with huge output
        self.buffer = self.outputPipe.readingStream
        
        do {
            try await self.task.execute(withArguments: arguments)
        } catch where (error as? POSIXError)?.code == .ENOTBLK {  // on user cancellation
            return
        } catch {
            throw error
        }
    }
    
    /// Send the input as the standard input to the script.
    ///
    /// - Parameter input: The string to input.
    func pipe(input: String) {
        
        guard let data = input.data(using: .utf8) else { return assertionFailure() }
        
        self.inputPipe.fileHandleForWriting.writeabilityHandler = { (handle) in
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
            guard let buffer = self.buffer else { return nil }
            
            let data = await buffer.reduce(into: Data()) { $0 += $1 }
            
            return String(data: data, encoding: .utf8)
        }
    }
    
    
    /// The standard error.
    var error: String? {
        
        guard
            let data = try? self.errorPipe.fileHandleForReading.readToEnd(),
            let string = String(data: data, encoding: .utf8),
            !string.isEmpty
        else { return nil }
        
        return string
    }
}



private extension Pipe {
    
    /// Create asynchronous stream for the standard output.
    var readingStream: AsyncStream<Data> {
        
        AsyncStream { (continuation) in
            self.fileHandleForReading.readabilityHandler = { (handle) in
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
