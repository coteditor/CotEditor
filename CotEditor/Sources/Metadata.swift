//
//  Metadata.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-23.
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

import Foundation.NSObject

enum DictionaryKey: String {
    
    case metadata
}


/// Metadata dict keys for themes and syntax styles
typealias MetadataKey = Metadata.CodingKeys


final class Metadata: NSObject, Codable {
    
    @objc dynamic var author: String?
    @objc dynamic var distributionURL: String?
    @objc dynamic var license: String?
    @objc dynamic var comment: String?
    
    
    var isEmpty: Bool {
        
        return self.author == nil && self.distributionURL == nil && self.license == nil && self.comment == nil
    }
    
    
    enum CodingKeys: String, CodingKey {
        
        case author
        case distributionURL
        case license
        case comment = "description"  // `description` conflicts with NSObject's method.
    }
}
