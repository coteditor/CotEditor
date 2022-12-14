//
//  String+Encodings.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2022 1024jp
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

extension Unicode {
    
    /// Byte order mark.
    enum BOM: CaseIterable {
        
        case utf8
        case utf32BigEndian
        case utf32LittleEndian
        case utf16BigEndian
        case utf16LittleEndian
        
        
        var sequence: [UInt8] {
            
            switch self {
                case .utf8: return [0xEF, 0xBB, 0xBF]
                case .utf32BigEndian: return [0x00, 0x00, 0xFE, 0xFF]
                case .utf32LittleEndian: return [0xFF, 0xFE, 0x00, 0x00]
                case .utf16BigEndian: return [0xFE, 0xFF]
                case .utf16LittleEndian: return [0xFF, 0xFE]
            }
        }
        
        
        var encoding: String.Encoding {
            
            switch self {
                case .utf8:
                    return .utf8
                case .utf32BigEndian, .utf32LittleEndian:
                    return .utf32
                case .utf16BigEndian, .utf16LittleEndian:
                    return .utf16
            }
        }
    }
}



// MARK: -

private extension CFStringEncoding {
    
    static let shiftJIS = CFStringEncoding(CFStringEncodings.shiftJIS.rawValue)
    static let shiftJIS_X0213 = CFStringEncoding(CFStringEncodings.shiftJIS_X0213.rawValue)
}



extension String.Encoding {
    
    init(cfEncodings: CFStringEncodings) {
        
        self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncodings.rawValue)))
    }
    
    
    init(cfEncoding: CFStringEncoding) {
        
        self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
    }
    
    
    
    // MARK: Public Methods
    
    var cfEncoding: CFStringEncoding {
        
        CFStringConvertNSStringEncodingToEncoding(self.rawValue)
    }
    
    
    /// whether receiver can convert Yen sign (U+00A5)
    var canConvertYenSign: Bool {
        
        "¥".canBeConverted(to: self)
    }
    
    
    /// IANA charset name for the encoding
    var ianaCharSetName: String? {
        
        CFStringConvertEncodingToIANACharSetName(self.cfEncoding) as String?
    }
}



extension String {
    
    /// An array of the encodings that strings support in the application’s environment. `nil` for section divider.
    static let sortedAvailableStringEncodings: [String.Encoding?] = Self.availableStringEncodings
        .sorted {
            String.localizedName(of: $0).localizedCaseInsensitiveCompare(String.localizedName(of: $1)) == .orderedAscending
        }
        .reduce(into: []) { (encodings, encoding) in
            if let last = encodings.last as? String.Encoding,
               let nameRangeLast = String.localizedName(of: last).range(of: "^\\w+", options: .regularExpression),
               let nameRange = String.localizedName(of: encoding).range(of: "^\\w+", options: .regularExpression),
               String.localizedName(of: last)[nameRangeLast] != String.localizedName(of: encoding)[nameRange]
            {
                encodings.append(nil)
            }
            encodings.append(encoding)
        }
    
    
    /// decode data and remove UTF-8 BOM if exists
    ///
    /// cf. <https://bugs.swift.org/browse/SR-10173>
    init?(bomCapableData data: Data, encoding: String.Encoding) {
        
        let bom = Unicode.BOM.utf8.sequence
        let hasUTF8WithBOM = (encoding == .utf8 && data.starts(with: bom))
        let bomFreeData = hasUTF8WithBOM ? data[bom.count...] : data
        
        self.init(data: bomFreeData, encoding: encoding)
    }
    
    
    /// obtain string from Data with intelligent encoding detection
    init(data: Data, suggestedCFEncodings: [CFStringEncoding], usedEncoding: inout String.Encoding?) throws {
        
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
        for cfEncoding in suggestedCFEncodings {
            let encoding = String.Encoding(cfEncoding: cfEncoding)
            guard
                let string = String(data: data, encoding: encoding)
            else { continue }
            
            usedEncoding = encoding
            self = string
            return
        }
        
        throw CocoaError(.fileReadUnknownStringEncoding)
    }
    
    
    
    // MARK: Public Methods
    
    /// scan encoding declaration in string
    func scanEncodingDeclaration(upTo maxLength: Int, suggestedCFEncodings: [CFStringEncoding]) -> String.Encoding? {
        
        guard !self.isEmpty else { return nil }
        
        let tags = ["charset=", "encoding=", "@charset", "encoding:", "coding:"]
        let pattern = "\\b(?:" + tags.joined(separator: "|") + ") *[\"']? *([-_a-zA-Z0-9]+)"
        let regex = try! NSRegularExpression(pattern: pattern)
        let scanLength = min(self.length, maxLength)
        
        guard
            let match = regex.firstMatch(in: self, range: NSRange(location: 0, length: scanLength)),
            let matchedRange = Range(match.range(at: 1), in: self)
        else { return nil }
        
        let ianaCharSetName = self[matchedRange]
        
        // convert IANA CharSet name to CFStringEncoding
        let cfEncoding: CFStringEncoding = {
            // pick user's preferred one for "Shift_JIS"
            // -> CFStringConvertIANACharSetNameToEncoding() converts "SHIFT_JIS" to .shiftJIS regardless of the letter case.
            //    Although this behavior is theoretically correct since IANA is case insensitive,
            //    we treat them with care by respecting the user's priority.
            //    FYI: CFStringConvertEncodingToIANACharSetName() converts .shiftJIS and .shiftJIS_X0213
            //         to "shift_jis" and "Shift_JIS" respectively.
            if ianaCharSetName.uppercased() == "SHIFT_JIS",
               let cfEncoding = suggestedCFEncodings.first(where: { $0 == .shiftJIS || $0 == .shiftJIS_X0213 })
            {
                return cfEncoding
            }
            
            return CFStringConvertIANACharSetNameToEncoding(ianaCharSetName as CFString)
        }()
        
        guard cfEncoding != kCFStringEncodingInvalidId else { return nil }
        
        return String.Encoding(cfEncoding: cfEncoding)
    }
    
    
    /// convert Yen sign in consideration of the encoding
    func convertingYenSign(for encoding: String.Encoding) -> String {
        
        guard !self.isEmpty, !encoding.canConvertYenSign else {
            return self
        }
        
        // replace Yen signs to backslashs if encoding cannot convert Yen sign
        return self.replacingOccurrences(of: "¥", with: "\\")
    }
}



// MARK: - Xattr Encoding

extension Data {
    
    /// decode `com.apple.TextEncoding` extended file attribute to encoding
    var decodingXattrEncoding: String.Encoding? {
        
        guard let string = String(data: self, encoding: .ascii) else { return nil }
        
        let components = string.components(separatedBy: ";")
        
        guard
            let cfEncoding: CFStringEncoding = {
                if let cfEncodingNumber = components[safe: 1] {
                    return UInt32(cfEncodingNumber)
                }
                if let ianaCharSetName = components[safe: 0] {
                    return CFStringConvertIANACharSetNameToEncoding(ianaCharSetName as CFString)
                }
                return nil
            }(),
            cfEncoding != kCFStringEncodingInvalidId
        else { return nil }
        
        return String.Encoding(cfEncoding: cfEncoding)
    }
}


extension String.Encoding {
    
    /// encode encoding to data for `com.apple.TextEncoding` extended file attribute
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
