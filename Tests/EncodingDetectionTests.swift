//
//  EncodingDetectionTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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
import Testing
@testable import CotEditor

final class EncodingDetectionTests {
    
    @Test func utf8BOM() throws {
        
        // -> String(data:encoding:) preserves BOM since Swift 5 (2019-03)
        //    cf. https://bugs.swift.org/browse/SR-10173
        let data = try self.dataForFileName("UTF-8 BOM")
        #expect(String(decoding: data, as: UTF8.self) == "\u{FEFF}0")
        #expect(String(bomCapableData: data, encoding: .utf8) == "0")
        
        var encoding: String.Encoding?
        let string = try self.encodedStringForFileName("UTF-8 BOM", usedEncoding: &encoding)
        
        #expect(string == "0")
        #expect(encoding == .utf8)
        
        #expect(String(bomCapableData: Data(Unicode.BOM.utf8.sequence), encoding: .utf8)?.isEmpty == true)
        #expect(String(bomCapableData: Data(), encoding: .utf8)?.isEmpty == true)
    }
    
    
    @Test func utf16() throws {
        
        var encoding: String.Encoding?
        let string = try self.encodedStringForFileName("UTF-16", usedEncoding: &encoding)
        
        #expect(string == "0")
        #expect(encoding == .utf16)
    }
    
    
    @Test func utf32() throws {
        
        var encoding: String.Encoding?
        let string = try self.encodedStringForFileName("UTF-32", usedEncoding: &encoding)
        
        #expect(string == "0")
        #expect(encoding == .utf32)
    }
    
    
    @Test func iso2022() throws {
        
        let data = try self.dataForFileName("ISO 2022-JP")
        let encodings: [String.Encoding] = [.iso2022JP, .utf16]
        
        var encoding: String.Encoding?
        let string = try String(data: data, suggestedEncodings: encodings, usedEncoding: &encoding)
        
        #expect(string == "dog犬")
        #expect(encoding == .iso2022JP)
    }
    
    
    @Test func utf8() throws {
        
        let data = try self.dataForFileName("UTF-8")
        
        var encoding: String.Encoding?
        #expect(throws: CocoaError(.fileReadUnknownStringEncoding)) {
            try String(data: data, suggestedEncodings: [], usedEncoding: &encoding)
        }
        #expect(encoding == nil)
    }
    
    
    @Test func suggestedEncoding() throws {
        
        let data = try self.dataForFileName("UTF-8")
        
        var encoding: String.Encoding?
        let invalidEncoding = String.Encoding(cfEncoding: kCFStringEncodingInvalidId)
        let string = try String(data: data, suggestedEncodings: [invalidEncoding, .utf8], usedEncoding: &encoding)
        
        #expect(string == "0")
        #expect(encoding == .utf8)
    }
    
    
    @Test func emptyData() {
        
        let data = Data()
        
        var encoding: String.Encoding?
        var string: String?
        
        #expect(throws: CocoaError(.fileReadUnknownStringEncoding)) {
            string = try String(data: data, suggestedEncodings: [], usedEncoding: &encoding)
        }
        
        #expect(string == nil)
        #expect(encoding == nil)
        #expect(!data.starts(with: Unicode.BOM.utf8.sequence))
    }
    
    
    @Test func utf8BOMData() throws {
        
        let withBOMData = try self.dataForFileName("UTF-8 BOM")
        #expect(withBOMData.starts(with: Unicode.BOM.utf8.sequence))
        
        let data = try self.dataForFileName("UTF-8")
        #expect(!data.starts(with: Unicode.BOM.utf8.sequence))
    }
    
    
    @Test func scanEncodingDeclaration() throws {
        
        let string = "<meta charset=\"Shift_JIS\"/>"
        #expect(string.scanEncodingDeclaration(upTo: 16) == nil)
        #expect(string.scanEncodingDeclaration(upTo: 128) == String.Encoding(cfEncodings: .shiftJIS))
        
        #expect("<meta charset=\"utf-8\"/>".scanEncodingDeclaration(upTo: 128) == .utf8)
        
        // Swift.Regex with non-simple word boundaries never returns when the given string contains a specific pattern of letters (2023-12 on Swift 5.9).
        #expect("ﾀﾏｺﾞ,1,".scanEncodingDeclaration(upTo: 128) == nil)
        #expect(try /\ba/.wordBoundaryKind(.simple).firstMatch(in: "ﾀﾏｺﾞ,1,") == nil)
    }
    
    
    @Test func initializeEncoding() {
        
        #expect(String.Encoding(cfEncodings: CFStringEncodings.dosJapanese) == .shiftJIS)
        #expect(String.Encoding(cfEncodings: CFStringEncodings.shiftJIS) != .shiftJIS)
        #expect(String.Encoding(cfEncodings: CFStringEncodings.shiftJIS_X0213) != .shiftJIS)
        
        #expect(String.Encoding(cfEncoding: CFStringEncoding(CFStringEncodings.dosJapanese.rawValue)) == .shiftJIS)
        #expect(String.Encoding(cfEncoding: CFStringEncoding(CFStringEncodings.shiftJIS.rawValue)) != .shiftJIS)
        #expect(String.Encoding(cfEncoding: CFStringEncoding(CFStringEncodings.shiftJIS_X0213.rawValue)) != .shiftJIS)
    }
    
    
    /// Makes sure the behaviors around Shift-JIS.
    @Test func shiftJIS() {
        
        let shiftJIS = CFStringEncoding(CFStringEncodings.shiftJIS.rawValue)
        let shiftJIS_X0213 = CFStringEncoding(CFStringEncodings.shiftJIS_X0213.rawValue)
        let dosJapanese = CFStringEncoding(CFStringEncodings.dosJapanese.rawValue)
        
        // IANA charset name conversion
        // CFStringEncoding -> IANA charset name
        #expect(CFStringConvertEncodingToIANACharSetName(shiftJIS) as String == "shift_jis")
        #expect(CFStringConvertEncodingToIANACharSetName(shiftJIS_X0213) as String == "Shift_JIS")
        
        #expect(CFStringConvertEncodingToIANACharSetName(dosJapanese) as String == "cp932")
        // IANA charset name -> CFStringEncoding
        #expect(CFStringConvertIANACharSetNameToEncoding("SHIFT_JIS" as CFString) == shiftJIS)
        #expect(CFStringConvertIANACharSetNameToEncoding("shift_jis" as CFString) == shiftJIS)
        #expect(CFStringConvertIANACharSetNameToEncoding("cp932" as CFString) == dosJapanese)
        #expect(CFStringConvertIANACharSetNameToEncoding("sjis" as CFString) == dosJapanese)
        #expect(CFStringConvertIANACharSetNameToEncoding("shiftjis" as CFString) == dosJapanese)
        #expect(CFStringConvertIANACharSetNameToEncoding("shift_jis" as CFString) != shiftJIS_X0213)
        
        // `String.Encoding.shiftJIS` is "Japanese (Windows, DOS)."
        #expect(CFStringConvertNSStringEncodingToEncoding(String.Encoding.shiftJIS.rawValue) == dosJapanese)
    }
    
    
    @Test func encodeXattr() {
        
        let utf8Data = Data("utf-8;134217984".utf8)
        
        #expect(String.Encoding.utf8.xattrEncodingData == utf8Data)
        #expect(utf8Data.decodingXattrEncoding == .utf8)
        #expect(Data("utf-8".utf8).decodingXattrEncoding == .utf8)
        
        
        let eucJPData = Data("euc-jp;2336".utf8)
        
        #expect(String.Encoding.japaneseEUC.xattrEncodingData == eucJPData)
        #expect(eucJPData.decodingXattrEncoding == .japaneseEUC)
        #expect(Data("euc-jp".utf8).decodingXattrEncoding == .japaneseEUC)
    }
    
    
    @Test func convertYen() {
        
        #expect("¥".canBeConverted(to: .utf8))
        #expect("¥".canBeConverted(to: String.Encoding(cfEncodings: .shiftJIS)))
        #expect(!"¥".canBeConverted(to: .shiftJIS))
        #expect(!"¥".canBeConverted(to: .japaneseEUC))  // ? (U+003F)
        #expect(!"¥".canBeConverted(to: .ascii))  // Y (U+0059)
        
        let string = "\\ ¥ yen"
        #expect(string.convertYenSign(for: .utf8) == string)
        #expect(string.convertYenSign(for: String.Encoding(cfEncodings: .shiftJIS)) == string)
        #expect(string.convertYenSign(for: .shiftJIS) == "\\ \\ yen")
        #expect(string.convertYenSign(for: .japaneseEUC) == "\\ \\ yen")
        #expect(string.convertYenSign(for: .ascii) == "\\ \\ yen")
    }
    
    
    @Test func ianaCharsetName() {
        
        #expect(String.Encoding.utf8.ianaCharSetName == "utf-8")
        #expect(String.Encoding.isoLatin1.ianaCharSetName == "iso-8859-1")
    }
    
    
    @Test func encodeYen() throws {
        
        // encodings listed in faq_about_yen_backslash.html
        let ascii = try #require(CFStringEncodings(rawValue: CFIndex(CFStringBuiltInEncodings.ASCII.rawValue)))
        let inHelpCFEncodings: [CFStringEncodings] = [
            .dosJapanese,
            .EUC_JP,              // Japanese (EUC)
            .EUC_TW,              // Traditional Chinese (EUC)
            .EUC_CN,              // Simplified Chinese (GB 2312)
            .EUC_KR,              // Korean (EUC)
            .dosKorean,           // Korean (Windows, DOS)
            .dosThai,             // Thai (Windows, DOS)
            .isoLatinThai,        // Thai (ISO 8859-11)
            
            .macArabic,           // Arabic (Mac OS)
            .isoLatinArabic,      // Arabic (ISO 8859-6)
            .macHebrew,           // Hebrew (Mac OS)
            .isoLatinGreek,       // Greek (ISO 8859-7)
            .macCyrillic,         // Cyrillic (Mac OS)
            .isoLatinCyrillic,    // Cyrillic (ISO 8859-5)
            .windowsCyrillic,     // Cyrillic (Windows)
            .macCentralEurRoman,  // Central European (Mac OS)
            .isoLatin2,           // Central European (ISO Latin 2)
            .isoLatin3,           // Western (ISO Latin 3)
            .isoLatin4,           // Central European (ISO Latin 4)
            .dosLatinUS,          // Latin-US (DOS)
            .windowsLatin2,       // Central European (Windows Latin 2)
            .isoLatin6,           // Nordic (ISO Latin 6)
            .isoLatin7,           // Baltic (ISO Latin 7)
            .isoLatin8,           // Celtic (ISO Latin 8)
            .isoLatin10,          // Romanian (ISO Latin 10)
            .dosRussian,          // Russian (DOS)
            ascii,                // Western (ASCII)
        ]
        let inHelpEncodings = inHelpCFEncodings
            .map(\.rawValue)
            .map(CFStringEncoding.init)
            .map(String.Encoding.init(cfEncoding:))
        let availableEncodings = DefaultSettings.encodings
            .filter { $0 != kCFStringEncodingInvalidId }
            .map(String.Encoding.init(cfEncoding:))
        let yenIncompatibleEncodings = availableEncodings
            .filter { !"¥".canBeConverted(to: $0) }
        
        for encoding in yenIncompatibleEncodings {
            #expect(inHelpEncodings.contains(encoding), "\(String.localizedName(of: encoding))")
        }
        for encoding in inHelpEncodings {
            #expect(availableEncodings.contains(encoding), "\(String.localizedName(of: encoding))")
        }
    }
}


// MARK: Private Methods

private extension String.Encoding {
    
    init(cfEncodings: CFStringEncodings) {
        
        self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncodings.rawValue)))
    }
}
   

private extension EncodingDetectionTests {
    
    func encodedStringForFileName(_ fileName: String, usedEncoding: inout String.Encoding?) throws -> String {
        
        let data = try self.dataForFileName(fileName)
        
        return try String(data: data, suggestedEncodings: [], usedEncoding: &usedEncoding)
    }
    
    
    func dataForFileName(_ fileName: String) throws -> Data {
        
        guard
            let fileURL = Bundle(for: type(of: self)).url(forResource: fileName, withExtension: "txt", subdirectory: "Encodings")
        else { throw CocoaError(.fileNoSuchFile) }
        
        return try Data(contentsOf: fileURL)
    }
}
