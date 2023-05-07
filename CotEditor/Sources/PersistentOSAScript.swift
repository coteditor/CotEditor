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
import OSAKit

final class PersistentOSAScript: Script, AppleEventReceivable {
    
    // MARK: Script Properties
    
    let url: URL
    let name: String
    
    
    // MARK: Private Properties
    
    private let script: OSAScript
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(url: URL, name: String) throws {
        
        guard let script = OSAScript(contentsOf: url, error: nil) else {
            throw ScriptFileError(kind: .read, url: url)
        }
        
        self.url = url
        self.name = name
        self.script = script
    }
    
    
    
    // MARK: Script Methods
    
    /// Execute the script.
    ///
    /// - Throws: `ScriptError` by the script,`ScriptFileError`, or any errors on script loading.
    func run() async throws {
        
        guard self.url.isReachable else {
            throw ScriptFileError(kind: .existence, url: self.url)
        }
        
        var errorInfo: NSDictionary? = NSDictionary()
        self.script.executeAndReturnError(&errorInfo)
        
        if let errorDescription = errorInfo?[NSLocalizedDescriptionKey] as? String {
            throw ScriptError.standardError(errorDescription)
        }
    }
    
    
    /// Execute the script by sending it the given Apple event.
    ///
    /// - Parameters:
    ///   - event: The Apple event.
    /// - Throws: `ScriptError` by the script, `ScriptFileError`, or any errors on `NSUserAppleScriptTask.init(url:)`
    func run(withAppleEvent event: NSAppleEventDescriptor?) async throws {
        
        guard let event else {
            return try await self.run()
        }
        
        guard self.url.isReachable else {
            throw ScriptFileError(kind: .existence, url: self.url)
        }
        
        var errorInfo: NSDictionary?
        self.script.executeAppleEvent(event, error: &errorInfo)
        
        if let errorDescription = errorInfo?[NSLocalizedDescriptionKey] as? String {
            throw ScriptError.standardError(errorDescription)
        }
    }
}
