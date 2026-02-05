//
//  EncodingDetectionTests.swift
//  FileEncodingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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
@testable import FileEncoding

struct EncodingDetectionTests {
    
    @Test(.bug("https://bugs.swift.org/browse/SR-10173"))
    func utf8BOM() throws {
        
        // -> String(data:encoding:) preserves BOM since Swift 5 (2019-03)
        // -> This issue has already solved in macOS 26 (2025-09)
        let data = try self.dataForFileName("UTF-8 BOM")
        if #available(macOS 26, *) {
            #expect(String(data: data, encoding: .utf8) == "0")
        } else {
            withKnownIssue {
                #expect(String(data: data, encoding: .utf8) == "0")
            }
            #expect(String(data: data, encoding: .utf8) == "\u{FEFF}0")
        }
        #expect(String(bomCapableData: data, encoding: .utf8) == "0")
        
        let (string, encoding) = try String.string(data: data, options: .init(candidates: String.Encoding.utfEncodings))
        
        #expect(string == "0")
        #expect(encoding == .utf8)
        
        #expect(String(bomCapableData: Data(Unicode.BOM.utf8.sequence), encoding: .utf8)?.isEmpty == true)
        #expect(String(bomCapableData: Data(), encoding: .utf8)?.isEmpty == true)
    }
    
    
    @Test func utf16() throws {
        
        let data = try self.dataForFileName("UTF-16")
        let (string, encoding) = try String.string(data: data, options: .init(candidates: String.Encoding.utfEncodings))
        
        #expect(string == "0")
        #expect(encoding == .utf16)
    }
    
    
    @Test func utf32() throws {
        
        let data = try self.dataForFileName("UTF-32")
        let (string, encoding) = try String.string(data: data, options: .init(candidates: String.Encoding.utfEncodings))
        
        #expect(string == "0")
        #expect(encoding == .utf32)
    }
    
    
    @Test func iso2022() throws {
        
        let data = try self.dataForFileName("ISO 2022-JP")
        let encodings: [String.Encoding] = [.iso2022JP, .utf16]
        
        let (string, encoding) = try String.string(data: data, options: .init(candidates: encodings))
        
        #expect(string == "dog犬")
        #expect(encoding == .iso2022JP)
    }
    
    
    @Test func emptySuggestion() throws {
        
        let data = try self.dataForFileName("UTF-8")
        
        #expect(throws: CocoaError(.fileReadUnknownStringEncoding)) {
            try String.string(data: data, options: .init(candidates: []))
        }
    }
    
    
    @Test func utf8() throws {
        
        let data = try self.dataForFileName("UTF-8")
        
        let invalidEncoding = String.Encoding(cfEncoding: kCFStringEncodingInvalidId)
        let (string, encoding) = try String.string(data: data, options: .init(candidates: [invalidEncoding, .utf8, .utf16]))
        
        #expect(string == "0")
        #expect(encoding == .utf8)
    }
    
    
    @Test func emptyData() throws {
        
        let data = Data()
        let (string, encoding) = try String.string(data: data, options: .init(candidates: [.shiftJIS]))
        
        #expect(string.isEmpty)
        #expect(encoding == .shiftJIS)
        #expect(!data.starts(with: Unicode.BOM.utf8.sequence))
    }
    
    
    @Test func utf8BOMData() throws {
        
        let withBOMData = try self.dataForFileName("UTF-8 BOM")
        #expect(withBOMData.starts(with: Unicode.BOM.utf8.sequence))
        
        let data = try self.dataForFileName("UTF-8")
        #expect(!data.starts(with: Unicode.BOM.utf8.sequence))
    }
    
    
    @Test func scanEncodingDeclaration() throws {
        
        #expect(Data("coding: utf-8".utf8).scanEncodingDeclaration() == .utf8)
        #expect(Data("coding: utf8".utf8).scanEncodingDeclaration() == .utf8)
        #expect(Data("coding: sjis".utf8).scanEncodingDeclaration() == .shiftJIS)
        #expect(Data("coding: shift-jis".utf8).scanEncodingDeclaration() == .shiftJIS)
        #expect(Data("coding: Shift_JIS".utf8).scanEncodingDeclaration() == String.Encoding(cfEncodings: .shiftJIS))
        
        #expect(Data("fileencoding: utf8".utf8).scanEncodingDeclaration() == .utf8)  // Vim
        #expect(Data("encoding=utf8".utf8).scanEncodingDeclaration() == .utf8)  // Python
        
        // HTML (1024 bytes)
        let data = Data("<meta charset=\"utf-8\">".utf8)
        #expect((Data(repeating: 0, count: 512) + data).scanEncodingDeclaration() == .utf8)
        #expect((Data(repeating: 0, count: 1024) + data).scanEncodingDeclaration() == nil)
        #expect(Data("<meta charset=\"utf-8\" 犬".utf8).scanEncodingDeclaration() == .utf8)
        #expect(Data("犬<meta charset=\"utf-8\"".utf8).scanEncodingDeclaration() == nil)
        #expect(Data("<meta charset=utf-8".utf8).scanEncodingDeclaration() == nil)
        
        // CSS (@charset)
        #expect(Data("@charset \"utf-8\";".utf8).scanEncodingDeclaration() == .utf8)
        #expect(Data("a\n@charset \"utf-8\";".utf8).scanEncodingDeclaration() == nil)
        #expect(Data(" @charset \"utf-8\";".utf8).scanEncodingDeclaration() == nil)
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
    
    
    @Test func decodingStrategySpecific() throws {
        
        let data = Data("🐕".utf8)
        let result = try String.string(data: data, decodingStrategy: .specific(.utf8))
        
        #expect(result.0 == "🐕")
        #expect(result.1 == FileEncoding(encoding: .utf8))
        
        let error = #expect(throws: CocoaError.self) {
            try String.string(data: data, decodingStrategy: .specific(.ascii))
        }
        #expect(error?.code == .fileReadInapplicableStringEncoding)
    }
    
    
    @Test func decodingStrategyAutomaticBOM() throws {
        
        let data = Data(Unicode.BOM.utf8.sequence + [0x61])
        let options = String.DetectionOptions(candidates: [.utf8])
        let result = try String.string(data: data, decodingStrategy: .automatic(options))
        
        #expect(result.0 == "a")
        #expect(result.1.withUTF8BOM)
    }
    
    
    @Test func detectionOptionsXattrEncoding() throws {
        
        let data = Data()
        let options = String.DetectionOptions(candidates: [], xattrEncoding: .utf8)
        let (string, encoding) = try String.string(data: data, options: options)
        
        #expect(string.isEmpty)
        #expect(encoding == .utf8)
    }
    
    
    @Test func detectionOptionsDeclarationPriority() throws {
        
        let data = Data("# coding: utf-8".utf8)
        let options = String.DetectionOptions(candidates: [.utf16, .utf8], considersDeclaration: true)
        let (string, encoding) = try String.string(data: data, options: options)
        
        #expect(string == "# coding: utf-8")
        #expect(encoding == .utf8)
    }
    
    
    @Test func sortedAvailableStringEncodings() {
        
        let encodings = String.sortedAvailableStringEncodings
        let compact = encodings.compactMap(\.self)
        
        #expect(encodings.contains(nil))
        #expect(compact.count == String.availableStringEncodings.count)
    }
    
    
    /// Tests testing helper APIs.
    @Test func initializeEncoding() {
        
        #expect(String.Encoding(cfEncodings: .dosJapanese) == .shiftJIS)
        #expect(String.Encoding(cfEncodings: .shiftJIS) != .shiftJIS)
        #expect(String.Encoding(cfEncodings: .shiftJIS_X0213) != .shiftJIS)
        
        #expect(String.Encoding(cfEncoding: CFStringEncoding(CFStringEncodings.dosJapanese.rawValue)) == .shiftJIS)
        #expect(String.Encoding(cfEncoding: CFStringEncoding(CFStringEncodings.shiftJIS.rawValue)) != .shiftJIS)
        #expect(String.Encoding(cfEncoding: CFStringEncoding(CFStringEncodings.shiftJIS_X0213.rawValue)) != .shiftJIS)
    }
}


// MARK: Private Methods

private extension String.Encoding {
    
    static let utfEncodings: [String.Encoding] = [
        .utf8,
        .utf16,
        .utf16BigEndian,
        .utf16LittleEndian,
        .utf32,
        .utf32BigEndian,
        .utf32LittleEndian,
    ]
    
    
    init(cfEncodings: CFStringEncodings) {
        
        self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncodings.rawValue)))
    }
}
   

private extension EncodingDetectionTests {
    
    func dataForFileName(_ fileName: String) throws -> Data {
        
        guard
            let fileURL = Bundle.module.url(forResource: fileName, withExtension: "txt")
        else { throw CocoaError(.fileNoSuchFile) }
        
        return try Data(contentsOf: fileURL)
    }
}
