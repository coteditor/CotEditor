//
//  PersistentOSAScript.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-10-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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
import OSAKit
import Shortcut

struct PersistentOSAScript: EventScript {
    
    // MARK: Script Properties
    
    let url: URL
    let name: String
    let shortcut: Shortcut?
    var eventTypes: [ScriptingEventType] = []
    
    
    // MARK: Private Properties
    
    private let compiledData: Data
    
    
    // MARK: Lifecycle
    
    init(url: URL, name: String, shortcut: Shortcut?) throws {
        
        guard
            let script = OSAScript(contentsOf: url, error: nil),
            let data = script.compiledData(forType: url.pathExtension, error: nil)
        else { throw ScriptFileError(.read, url: url) }
        
        self.url = url
        self.name = name
        self.shortcut = shortcut
        self.compiledData = data
    }
    
    
    // MARK: Script Methods
    
    /// Executes the script by sending it the given Apple event.
    ///
    /// - Parameters:
    ///   - event: The Apple event.
    /// - Throws: `ScriptError` by the script, `ScriptFileError`, or any errors on `NSUserAppleScriptTask.init(url:)`
    func run(withAppleEvent event: NSAppleEventDescriptor?) async throws {
        
        let script = try OSAScript(compiledData: self.compiledData, from: self.url)
        
        var errorInfo: NSDictionary?
        if let event {
            script.executeAppleEvent(event, error: &errorInfo)
        } else {
            script.executeAndReturnError(&errorInfo)
        }
        
        if let errorDescription = errorInfo?[NSLocalizedDescriptionKey] as? String {
            throw ScriptError.standardError(errorDescription)
        }
    }
}
