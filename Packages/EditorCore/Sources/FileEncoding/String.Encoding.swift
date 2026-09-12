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
//  © 2014-2026 1024jp
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

public import Foundation

public extension String.Encoding {
    
    /// Initializes String.Encoding from an encoding name.
    ///
    /// - Note: Concurrent calls can crash in Foundation's localized encoding name lookup.
    ///         Call this initializer serially.
    ///
    /// - Parameter localizedName: The localized name of the encoding to find.
    init?(localizedName: String) {
        
        guard
            let encoding = String.availableStringEncodings.lazy
                .first(where: { String.localizedName(of: $0) == localizedName })
        else { return nil }
        
        self = encoding
    }
    
    
    /// Initializes corresponding String.Encoding from an IANA charset name.
    ///
    /// - Parameter ianaCharSetName: The IANA charset name of the encoding to find.
    init?(ianaCharSetName: String) {
        
        guard
            let encoding = String.availableStringEncodings.lazy
                .first(where: { $0.ianaCharSetName?.caseInsensitiveCompare(ianaCharSetName) == .orderedSame })
            else { return nil }
        
        self = encoding
    }
    
    
    /// Initializes String.Encoding most closely to a given Core Foundation encoding constant.
    ///
    /// - Parameter cfEncoding: The Core Foundation encoding constant.
    init(cfEncoding: CFStringEncoding) {
        
        self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
    }
    
    
    /// The `CFStringEncoding` constant that is the closest mapping to the receiver.
    var cfEncoding: CFStringEncoding {
        
        CFStringConvertNSStringEncodingToEncoding(self.rawValue)
    }
    
    
    /// The name of the IANA registry “charset” that is the closest mapping to the encoding.
    var ianaCharSetName: String? {
        
        CFStringConvertEncodingToIANACharSetName(self.cfEncoding) as String?
    }
    
    
    /// Whether the encoding is a Unicode encoding.
    var isUnicodeEncoding: Bool {
        
        switch self {
            case .utf8, .utf16, .utf16BigEndian, .utf16LittleEndian, .utf32, .utf32BigEndian, .utf32LittleEndian:
                true
            default:
                false
        }
    }
}
