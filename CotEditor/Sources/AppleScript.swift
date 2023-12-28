//
//  AppleScript.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-10-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2023 1024jp
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

struct AppleScript: EventScript {
    
    // MARK: Script Properties
    
    let url: URL
    let name: String
    let shortcut: Shortcut?
    var eventTypes: [ScriptingEventType] = []
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(url: URL, name: String, shortcut: Shortcut?) throws {
        
        self.url = url
        self.name = name
        self.shortcut = shortcut
    }
    
    
    
    // MARK: Script Methods
    
    /// Executes the script by sending it the given Apple event.
    ///
    /// - Parameters:
    ///   - event: The Apple event.
    /// - Throws: `ScriptError` by the script, `ScriptFileError`, or any errors on `NSUserAppleScriptTask.init(url:)`
    func run(withAppleEvent event: NSAppleEventDescriptor?) async throws {
        
        guard self.url.isReachable else {
            throw ScriptFileError(kind: .existence, url: self.url)
        }
        
        let task = try NSUserAppleScriptTask(url: self.url)
        
        do {
            try await task.execute(withAppleEvent: event)
        } catch {
            throw ScriptError.standardError(error.localizedDescription)
        }
    }
}
