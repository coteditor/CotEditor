//
//  ScriptDescriptor.swift
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

enum ScriptingFileType: CaseIterable {
    
    case appleScript
    case unixScript
    
    
    var extensions: [String] {
        
        switch self {
            case .appleScript: return ["applescript", "scpt", "scptd"]
            case .unixScript: return ["sh", "pl", "php", "rb", "py", "js", "swift"]
        }
    }
    
}



enum ScriptingExecutionModel: String, Decodable {
    
    case unrestricted
    case persistent
}



enum ScriptingEventType: String, Decodable {
    
    case documentOpened = "document opened"
    case documentSaved = "document saved"
    
    
    var eventID: AEEventID {
        
        switch self {
            case .documentOpened: return "edod"
            case .documentSaved: return "edsd"
        }
    }
    
}



private struct ScriptInfo: Decodable {
    
    var executionModel: ScriptingExecutionModel?
    var eventType: [ScriptingEventType]?
    
    
    private enum CodingKeys: String, CodingKey {
        
        case executionModel = "CotEditorExecutionModel"
        case eventType = "CotEditorHandlers"
    }
    
    
    /// Load from Info.plist in script bundle.
    init(scriptBundle bundleURL: URL) throws {
        
        let plistURL = bundleURL.appendingPathComponent("Contents/Info.plist")
        let data = try Data(contentsOf: plistURL)
        
        self = try PropertyListDecoder().decode(ScriptInfo.self, from: data)
    }
    
}



// MARK: -

struct ScriptDescriptor {
    
    // MARK: Public Properties
    
    let url: URL
    let name: String
    let type: ScriptingFileType
    let executionModel: ScriptingExecutionModel
    let eventTypes: [ScriptingEventType]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Create a descriptor that represents a user script at given URL.
    ///
    /// `Contents/Info.plist` in the script at `url` will be read if they exist.
    ///
    /// - Parameter url: The location of a user script.
    init?(at url: URL, name: String) {
        
        guard let type = ScriptingFileType.allCases.first(where: { $0.extensions.contains(url.pathExtension) }) else { return nil }
        
        self.url = url
        self.name = name
        self.type = type
        
        // load some settings Info.plist if exists
        let info = (self.type == .appleScript) ? (try? ScriptInfo(scriptBundle: url)) : nil
        self.executionModel = info?.executionModel ?? .unrestricted
        self.eventTypes = info?.eventType ?? []
    }
    
    
    
    // MARK: Public Methods
    
    /// Create and return a user script instance.
    ///
    /// - Returns: An instance of `Script` created by the receiver.
    ///            Returns `nil` if the script type is unsupported.
    func makeScript() throws -> Script {
        
        return try self.scriptType.init(url: self.url, name: self.name)
    }
        
    
    
    // MARK: Private Methods
    
    private var scriptType: Script.Type {
        
        switch self.type {
            case .appleScript:
                switch self.executionModel {
                    case .unrestricted: return AppleScript.self
                    case .persistent: return PersistentOSAScript.self
                }
            case .unixScript: return UnixScript.self
        }
    }
    
}
