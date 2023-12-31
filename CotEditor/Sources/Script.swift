//
//  Script.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-10-22.
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

protocol Script: Sendable {
    
    // MARK: Properties
    
    var url: URL { get }
    var name: String { get }
    var shortcut: Shortcut? { get }
    
    
    // MARK: Methods
    
    init(url: URL, name: String, shortcut: Shortcut?) throws
    
    
    /// Executes the script.
    ///
    /// - Throws: `ScriptError` by the script,`ScriptFileError`, or any errors on script loading.
    func run() async throws
}


protocol EventScript: Script {
    
    var eventTypes: [ScriptingEventType] { get set }
    
    
    /// Executes the script by sending it the given Apple event.
    ///
    /// - Parameters:
    ///   - event: The Apple event.
    /// - Throws: `ScriptError` by the script, `ScriptFileError`, or any errors on `NSUserAppleScriptTask.init(url:)`
    func run(withAppleEvent event: NSAppleEventDescriptor?) async throws
}


extension EventScript {
    
    func run() async throws {
        
        try await self.run(withAppleEvent: nil)
    }
}



// MARK: - Errors

struct ScriptFileError: LocalizedError {
    
    enum Code {
        
        case existence
        case read
        case open
        case permission
    }
    
    var code: Code
    var url: URL
    
    
    init(_ code: Code, url: URL) {
        
        self.code = code
        self.url = url
    }
    
    
    var errorDescription: String? {
        
        switch self.code {
            case .existence:
                String(localized: "The script “\(self.url.lastPathComponent)” does not exist.")
            case .read:
                String(localized: "The script “\(self.url.lastPathComponent)” couldn’t be read.")
            case .open:
                String(localized: "The script file “\(self.url.path)” couldn’t be opened.")
            case .permission:
                String(localized: "The script “\(self.url.lastPathComponent)” can’t be executed because you don’t have the execute permission.")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.code {
            case .permission:
                String(localized: "Check the permission of the script file.")
            default:
                String(localized: "Check the script file.")
        }
    }
}



enum ScriptError: LocalizedError {
    
    case standardError(String)
    case noInputTarget
    case noOutputTarget
    
    
    var errorDescription: String? {
        
        switch self {
            case .standardError(let string):
                string
            case .noInputTarget:
                String(localized: "No document to get input.")
            case .noOutputTarget:
                String(localized: "No document to put output.")
        }
    }
}
