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

protocol Script: AnyObject {
    
    // MARK: Properties
    
    var url: URL { get }
    var name: String { get }
    
    
    // MARK: Methods
    
    init(url: URL, name: String) throws
    
    
    /// Execute the script.
    ///
    /// - Parameters:
    ///   - completionHandler: The completion handler block that returns a script error if any.
    ///   - error: The `ScriptError` by the script.
    /// - Throws: `ScriptFileError` and any errors on script loading.
    func run(completionHandler: @escaping ((_ error: ScriptError?) -> Void)) throws
}


protocol AppleEventReceivable {
    
    /// Execute the script by sending it the given Apple event.
    ///
    /// - Parameters:
    ///   - event: The apple event.
    ///   - completionHandler: The completion handler block that returns a script error if any.
    ///   - error: The `ScriptError` by the script.
    /// - Throws: `ScriptFileError` and any errors on `NSUserAppleScriptTask.init(url:)`
    func run(withAppleEvent event: NSAppleEventDescriptor?, completionHandler: @escaping ((_ error: ScriptError?) -> Void)) throws
}

typealias EventScript = Script & AppleEventReceivable



// MARK: - Errors

struct ScriptFileError: LocalizedError {
    
    enum ErrorKind {
        case existance
        case read
        case open
        case permission
    }
    
    let kind: ErrorKind
    let url: URL
    
    
    var errorDescription: String? {
        
        switch self.kind {
            case .existance:
                return String(format: "The script “%@” does not exist.".localized, self.url.lastPathComponent)
            case .read:
                return String(format: "The script “%@” couldn’t be read.".localized, self.url.lastPathComponent)
            case .open:
                return String(format: "The script file “%@” couldn’t be opened.".localized, self.url.path)
            case .permission:
                return String(format: "The script “%@” can’t be executed because you don’t have the execute permission.".localized, self.url.lastPathComponent)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.kind {
            case .permission:
                return "Check the permission of the script file.".localized
            default:
                return "Check the script file.".localized
        }
    }
    
}



enum ScriptError: LocalizedError {
    
    case standardError(String)
    case noInputTarget
    case noOutputTarget
    
    
    var errorDescription: String {
        
        switch self {
            case .standardError(let string):
                return string
            case .noInputTarget:
                return "No document to get input.".localized
            case .noOutputTarget:
                return "No document to put output.".localized
        }
    }
    
}
