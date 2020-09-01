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
//  © 2016-2020 1024jp
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

final class PersistentOSAScript: Script, AppleEventReceivable {
    
    // MARK: Script Properties
    
    let descriptor: ScriptDescriptor
    
    
    // MARK: Private Properties
    
    private let script: OSAScript
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init?(descriptor: ScriptDescriptor) {
        
        guard let script = OSAScript(contentsOf: descriptor.url, error: nil) else { return nil }
        
        self.descriptor = descriptor
        self.script = script
    }
    
    
    
    // MARK: Script Methods
    
    /// run script
    ///
    /// - Throws: Error by `NSUserScriptTask`
    func run(completionHandler: (() -> Void) = {}) throws {
        
        guard self.descriptor.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.descriptor.url)
        }
        
        var errorInfo: NSDictionary? = NSDictionary()
        if self.script.executeAndReturnError(&errorInfo) == nil {
            let message = (errorInfo?[NSLocalizedDescriptionKey] as? String) ?? "Unknown error"
            writeToConsole(message: message, scriptName: self.descriptor.name)
        }
        
        completionHandler()
    }
    
    
    /// Execute the AppleScript script by sending it the given Apple event.
    ///
    /// Any script errors will be written to the console panel.
    ///
    /// - Parameter event: The apple event.
    /// - Throws: `ScriptFileError` and any errors by `NSUserScriptTask.init(url:)`
    func run(withAppleEvent event: NSAppleEventDescriptor?, completionHandler: @escaping (() -> Void) = {}) throws {
        
        guard let event = event else {
            try self.run(completionHandler: completionHandler)
            return
        }
        
        guard self.descriptor.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.descriptor.url)
        }
        
        var errorInfo: NSDictionary?
        if self.script.executeAppleEvent(event, error: &errorInfo) == nil {
            let message = (errorInfo?[NSLocalizedDescriptionKey] as? String) ?? "Unknown error"
            writeToConsole(message: message, scriptName: self.descriptor.name)
        }
        
        completionHandler()
    }
    
}
