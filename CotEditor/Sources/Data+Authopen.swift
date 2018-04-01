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
// This category is Sandbox incompatible.
// They had been used until CotEditor 2.1.6 (2015-07) which is the last non-Sandboxed version.
// Currently not in use, and should not be used.
// We keep this just for a record.
// You can remove these if you feel it's really needless.
// ------------------------------------------------------------------------------

private let authopenPath = "/usr/libexec/authopen"

extension Data {
    
    /// Try reading data at the URL using authopen (Sandobox incompatible)
    @available(macOS, unavailable, message: "Sandbox incompatible")
    init?(forceReadFromFileURL fileURL: URL) {
        
        guard fileURL.isFileURL else { return nil }
        
        let task = Task()
        task.launchPath = authopenPath
        task.arguments = [fileURL.path]
        task.standardOutput = Pipe()
        
        task.launch()
        guard let data = task.standardOutput?.fileHandleForReading.readDataToEndOfFile() else { return nil }
        
        while task.isRunning {
            usleep(200)
        }
        
        self.init(referencing: data)
        
        guard task.terminationStatus == 0 else { return nil }
    }
    
    
    /// Try writing data to the URL using authopen (Sandobox incompatible)
    @available(macOS, unavailable, message: "Sandbox incompatible")
    func forceWrite(to fileURL: URL) -> Bool {
        
        guard fileURL.isFileURL else { return false }
        
        let task = Task()
        task.launchPath = authopenPath
        task.arguments = ["-c", "-c", fileURL.path]
        task.standardOutput = Pipe()
        
        task.launch()
        task.standardInput?.fileHandleForWriting.write(self)
        task.standardInput?.fileHandleForWriting.closeFile()
        
        // [caution] Do not use `[task waitUntilExit]` here,
        //           since it passes through the run-loop and other file access can interrupt.
        while task.isRunning {
            usleep(200)
        }
        
        return (task.terminationStatus == 0)
    }
    
}
