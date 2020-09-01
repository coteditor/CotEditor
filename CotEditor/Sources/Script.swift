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
    
    /// Execute the script with the default way.
    func run(completionHandler: @escaping (() -> Void)) throws
}


protocol AppleEventReceivable {
    
    /// Execute the script by sending it the given Apple event.
    func run(withAppleEvent event: NSAppleEventDescriptor?, completionHandler: @escaping (() -> Void)) throws
}

typealias EventScript = Script & AppleEventReceivable



// MARK: - Error

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


// MARK: Functions

func writeToConsole(message: String, scriptName: String) {
    
    let log = Console.Log(message: message, title: scriptName)
    
    DispatchQueue.main.async {
        Console.shared.panelController.showWindow(nil)
        Console.shared.append(log: log)
    }
}
