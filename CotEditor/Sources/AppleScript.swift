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

import Combine
import Foundation

final class AppleScript: Script, AppleEventReceivable {
    
    // MARK: Script Properties
    
    let url: URL
    let name: String
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    init(url: URL, name: String) throws {
        
        self.url = url
        self.name = name
    }
    
    
    
    // MARK: Script Methods
    
    /// Execute the script.
    ///
    /// - Parameters:
    ///   - completionHandler: The completion handler block that returns a script error if any.
    ///   - error: The `ScriptError` by the script.
    /// - Throws: `ScriptFileError` and any errors on `NSUserAppleScriptTask.init(url:)`
    func run(completionHandler: @escaping ((_ error: ScriptError?) -> Void)) throws {
        
        try self.run(withAppleEvent: nil, completionHandler: completionHandler)
    }
    
    
    /// Execute the script by sending it the given Apple event.
    ///
    /// - Parameters:
    ///   - event: The apple event.
    ///   - completionHandler: The completion handler block that returns a script error if any.
    ///   - error: The `ScriptError` by the script.
    /// - Throws: `ScriptFileError` and any errors on `NSUserAppleScriptTask.init(url:)`
    func run(withAppleEvent event: NSAppleEventDescriptor?, completionHandler: @escaping ((_ error: ScriptError?) -> Void)) throws {
        
        guard self.url.isReachable else {
            throw ScriptFileError(kind: .existance, url: self.url)
        }
        
        let task = try NSUserAppleScriptTask(url: self.url)
        
        task.execute(withAppleEvent: event) { (_, error) in
            let scriptError = error.flatMap { ScriptError.standardError($0.localizedDescription) }
            
            completionHandler(scriptError)
        }
    }
    
}
