//
//  Version+Codable.swift
//  SemanticVersioning
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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

extension Version: Codable {
    
    public init(from decoder: any Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        guard let version = Version(string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported version expression")
        }
        
        self = version
    }
    
    
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        try container.encode(self.formatted())
    }
}
