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
//  © 2016-2024 1024jp
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
import UniformTypeIdentifiers
import Shortcut

private extension UTType {
    
    static let awkScript = UTType(exportedAs: "com.coteditor.awk")
}


enum ScriptingFileType: CaseIterable {
    
    case appleScript
    case unixScript
    
    
    var fileTypes: [UTType] {
        
        switch self {
            case .appleScript: [.appleScript, .osaScript, .osaScriptBundle]  // .applescript, .scpt, .scptd
            case .unixScript: [.shellScript, .perlScript, .phpScript, .rubyScript, .pythonScript, .javaScript, .awkScript, .swiftSource]
        }
    }
}


enum ScriptingExecutionModel: String, Decodable {
    
    case unrestricted
    case persistent
}


enum ScriptingEventType: String, CaseIterable, Decodable {
    
    case documentOpened = "document opened"
    case documentSaved = "document saved"
    
    
    var eventID: AEEventID {
        
        switch self {
            case .documentOpened: "edod"
            case .documentSaved: "edsd"
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
    
    
    /// Loads from Info.plist in the script bundle.
    ///
    /// - Parameter bundleURL: The URL to the script bundle.
    init(scriptBundle bundleURL: URL) throws {
        
        let plistURL = bundleURL.appending(components: "Contents", "Info.plist")
        let data = try Data(contentsOf: plistURL)
        
        self = try PropertyListDecoder().decode(ScriptInfo.self, from: data)
    }
}


// MARK: -

struct ScriptDescriptor {
    
    // MARK: Public Properties
    
    var url: URL
    var name: String
    var shortcut: Shortcut?
    var eventTypes: [ScriptingEventType]
    
    
    // MARK: Private Properties
    
    private var type: ScriptingFileType
    private var executionModel: ScriptingExecutionModel
    
    
    // MARK: Lifecycle
    
    /// Creates a descriptor that represents a user script at the given URL.
    ///
    /// `Contents/Info.plist` in the script at `url` will be read if they exist.
    ///
    /// - Parameters:
    ///   - url: The location of a user script.
    ///   - name: The name of the script file.
    init?(contentsOf url: URL, name: String) {
        
        guard
            let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType,
            let type = ScriptingFileType.allCases.first(where: { $0.fileTypes.contains { contentType.conforms(to: $0) } })
        else { return nil }
        
        var name = name
        var shortcut = Shortcut(keySpecChars: url.deletingPathExtension().pathExtension)
        shortcut = (shortcut?.isValid == true) ? shortcut : nil
        if shortcut != nil {
            name.replace(/\..+$/, with: "")
        }
        
        self.url = url
        self.name = name
        self.shortcut = shortcut
        self.type = type
        
        // load some settings Info.plist if exists
        let info = (self.type == .appleScript) ? (try? ScriptInfo(scriptBundle: url)) : nil
        self.executionModel = info?.executionModel ?? .unrestricted
        self.eventTypes = info?.eventType ?? []
    }
    
    
    // MARK: Public Methods
    
    /// Creates and returns a user script instance.
    ///
    /// - Returns: An instance of `Script` created by the receiver.
    func makeScript() throws -> any Script {
        
        let script = try self.scriptType.init(url: self.url, name: self.name, shortcut: self.shortcut)
        
        if var script = script as? any EventScript {
            script.eventTypes = self.eventTypes
            return script
        } else {
            return script
        }
    }
    
    
    // MARK: Private Methods
    
    private var scriptType: any Script.Type {
        
        switch self.type {
            case .appleScript:
                switch self.executionModel {
                    case .unrestricted: AppleScript.self
                    case .persistent: PersistentOSAScript.self
                }
            case .unixScript: UnixScript.self
        }
    }
}
