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
//  © 2016-2019 1024jp
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
        case .documentOpened: return AEEventID(code: "edod")
        case .documentSaved: return AEEventID(code: "edsd")
        }
    }
    
}



struct ScriptInfo: Decodable {
    
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
    let shortcut: Shortcut
    let ordering: Int?
    let type: ScriptingFileType?
    let executionModel: ScriptingExecutionModel
    let eventTypes: [ScriptingEventType]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Create a descriptor that represents an user script at given URL.
    ///
    /// `Contents/Info.plist` in the script at `url` will be read if they exist.
    ///
    /// - Parameter url: The location of an user script.
    init(at url: URL) {
        
        self.url = url
        self.type = ScriptingFileType.allCases.first { $0.extensions.contains(url.pathExtension) }
        var name = url.deletingPathExtension().lastPathComponent.immutable
        // -> `.immutable` is a workaround for NSPathStore2 bug (2019-10 Xcode 11.1)
        
        let shortcut = Shortcut(keySpecChars: url.deletingPathExtension().pathExtension)
        if shortcut.modifierMask.isEmpty {
            self.shortcut = .none
        } else {
            self.shortcut = shortcut
            
            // remove the shortcut specification from the script name
            // -> `.immutable` is a workaround for NSPathStore2 bug (2019-10 Xcode 11.1)
            name = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent.immutable
        }
        
        if let range = name.range(of: "^[0-9]+\\)", options: .regularExpression) {
            // remove the parenthesis at last
            let orderingString = name[..<name.index(before: range.upperBound)]
            self.ordering = Int(orderingString)
            
            // Remove the ordering number from the script name
            name.removeSubrange(range)
        } else {
            self.ordering = nil
        }
        
        self.name = name
        
        // load some settings Info.plist if exists
        let info = try? ScriptInfo(scriptBundle: url)
        self.executionModel = info?.executionModel ?? .unrestricted
        self.eventTypes = info?.eventType ?? []
    }
    
    
    
    // MARK: Public Methods
    
    /// Create and return an user script instance.
    ///
    /// - Returns: An instance of `Script` created by the receiver.
    ///            Returns `nil` if the script type is unsupported.
    func makeScript() -> Script? {
        
        switch self.type {
        case .appleScript:
            switch self.executionModel {
            case .unrestricted: return AppleScript(descriptor: self)
            case .persistent: return PersistentOSAScript(descriptor: self)
            }
        case .unixScript: return UnixScript(descriptor: self)
        case .none: return nil
        }
    }
    
}
