/*
 
 BatchReplacement.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-19.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
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

struct BatchReplacement {
    
    struct Settings {
        
        let textualOptions: NSString.CompareOptions
        let regexOptions: NSRegularExpression.Options
        let unescapesReplacementString: Bool
    }
    
    
    
    // MARK: Public Properties
    
    let name: String
    let settings: Settings
    let replacements: [Replacement]
    
    
    
    // MARK: -
    // MARK: LifeCycle
    
    init(url: URL) throws {
        
        // load JSON data
        let data = try Data(contentsOf: url)
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        
        guard let json = jsonObject as? [String: Any] else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let name = url.deletingPathExtension().lastPathComponent
        
        self = try BatchReplacement(name: name, json: json)
    }
    
    
    init(name: String, json: [String: Any]) throws {
        
        guard
            let replacementsJson = json["replacements"] as? [[String: Any]],
            let settingsJson = json["settings"] as? [String: Any]
            else { throw CocoaError(.fileReadCorruptFile) }
        
        self.name = name
        self.settings = Settings(textualOptions: NSString.CompareOptions(rawValue: (settingsJson["textualOptions"] as? UInt) ?? 0),
                                 regexOptions: NSRegularExpression.Options(rawValue: (settingsJson["regexOptions"] as? UInt) ?? 0),
                                 unescapesReplacementString: (settingsJson["unescapesReplacementString"] as? Bool) ?? false)
        self.replacements = replacementsJson.flatMap { Replacement(dictionary: $0) }
    }
    
}
