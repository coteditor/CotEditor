/*
 
 ScriptDescriptor.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-10-28.
 
 ------------------------------------------------------------------------------
 
 © 2016-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

enum ScriptingEventType: String {
    
    case documentOpened = "document opened"
    case documentSaved = "document saved"
    
    
    var eventID: AEEventID {
        
        switch self {
        case .documentOpened: return AEEventID(code: "edod")
        case .documentSaved: return AEEventID(code: "edsd")
        }
    }
    
}



enum ScriptingFileType {
    
    case appleScript
    case unixScript
    
    static let all: [ScriptingFileType] = [.appleScript, .unixScript]
    
    
    var extensions: [String] {
        
        switch self {
        case .appleScript: return ["applescript", "scpt", "scptd"]
        case .unixScript: return ["sh", "pl", "php", "rb", "py", "js", "swift"]
        }
    }
    
}



enum ScriptingExecutionModel: String {
    
    case unrestricted
    case persistent
    
}



// MARK: -

struct ScriptDescriptor {
    
    // MARK: Public Properties
    
    let url: URL
    let name: String
    let type: ScriptingFileType?
    let executionModel: ScriptingExecutionModel
    let eventTypes: [ScriptingEventType]
    let shortcut: Shortcut
    let ordering: Int?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Create a descriptor that represents an user script at given URL.
    ///
    /// `Contents/Info.plist` in the script at `url` will be read if they exist.
    ///
    /// - parameter url: the location of an user script
    init(at url: URL) {
        
        // Extract from URL
        
        self.url = url
        self.type = ScriptingFileType.all.first { $0.extensions.contains(url.pathExtension) }
        var name = url.deletingPathExtension().lastPathComponent
        
        let shortcut = Shortcut(keySpecChars: url.deletingPathExtension().pathExtension)
        if shortcut.modifierMask.isEmpty {
            self.shortcut = .none
        } else {
            self.shortcut = shortcut
            
            // Remove the shortcut specification from the script name
            name = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
        }
        
        if let range = name.range(of: "^[0-9]+\\)", options: .regularExpression) {
            // Remove the parenthesis at last
            let orderingString = name[..<name.index(before: range.upperBound)]
            self.ordering = Int(orderingString)
            
            // Remove the ordering number from the script name
            name.removeSubrange(range)
        } else {
            self.ordering = nil
        }
        
        self.name = name
        
        // Extract from Info.plist
        
        let info = NSDictionary(contentsOf: url.appendingPathComponent("Contents/Info.plist"))
        
        if let name = info?["CotEditorExecutionModel"] as? String {
            self.executionModel = ScriptingExecutionModel(rawValue: name) ?? .unrestricted
        } else {
            self.executionModel = .unrestricted
        }
        
        if let names = info?["CotEditorHandlers"] as? [String] {
            self.eventTypes = names.flatMap { ScriptingEventType(rawValue: $0) }
        } else {
            self.eventTypes = []
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Create and return an user script instance
    ///
    /// - returns: An instance of `Script` created by the receiver.
    ///            Returns `nil` if the script type is unsupported.
    func makeScript() -> Script? {
        
        guard let type = self.type else { return nil }
        
        switch type {
        case .appleScript:
            switch self.executionModel {
            case .unrestricted: return AppleScript(descriptor: self)
            case .persistent: return PersistentOSAScript(descriptor: self)
            }
        case .unixScript: return UnixScript(descriptor: self)
        }
    }
    
}
