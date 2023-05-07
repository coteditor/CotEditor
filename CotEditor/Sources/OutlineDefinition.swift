//
//  OutlineDefinition.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-05-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2023 1024jp
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

struct OutlineDefinition: Equatable {
    
    enum `Error`: Swift.Error {
        
        case invalidFormat
    }
    
    
    var pattern: String = ""
    var template: String = ""
    var ignoreCase: Bool = false
    var bold: Bool = false
    var italic: Bool = false
    var underline: Bool = false
    
    var description: String?
    
    
    private enum CodingKeys: String, CodingKey {
        
        case pattern = "beginString"
        case template = "keyString"
        case ignoreCase
        case bold
        case italic
        case underline
        case description
    }
    
    
    
    init(dictionary: [String: Any]) throws {
        
        guard let pattern = dictionary[CodingKeys.pattern] as? String else { throw Error.invalidFormat }
        
        self.pattern = pattern
        self.template = dictionary[CodingKeys.template] as? String ?? ""
        self.ignoreCase = dictionary[CodingKeys.ignoreCase] as? Bool ?? false
        self.bold = dictionary[CodingKeys.bold] as? Bool ?? false
        self.italic = dictionary[CodingKeys.italic] as? Bool ?? false
        self.underline = dictionary[CodingKeys.underline] as? Bool ?? false
    }
}
