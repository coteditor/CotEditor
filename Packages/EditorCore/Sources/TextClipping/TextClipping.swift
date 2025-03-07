//
//  TextClipping.swift
//  TextClipping
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-02-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2025 1024jp
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

public struct TextClipping: Equatable, Sendable, Decodable {
    
    public static let pathExtension = "textClipping"
    
    public var string: String
    
    
    enum CodingKeys: String, CodingKey {
        
        case string = "public.utf8-plain-text"
    }
    
    
    public init(contentsOf url: URL) throws {
        
        let data = try Data(contentsOf: url)
        let plist = try PropertyListDecoder().decode([String: TextClipping].self, from: data)
        
        guard let textClipping = plist["UTI-Data"] else { throw CocoaError.error(.coderReadCorrupt, url: url) }
        
        self = textClipping
    }
}
