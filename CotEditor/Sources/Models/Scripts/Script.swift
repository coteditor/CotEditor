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
//  © 2016-2025 1024jp
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
import Shortcut

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
                String(localized: "ScriptFileError.existence.description",
                       defaultValue: "The script “\(self.url.lastPathComponent)” does not exist.",
                       table: "Script")
            case .read:
                String(localized: "ScriptFileError.read.description",
                       defaultValue: "The script “\(self.url.lastPathComponent)” couldn’t be read.",
                       table: "Script")
            case .open:
                String(localized: "ScriptFileError.open.description",
                       defaultValue: "The script file “\(self.url, format: .url.scheme(.never))” couldn’t be opened.",
                       table: "Script")
            case .permission:
                String(localized: "ScriptFileError.permission.description",
                       defaultValue: "The script “\(self.url.lastPathComponent)” can’t be executed because you don’t have the execute permission.",
                       table: "Script")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.code {
            case .permission:
                String(localized: "ScriptFileError.permission.recoverySuggestion",
                       defaultValue: "Check the permission of the script file.",
                       table: "Script")
            default:
                String(localized: "ScriptFileError.recoverySuggestion",
                       defaultValue: "Check the script file.",
                       table: "Script")
        }
    }
}


enum ScriptError: LocalizedError {
    
    case standardError(String)
    case noInputTarget
    case noOutputTarget
    case notEditable
    
    
    var errorDescription: String? {
        
        switch self {
            case .standardError(let string):
                string
            case .noInputTarget:
                String(localized: "ScriptError.noInputTarget.description",
                       defaultValue: "No document to get input.",
                       table: "Script")
            case .noOutputTarget:
                String(localized: "ScriptError.noOutputTarget.description",
                       defaultValue: "No document to put output.",
                       table: "Script")
            case .notEditable:
                String(localized: "ScriptError.notEditable.description",
                       defaultValue: "The document is not editable.",
                       table: "Script")
        }
    }
}
