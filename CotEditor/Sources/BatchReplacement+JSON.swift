/*
 
 BatchReplacement+JSON.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-03-17.
 
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

extension BatchReplacement {
    
    enum Key {
        
        static let settings = "settings"
        static let replacements = "replacements"
    }
    
    
    convenience init(name: String, dictionary: [String: Any]) throws {
        
        guard
            let replacementsJson = dictionary[Key.replacements] as? [[String: Any]],
            let settingsJson = dictionary[Key.settings] as? [String: Any]
            else { throw CocoaError(.fileReadCorruptFile) }
        
        self.init(name: name,
                  settings: Settings(dictionary: settingsJson),
                  replacements: replacementsJson.flatMap { Replacement(dictionary: $0) })
    }
    
    
    convenience init(url: URL) throws {
        
        // load JSON data
        let data = try Data(contentsOf: url)
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        
        guard let json = jsonObject as? [String: Any] else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let name = url.deletingPathExtension().lastPathComponent
        
        try self.init(name: name, dictionary: json)
    }
    
}



extension Replacement {
    
    enum Key {
        
        static let findString = "findString"
        static let replacementString = "replacementString"
        static let usesRegularExpression = "usesRegularExpression"
        static let ignoresCase = "ignoresCase"
        static let enabled = "enabled"
        static let description = "description"
    }
    
    
    convenience init?(dictionary: [String: Any]) {
        
        guard
            let findString = dictionary[Key.findString] as? String, !findString.isEmpty,
            let replacementString = dictionary[Key.replacementString] as? String
            else { return nil }
        
        self.init(findString: findString,
                  replacementString: replacementString,
                  usesRegularExpression: (dictionary[Key.usesRegularExpression] as? Bool) ?? false,
                  ignoresCase: (dictionary[Key.ignoresCase] as? Bool) ?? false,
                  comment: dictionary[Key.description] as? String,
                  enabled: dictionary[Key.enabled] as? Bool
        )
    }
    
}



extension BatchReplacement.Settings {
    
    enum Key {
        
        static let textualOptions = "textualOptions"
        static let regexOptions = "regexOptions"
        static let unescapesReplacementString = "unescapesReplacementString"
    }
    
    
    init(dictionary: [String: Any]) {
        
        self = BatchReplacement.Settings()
        
        if let rawValue = dictionary[Key.textualOptions] as? UInt {
            self.textualOptions = NSString.CompareOptions(rawValue: rawValue)
        }
        if let rawValue = dictionary[Key.regexOptions] as? UInt {
            self.regexOptions = NSRegularExpression.Options(rawValue: rawValue)
        }
        if let rawValue = dictionary[Key.unescapesReplacementString] as? Bool {
            self.unescapesReplacementString = rawValue
        }
    }
    
}
