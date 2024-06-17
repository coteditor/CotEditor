//
//  String.Encodings.swift
//  FileEncoding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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

public extension String.Encoding {
    
    init(cfEncoding: CFStringEncoding) {
        
        self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
    }
    
    
    /// The name of the IANA registry “charset” that is the closest mapping to the encoding.
    var ianaCharSetName: String? {
        
        let cfEncoding = CFStringConvertNSStringEncodingToEncoding(self.rawValue)
        
        return CFStringConvertEncodingToIANACharSetName(cfEncoding) as String?
    }
}
