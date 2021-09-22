//
//  NSApplication.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2021-06-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2021 1024jp
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

import AppKit

extension NSApplication {
    
    /// Relaunch application itself.
    func relaunch() {
        
        let escapedPath = Bundle.main.bundlePath.replacingOccurrences(of: "\"", with: "\\\"")
        let command = String(format: "sleep 2; open \"%@\"", escapedPath)
        
        Process.launchedProcess(launchPath: "/bin/sh", arguments: ["-c", command])
    }
    
}
