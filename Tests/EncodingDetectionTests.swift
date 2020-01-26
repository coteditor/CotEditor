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
//  © 2016-2019 1024jp
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

import XCTest
@testable import CotEditor

final class EncodingDetectionTests: XCTestCase {
    
    var bundle: Bundle?
    

    override func setUp() {
        
        super.setUp()
        
        self.bundle = Bundle(for: type(of: self))
    }
    
    
    func testUTF8BOM() throws {
        
        // -> String(data:encoding:) preserves BOM since Swift 5 (2019-03)
        let data = try self.dataForFileName("UTF-8 BOM")
        XCTAssertEqual(String(data: data, encoding: .utf8), "\u{FEFF}0")
        XCTAssertEqual(String(bomCapableData: data, encoding: .utf8), "0")
        
        var encoding: String.Encoding?
        let string = try self.encodedStringForFileName("UTF-8 BOM", usedEncoding: &encoding)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, String.Encoding.utf8)
    }
    
    
    func testUTF16() throws {
        
        var encoding: String.Encoding?
        let string = try self.encodedStringForFileName("UTF-16", usedEncoding: &encoding)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, String.Encoding.utf16)
    }
    
    
    func testUTF32() throws {
        
        var encoding: String.Encoding?
        let string = try self.encodedStringForFileName("UTF-32", usedEncoding: &encoding)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, String.Encoding.utf32)
    }

    
    func testISO2022() throws {
        
        var encoding: String.Encoding?
        let string = try self.encodedStringForFileName("ISO 2022-JP", usedEncoding: &encoding)
        
        XCTAssertEqual(string, "dog犬")
        XCTAssertEqual(encoding, String.Encoding.iso2022JP)
    }
    
    
    func testUTF8() throws {
        
        let data = try self.dataForFileName("UTF-8")
        
        var encoding: String.Encoding?
        do {
            _ = try String(data: data, suggestedCFEncodings: [], usedEncoding: &encoding)
        } catch let error as CocoaError {
            XCTAssertEqual(error.code, .fileReadUnknownStringEncoding)
        } catch _ {
            XCTFail("Caught incorrect error.")
        }
        
        XCTAssertNil(encoding)
    }

    
    func testSuggestedCFEncoding() throws {
        
        let data = try self.dataForFileName("UTF-8")
        
        var encoding: String.Encoding?
        let invalidInt = UInt32(kCFStringEncodingInvalidId)
        let utf8Int = UInt32(CFStringBuiltInEncodings.UTF8.rawValue)
        let string = try String(data: data, suggestedCFEncodings: [invalidInt, utf8Int], usedEncoding: &encoding)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, String.Encoding.utf8)
    }
    
    
    func testEmptyData() {
        
        let data = Data()
        
        var encoding: String.Encoding?
        var string: String?
        var didCatchError = false
        do {
            string = try String(data: data, suggestedCFEncodings: [], usedEncoding: &encoding)
        } catch let error as CocoaError where error.code == .fileReadUnknownStringEncoding {
            didCatchError = true
        } catch {
            XCTFail(error.localizedDescription)
        }

        XCTAssertTrue(didCatchError, "String+Encoding didn't throw error.")
        XCTAssertNil(string)
        XCTAssertNil(encoding)
        XCTAssertFalse(data.hasUTF8BOM)
    }
    
    
    func testUTF8BOMData() throws {
        
        let withBOMData = try self.dataForFileName("UTF-8 BOM")
        XCTAssertTrue(withBOMData.hasUTF8BOM)
        
        let data = try self.dataForFileName("UTF-8")
        XCTAssertFalse(data.hasUTF8BOM)
        XCTAssertTrue(data.addingUTF8BOM.hasUTF8BOM)
    }
    
    
    func testEncodingDeclarationScan() {
        
        let string = "<meta charset=\"Shift_JIS\"/>"
        let utf8Int = UInt32(CFStringBuiltInEncodings.UTF8.rawValue)
        let shiftJISInt = UInt32(CFStringEncodings.shiftJIS.rawValue)
        let shiftJISX0213Int = UInt32(CFStringEncodings.shiftJIS_X0213.rawValue)
        
        XCTAssertNil(string.scanEncodingDeclaration(upTo: 16,
                                                    suggestedCFEncodings: [utf8Int, shiftJISInt, shiftJISX0213Int]))
        
        XCTAssertEqual(string.scanEncodingDeclaration(upTo: 128,
                                                      suggestedCFEncodings: [utf8Int, shiftJISInt, shiftJISX0213Int]),
                       String.Encoding(cfEncodings: CFStringEncodings.shiftJIS))
        
        XCTAssertEqual(string.scanEncodingDeclaration(upTo: 128,
                                                      suggestedCFEncodings: [utf8Int, shiftJISX0213Int, shiftJISInt]),
                       String.Encoding(cfEncodings: CFStringEncodings.shiftJIS_X0213))
        
        XCTAssertEqual("<meta charset=\"utf-8\"/>".scanEncodingDeclaration(upTo: 128,
                                                                           suggestedCFEncodings: [utf8Int, shiftJISX0213Int, shiftJISInt]),
                       String.Encoding.utf8)
    }
    
    
    func testEncodingInitialization() {
        
        XCTAssertEqual(String.Encoding(cfEncodings: CFStringEncodings.dosJapanese), String.Encoding.shiftJIS)
        XCTAssertNotEqual(String.Encoding(cfEncodings: CFStringEncodings.shiftJIS), String.Encoding.shiftJIS)
        XCTAssertNotEqual(String.Encoding(cfEncodings: CFStringEncodings.shiftJIS_X0213), String.Encoding.shiftJIS)
        
        XCTAssertEqual(String.Encoding(cfEncoding: CFStringEncoding(CFStringEncodings.dosJapanese.rawValue)), String.Encoding.shiftJIS)
        XCTAssertNotEqual(String.Encoding(cfEncoding: CFStringEncoding(CFStringEncodings.shiftJIS.rawValue)), String.Encoding.shiftJIS)
        XCTAssertNotEqual(String.Encoding(cfEncoding: CFStringEncoding(CFStringEncodings.shiftJIS_X0213.rawValue)), String.Encoding.shiftJIS)
    }
    
    
    func testXattrEncoding() {
        
        let utf8Data = "utf-8;134217984".data(using: String.Encoding.utf8)
        
        XCTAssertEqual(String.Encoding.utf8.xattrEncodingData, utf8Data)
        XCTAssertEqual(utf8Data?.decodingXattrEncoding, String.Encoding.utf8)
        XCTAssertEqual("utf-8".data(using: String.Encoding.utf8)?.decodingXattrEncoding, String.Encoding.utf8)
        
        
        let eucJPData = "euc-jp;2336".data(using: String.Encoding.utf8)
        
        XCTAssertEqual(String.Encoding.japaneseEUC.xattrEncodingData, eucJPData)
        XCTAssertEqual(eucJPData?.decodingXattrEncoding, String.Encoding.japaneseEUC)
        XCTAssertEqual("euc-jp".data(using: String.Encoding.utf8)?.decodingXattrEncoding, String.Encoding.japaneseEUC)
    }
    
    
    func testYenConvertion() {
        
        XCTAssertTrue(String.Encoding.utf8.canConvertYenSign)
        XCTAssertTrue(toNSEncoding(.shiftJIS).canConvertYenSign)
        XCTAssertFalse(String.Encoding.japaneseEUC.canConvertYenSign)  // ? (U+003F)
        XCTAssertFalse(String.Encoding.ascii.canConvertYenSign)  // Y (U+0059)
        
        let string = "yen \\ ¥ yen"
        XCTAssertEqual(string.convertingYenSign(for: .utf8), "yen \\ ¥ yen")
        XCTAssertEqual(string.convertingYenSign(for: .ascii), "yen \\ \\ yen")
    }
    
    
    func testIANACharsetName() {
        
        XCTAssertEqual(String.Encoding.utf8.ianaCharSetName, "utf-8")
        XCTAssertEqual(String.Encoding.isoLatin1.ianaCharSetName, "iso-8859-1")
    }
    
}
    
    
    // MARK: Private Methods
    
private extension EncodingDetectionTests {
    
    func encodedStringForFileName(_ fileName: String, usedEncoding: inout String.Encoding?) throws -> String {
        
        let data = try self.dataForFileName(fileName)
        
        return try String(data: data, suggestedCFEncodings: [], usedEncoding: &usedEncoding)
    }
    
    
    func dataForFileName(_ fileName: String) throws -> Data {
        
        let fileURL = self.bundle!.url(forResource: fileName, withExtension: "txt", subdirectory: "Encodings")
        
        return try Data(contentsOf: fileURL!)
    }
    
    
    func toNSEncoding(_ cfEncodings: CFStringEncodings) -> String.Encoding {
        
        let rawValue = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncodings.rawValue))
        return String.Encoding(rawValue: rawValue)
    }

}
