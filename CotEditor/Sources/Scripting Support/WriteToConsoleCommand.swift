//
//  WriteToConsoleCommand.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-21.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2025 1024jp
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

final class WriteToConsoleCommand: NSScriptCommand {
    
    override func performDefaultImplementation() -> Any? {
        
        guard let message = self.directParameter as? String else {
            self.scriptErrorNumber = OSAMissingParameter
            self.scriptErrorOffendingObjectDescriptor = NSAppleEventDescriptor(string: "message")
            return false
        }
        
        let arguments = self.evaluatedArguments ?? [:]
        let title = (arguments["title"] as? Bool) ?? true
        let timestamp = (arguments["timestamp"] as? Bool) ?? true
        
        let options = Console.DisplayOptions()
            .union(title ? .title : [])
            .union(timestamp ? .timestamp : [])
        
        Task { @MainActor in
            let log = Console.Log(message: message, title: ScriptManager.shared.currentScriptName)
            ConsolePanelController.shared.append(log: log, options: options)
            ConsolePanelController.shared.showWindow(nil)
        }
        
        return true
    }
}
