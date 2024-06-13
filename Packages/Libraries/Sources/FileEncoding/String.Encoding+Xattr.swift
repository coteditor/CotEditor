//
//  String.Encoding+Xattr.swift
//  FileEncoding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2024 1024jp
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
    
    /// Encodes encoding to data for `com.apple.TextEncoding` extended file attribute.
    var xattrEncodingData: Data? {
        
        let cfEncoding = CFStringConvertNSStringEncodingToEncoding(self.rawValue)
        
        guard
            cfEncoding != kCFStringEncodingInvalidId,
            let ianaCharSetName = CFStringConvertEncodingToIANACharSetName(cfEncoding)
        else { return nil }
        
        let string = String(format: "%@;%u", ianaCharSetName as String, cfEncoding)
        
        return string.data(using: .ascii)
    }
}


public extension Data {
    
    /// Decodes `com.apple.TextEncoding` extended file attribute to encoding.
    var decodingXattrEncoding: String.Encoding? {
        
        guard let string = String(data: self, encoding: .ascii) else { return nil }
        
        let components = string.split(separator: ";")
        
        guard
            let cfEncoding: CFStringEncoding = if components.count >= 2 {
                UInt32(components[1])
            } else if let ianaCharSetName = components.first {
                CFStringConvertIANACharSetNameToEncoding(ianaCharSetName as CFString)
            } else {
                nil
            },
        cfEncoding != kCFStringEncodingInvalidId
        else { return nil }
        
        return String.Encoding(cfEncoding: cfEncoding)
    }
}
