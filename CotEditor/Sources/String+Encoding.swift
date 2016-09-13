/*
 
 String+Encodings.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-16.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

private extension UTF8 {
    
    static var bom: [UInt8] { return [0xEF, 0xBB, 0xBF] }
}


private extension UTF16 {
    
    static var beBom: [UInt8] { return [0xFE, 0xFF] }
    static var leBom: [UInt8] { return [0xFF, 0xFE] }
}


private extension UTF32 {
    
    static var beBom: [UInt8] { return [0x00, 0x00, 0xFE, 0xFF] }
    static var leBom: [UInt8] { return [0xFF, 0xFE, 0x00, 0x00] }
}


private let ISO2022JP_EscapeSequences: [[UInt8]] = [
    [0x1B, 0x28, 0x42],  // ASCII
    [0x1B, 0x28, 0x49],  // kana
    [0x1B, 0x24, 0x40],  // 1978
    [0x1B, 0x24, 0x42],  // 1983
    [0x1B, 0x24, 0x28, 0x44],  // JISX0212
]


private let MaxDetectionLength = 1024 * 8



// MARK:

private extension CFStringEncoding {
    
    static let shiftJIS = CFStringEncoding(CFStringEncodings.shiftJIS.rawValue)
    static let shiftJIS_X0213 = CFStringEncoding(CFStringEncodings.shiftJIS_X0213.rawValue)
}



extension String.Encoding {
    
    private static let shiftJIS = String.Encoding(cfEncodings: .shiftJIS)
    private static let shiftJIS_X0213 = String.Encoding(cfEncodings: .shiftJIS_X0213)
    
    
    init(cfEncodings: CFStringEncodings) {
        
        self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncodings.rawValue)))
    }
    
    
    init(cfEncoding: CFStringEncoding) {
        
        self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
    }
    
    
    
    // MARK: Public Methods
    
    /// check IANA charset compatibility considering SHIFT_JIS
    func isCompatible(ianaCharSetEncoding encoding: String.Encoding) -> Bool {
        
        if encoding == self { return true }
        
        // -> Caution needed on Shift-JIS. See `scanEncodingDeclaration(forTags:upTo:suggestedCFEncodings:)` for details.
        return (encoding == .shiftJIS && self == .shiftJIS_X0213) || (encoding == .shiftJIS_X0213 && self == .shiftJIS)
    }
    
    
    /// whether receiver can convert Yen sign (U+00A5)
    var canConvertYenSign: Bool {
        
        return "¥".canBeConverted(to: self)
    }
    
    
    /// IANA charset name for the encoding
    var ianaCharSetName: String? {
        
        let cfEncoding = CFStringConvertNSStringEncodingToEncoding(self.rawValue)
        
        return CFStringConvertEncodingToIANACharSetName(cfEncoding) as String?
    }
    
}



extension String {
    
    /// obtain string from Data with intelligent encoding detection
    init(data: Data, suggestedCFEncodings: [CFStringEncoding], usedEncoding: inout String.Encoding?) throws {
        
        // detect encoding from so-called "magic numbers"
        if !data.isEmpty {
            // check UTF-8 BOM
            if data.starts(with: UTF8.bom) {
                if let string = String(data: data, encoding: .utf8) {
                    usedEncoding = .utf8
                    self = string
                    return
                }
                
            // check UTF-32 BOM
            } else if data.starts(with: UTF32.beBom) || data.starts(with: UTF32.leBom) {
                if let string = String(data: data, encoding: .utf32) {
                    usedEncoding = .utf32
                    self = string
                    return
                }
                
            // check UTF-32 BOM
            } else if data.starts(with: UTF16.beBom) || data.starts(with: UTF16.leBom) {
                if let string = String(data: data, encoding: .utf16) {
                    usedEncoding = .utf16
                    self = string
                    return
                }
            }
            
            // text ISO-2022-JP
            if data.prefix(MaxDetectionLength).contains(0x1B) {
                // check existance of typical escape sequences
                // -> It's not perfect yet works in most cases. (2016-01 by 1024p)
                for escapeSequence in ISO2022JP_EscapeSequences {
                    let escapeSequenceData = Data(bytes: escapeSequence)
                    if data.range(of: escapeSequenceData) != nil {
                        if let string = String(data: data, encoding: .iso2022JP) {
                            usedEncoding = .iso2022JP
                            self = string
                            return
                        }
                    }
                }
            }
        }
        
        // try encodings in order from the top of the encoding list
        for cfEncoding: CFStringEncoding in suggestedCFEncodings {
            guard cfEncoding != kCFStringEncodingInvalidId else { continue }
            
            let encoding = String.Encoding(cfEncoding: cfEncoding)
            
            if let string = String(data: data, encoding: encoding) {
                usedEncoding = encoding
                self = string
                return
            }
        }
        
        throw CocoaError(.fileReadUnknownStringEncoding)
    }
    
    
    
    // MARK: Public Methods
    
    /// human-readable encoding name considering UTF-8 BOM
    static func localizedName(of encoding: String.Encoding, withUTF8BOM: Bool) -> String {
        
        if encoding == .utf8 && withUTF8BOM {
            return self.localizedNameOfUTF8EncodingWithBOM
        }
        
        return self.localizedName(of: encoding)
    }
    
    
    /// human-readable encoding name for UTF-8 with BOM
    static var localizedNameOfUTF8EncodingWithBOM: String {
        
        return String(format: NSLocalizedString("%@ with BOM", comment: "Unicode (UTF-8) with BOM"),
                      String.localizedName(of: .utf8))
    }

    
    /// scan encoding declaration in string
    func scanEncodingDeclaration(forTags tags: [String], upTo maxLength: Int, suggestedCFEncodings: [UInt32]) -> String.Encoding? {
        
        guard !self.isEmpty else { return nil }
        
        // This method is based on Smultron's SMLTextPerformer.m by Peter Borg. (2005-08-10)
        // Smultron 2 was distributed on <http://smultron.sourceforge.net> under the terms of the BSD license.
        // Copyright (c) 2004-2006 Peter Borg
        
        let scanIndex = self.index(self.startIndex, offsetBy: maxLength, limitedBy: self.endIndex) ?? self.endIndex
        
        let stringToScan = self.substring(to: scanIndex)
        let scanner = Scanner(string: stringToScan)  // scan only the beginning of string
        let stopSet = CharacterSet(charactersIn: "\"\' </>\n\r")
        var scannedString: NSString?
        
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "\"\' ")
        
        // find encoding with tag in order
        for tag in tags {
            scanner.scanLocation = 0
            
            while !scanner.isAtEnd {
                scanner.scanUpTo(tag, into: nil)
                if scanner.scanString(tag, into: nil),
                    scanner.scanUpToCharacters(from: stopSet, into: &scannedString) {
                    break
                }
            }
            if scannedString != nil { break }
        }
        
        guard let ianaCharSetName = scannedString else { return nil }
        
        // convert IANA CharSet name to CFStringEncoding
        guard let cfEncoding: CFStringEncoding = {
            //　simply convert expect for "Shift_JIS"
            if ianaCharSetName.uppercased != "SHIFT_JIS" {
                return CFStringConvertIANACharSetNameToEncoding(ianaCharSetName)
            }
            
            // "Shift_JIS" だったら、.shiftJIS と .shiftJIS_X0213 の優先順位の高いものを取得する
            //   -> scannedString をそのまま CFStringConvertIANACharSetNameToEncoding() で変換すると、大文字小文字を問わず
            //     「日本語（Shift JIS）」になってしまうため。IANA では大文字小文字を区別しないとしているのでこれはいいのだが、
            //      CFStringConvertEncodingToIANACharSetName() では .shiftJIS と .shiftJIS_X0213 がそれぞれ
            //     「SHIFT_JIS」「shift_JIS」と変換されるため、可逆性を持たせるための処理
            return suggestedCFEncodings.first { $0 == .shiftJIS || $0 == .shiftJIS_X0213 }
            
            }(), cfEncoding != kCFStringEncodingInvalidId else { return nil }
        
        return String.Encoding(cfEncoding: cfEncoding)
    }
    
    
    /// convert Yen sign in consideration of the encoding
    func convertingYenSign(for encoding: String.Encoding) -> String {
        
        guard !self.isEmpty && !encoding.canConvertYenSign else { return String(self) }
        
        // replace Yen signs to backslashs if encoding cannot convert Yen sign
        return self.replacingOccurrences(of: "¥", with: "\\")
    }
    
}



// MARK: - Xattr Encoding

extension Data {
    
    /// decode `com.apple.TextEncoding` extended file attribute to encoding
    var decodingXattrEncoding: String.Encoding? {
        
        // parse value
        guard let string = String(data: self, encoding: .utf8) else { return nil }
        
        let components = string.components(separatedBy: ";")
        let cfEncoding: UInt32? = {
            if let cfEncodingNumber = components[safe: 1] {
                return UInt32(cfEncodingNumber)
            }
            if let ianaCharSetName = components[safe: 0] {
                return CFStringConvertIANACharSetNameToEncoding(ianaCharSetName as CFString)
            }
            return nil
        }()
        
        guard let unwrappedCFEncoding = cfEncoding, cfEncoding != kCFStringEncodingInvalidId else { return nil }
        
        return String.Encoding(cfEncoding: CFStringEncoding(unwrappedCFEncoding))
    }
    
}


extension String.Encoding {
    
    /// encode encoding to data for `com.apple.TextEncoding` extended file attribute
    var xattrEncodingData: Data? {
        
        let cfEncoding = CFStringConvertNSStringEncodingToEncoding(self.rawValue)
        
        guard cfEncoding != kCFStringEncodingInvalidId else { return nil }
        
        let ianaCharSetName = CFStringConvertEncodingToIANACharSetName(cfEncoding) as String
        let string = String(format:"%@;%u", ianaCharSetName, cfEncoding)
        
        return string.data(using: .utf8)
    }
    
}



// MARK: - UTF8

extension Data {
    
    // MARK: Public Methods
    
    /// return Data by adding UTF-8 BOM
    var addingUTF8BOM: Data {
        
        return Data(bytes: UTF8.bom) + self
    }
    
    
    /// check if data starts with UTF-8 BOM
    var hasUTF8BOM: Bool {
        
        return self.starts(with: UTF8.bom)
    }
    
}
