//
//  Data+Authopen.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-06-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2018 1024jp
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

// ------------------------------------------------------------------------------
// These extension methods are Sandbox incompatible.
// They had been used until CotEditor 2.1.6 (2015-07), the last non-Sandboxed version.
// Currently not in use, and should not be used.
// We keep this just for a record.
// You can remove these if you feel it's really needless.
// ------------------------------------------------------------------------------

private let authopenPath = "/usr/libexec/authopen"

extension Data {
    
    /// Try reading data at the URL using authopen (Sandobox incompatible)
    @available(*, unavailable, message: "Sandbox incompatible")
    init(forceReadFromFileURL fileURL: URL) throws {
        
        assert(fileURL.isFileURL)
        
        let process = Process()
        let stdOut = Pipe()
        process.launchPath = authopenPath
        process.arguments = [fileURL.path]
        process.standardOutput = stdOut
        
        process.launch()
        self = stdOut.fileHandleForReading.readDataToEndOfFile()
        
        while process.isRunning {
            usleep(200)
        }
        
        guard process.terminationStatus == 0 else {
            throw AuthopenError.nonzeroTerminationStatus(process.terminationStatus)
        }
    }
    
    
    /// Try writing data to the URL using authopen (Sandobox incompatible)
    @available(*, unavailable, message: "Sandbox incompatible")
    func forceWrite(to fileURL: URL) throws {
        
        assert(fileURL.isFileURL)
        
        let process = Process()
        let stdOut = Pipe()
        process.launchPath = authopenPath
        process.arguments = ["-c", "-c", fileURL.path]
        process.standardOutput = stdOut
        
        process.launch()
        stdOut.fileHandleForWriting.write(self)
        stdOut.fileHandleForWriting.closeFile()
        
        // [caution] Do not use `process.waitUntilExit()` here,
        //           since it passes through the run-loop and other file access can interrupt.
        while process.isRunning {
            usleep(200)
        }
        
        guard process.terminationStatus == 0 else {
            throw AuthopenError.nonzeroTerminationStatus(process.terminationStatus)
        }
    }
    
}


enum AuthopenError: Error {
    
    case nonzeroTerminationStatus(Int32)
}
