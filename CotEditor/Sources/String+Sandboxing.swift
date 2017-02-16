/*
 
 String+Sandboxing.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-07-25.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

extension String {
    
    /// Returns a new string representing the receiver as a path with a tilde (~) substituted for the full path to the current user’s home directory.
    var abbreviatingWithTildeInSandboxedPath: String {
        
        return self.replacingOccurrences(of: homeDirectory, with: "~", options: .anchored)
    }
    
}


private let homeDirectory: String = {
    
    guard
        let passwd = getpwuid(getuid()),
        let directory = passwd.pointee.pw_dir
        else { return NSHomeDirectory() }
    
    return String(cString: directory)
}()
