//
//  String+Encodings.swift
//  FileEncoding
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
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



public extension String {
    
    /// An array of the encodings that strings support in the application’s environment. `nil` for section divider.
    static let sortedAvailableStringEncodings: [String.Encoding?] = Self.availableStringEncodings
        .sorted {
            String.localizedName(of: $0).localizedCaseInsensitiveCompare(String.localizedName(of: $1)) == .orderedAscending
        }
        .reduce(into: []) { (encodings, encoding) in
            if let last = encodings.last as? String.Encoding,
               let lastName = String.localizedName(of: last).prefixMatch(of: /\w+/),
               let name = String.localizedName(of: encoding).prefixMatch(of: /\w+/),
               lastName.output != name.output
            {
                encodings.append(nil)
            }
            encodings.append(encoding)
        }
    
    
    /// Decodes data and remove UTF-8 BOM if exists.
    ///
    /// cf. <https://bugs.swift.org/browse/SR-10173>
    init?(bomCapableData data: Data, encoding: String.Encoding) {
        
        let bom = Unicode.BOM.utf8.sequence
        let hasUTF8WithBOM = (encoding == .utf8 && data.starts(with: bom))
        let bomFreeData = hasUTF8WithBOM ? data[bom.count...] : data
        
        self.init(data: bomFreeData, encoding: encoding)
    }
    
    
    /// Returns a  `String` initialized by converting given `data` into Unicode characters using an intelligent encoding detection.
    ///
    /// - Parameters:
    ///   - data: The data object containing the string data.
    ///   - suggestedEncodings: The prioritized list of encoding candidates.
    ///   - usedEncoding: The encoding used to interpret the data.
    /// - Throws: `CocoaError(.fileReadUnknownStringEncoding)`
    init(data: Data, suggestedEncodings: [String.Encoding], usedEncoding: inout String.Encoding?) throws(CocoaError) {
        
        // detect encoding from so-called "magic numbers"
        for bom in Unicode.BOM.allCases {
            guard
                data.starts(with: bom.sequence),
                let string = String(bomCapableData: data, encoding: bom.encoding)
            else { continue }
            
            usedEncoding = bom.encoding
            self = string
            return
        }
        
        // try encodings in order from the top of the encoding list
        for encoding in suggestedEncodings {
            guard let string = String(data: data, encoding: encoding) else { continue }
            
            usedEncoding = encoding
            self = string
            return
        }
        
        throw CocoaError(.fileReadUnknownStringEncoding)
    }
    
    
    /// Scans an possible encoding declaration in the string.
    ///
    /// - Parameters:
    ///   - maxLength: The number of forward characters to be scanned.
    /// - Returns: A string encoding, or `nil` if not found.
    func scanEncodingDeclaration(upTo maxLength: Int) -> String.Encoding? {
        
        assert(maxLength > 0)
        
        guard !self.isEmpty else { return nil }
        
        let regex = /\b(charset=|encoding=|@charset|encoding:|coding:) *["']? *(?<encoding>[-_a-zA-Z0-9]+)/
            .wordBoundaryKind(.simple)
        
        guard let ianaCharSetName = try? regex.firstMatch(in: self.prefix(maxLength))?.encoding else { return nil }
        
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(ianaCharSetName as CFString)
        
        guard cfEncoding != kCFStringEncodingInvalidId else { return nil }
        
        return String.Encoding(cfEncoding: cfEncoding)
    }
    
    
    /// Converts Yen signs (`U+00A5`) in consideration of the encoding.
    ///
    /// - Parameter encoding: The text encoding to keep compatibility.
    /// - Returns: A new string converted all Yen signs.
    func convertYenSign(for encoding: String.Encoding) -> String {
        
        "¥".canBeConverted(to: encoding) ? self : self.replacing("¥", with: "\\")
    }
}
