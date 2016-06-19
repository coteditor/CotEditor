/*
 
 EncodingDetectionTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-16.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

import XCTest

class EncodingDetectionTests: XCTestCase {
    
    var bundle: Bundle?
    

    override func setUp() {
        super.setUp()
        
        self.bundle = Bundle(for: self.dynamicType)
    }
    
    
    func testUTF8BOM() {
        var encodingUInt: UInt = 0
        let string = self.encodedStringForFileName("UTF-8 BOM", usedEncoding: &encodingUInt)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encodingUInt, String.Encoding.utf8.rawValue)
    }
    
    
    func testUTF16() {
        var encodingUInt: UInt = 0
        let string = self.encodedStringForFileName("UTF-16", usedEncoding: &encodingUInt)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encodingUInt, String.Encoding.utf16.rawValue)
    }
    
    
    func testUTF32() {
        var encodingUInt: UInt = 0
        let string = self.encodedStringForFileName("UTF-32", usedEncoding: &encodingUInt)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encodingUInt, String.Encoding.utf32.rawValue)
    }

    
    func testISO2022() {
        var encodingUInt: UInt = 0
        let string = self.encodedStringForFileName("ISO 2022-JP", usedEncoding: &encodingUInt)
        
        XCTAssertEqual(string, "dog犬")
        XCTAssertEqual(encodingUInt, String.Encoding.iso2022JP.rawValue)
    }
    
    
    func testUTF8() {  // this should fail
        var encodingUInt: UInt = 0
        let string = self.encodedStringForFileName("UTF-8", usedEncoding: &encodingUInt)
        
        XCTAssertNil(string)
        XCTAssertEqual(Int(encodingUInt), NSNotFound)
    }

    
    func testSuggestedCFEncoding() {
        let data = self.dataForFileName("UTF-8")
        
        var encodingUInt: UInt = 0
        let invalidNumber = NSNumber(value: UInt32(kCFStringEncodingInvalidId))
        let utf8Number = NSNumber(value: UInt32(CFStringBuiltInEncodings.UTF8.rawValue))
        let string = try! NSString(data: data, suggestedCFEncodings: [invalidNumber, utf8Number], usedEncoding: &encodingUInt)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encodingUInt, String.Encoding.utf8.rawValue)
    }
    
    
    func testEmptyData() {
        let data = Data()
        
        var encodingUInt: UInt = 0
        var string: NSString?
        var didCatchError = false
        do {
            string = try NSString(data: data, suggestedCFEncodings: [], usedEncoding: &encodingUInt)
        } catch let error as NSError {
            XCTAssertEqual(error.domain, NSCocoaErrorDomain)
            XCTAssertEqual(error.code, NSFileReadUnknownStringEncodingError)
            XCTAssertNotNil(error.localizedDescription)
            didCatchError = true
        }

        XCTAssertTrue(didCatchError, "NSString+CEEncoding didn't throw error.")
        XCTAssertNil(string)
        XCTAssertEqual(Int(encodingUInt), NSNotFound)
        XCTAssertFalse((data as NSData).hasUTF8BOM())
    }
    
    
    func testUTF8BOMData() {
        let withBOMData = self.dataForFileName("UTF-8 BOM")
        XCTAssertTrue((withBOMData as NSData).hasUTF8BOM())
        
        let data = self.dataForFileName("UTF-8")
        XCTAssertFalse((data as NSData).hasUTF8BOM())
        XCTAssertTrue(((data as NSData).addingUTF8BOM() as NSData).hasUTF8BOM())
    }
    
    
    func testEncodingDeclarationScan() {
        let string = "<meta charset=\"Shift_JIS\"/>" as NSString
        let tags = ["encoding=", "charset="]
        let utf8Number = NSNumber(value: UInt32(CFStringBuiltInEncodings.UTF8.rawValue))
        let shiftJISNumber = NSNumber(value: UInt32(CFStringEncodings.shiftJIS.rawValue))
        let shiftJISX0213Number = NSNumber(value: UInt32(CFStringEncodings.shiftJIS_X0213.rawValue))
        
        XCTAssertEqual(Int(string.scanEncodingDeclaration(forTags: tags, upTo: 16,
            suggestedCFEncodings: [utf8Number, shiftJISNumber, shiftJISX0213Number])),
            NSNotFound)
        
        XCTAssertEqual(string.scanEncodingDeclaration(forTags: tags, upTo: 128,
            suggestedCFEncodings: [utf8Number, shiftJISNumber, shiftJISX0213Number]),
            toNSEncoding(.shiftJIS).rawValue)
        
        XCTAssertEqual(string.scanEncodingDeclaration(forTags: tags, upTo: 128,
            suggestedCFEncodings: [utf8Number, shiftJISX0213Number, shiftJISNumber]),
            toNSEncoding(.shiftJIS_X0213).rawValue)
    }
    
    
    func testIANACharSetEncodingCompatibility() {
        XCTAssertTrue(CEIsCompatibleIANACharSetEncoding(String.Encoding.utf8.rawValue, String.Encoding.utf8.rawValue));
        XCTAssertFalse(CEIsCompatibleIANACharSetEncoding(String.Encoding.utf8.rawValue, String.Encoding.utf16.rawValue));
        
        XCTAssertTrue(CEIsCompatibleIANACharSetEncoding(toNSEncoding(.shiftJIS).rawValue, toNSEncoding(.shiftJIS).rawValue))
        XCTAssertTrue(CEIsCompatibleIANACharSetEncoding(toNSEncoding(.shiftJIS).rawValue, toNSEncoding(.shiftJIS_X0213).rawValue))
        XCTAssertTrue(CEIsCompatibleIANACharSetEncoding(toNSEncoding(.shiftJIS_X0213).rawValue, toNSEncoding(.shiftJIS).rawValue))
    }
    
    
    func testXattrEncoding() {
        let utf8Data = "utf-8;134217984".data(using: String.Encoding.utf8)
        
        XCTAssertEqual(encodeXattrEncoding(String.Encoding.utf8.rawValue), utf8Data)
        XCTAssertEqual(decodeXattrEncoding(utf8Data), String.Encoding.utf8.rawValue)
        XCTAssertEqual(decodeXattrEncoding("utf-8".data(using: String.Encoding.utf8)), String.Encoding.utf8.rawValue)
        
        
        let eucJPData = "euc-jp;2336".data(using: String.Encoding.utf8)
        
        XCTAssertEqual(encodeXattrEncoding(String.Encoding.japaneseEUC.rawValue), eucJPData)
        XCTAssertEqual(decodeXattrEncoding(eucJPData), String.Encoding.japaneseEUC.rawValue)
        XCTAssertEqual(decodeXattrEncoding("euc-jp".data(using: String.Encoding.utf8)), String.Encoding.japaneseEUC.rawValue)
    }
    
    
    func testYenConvertion() {
        XCTAssertTrue(CEEncodingCanConvertYenSign(String.Encoding.utf8.rawValue))
        XCTAssertTrue(CEEncodingCanConvertYenSign(toNSEncoding(.shiftJIS).rawValue))
        XCTAssertFalse(CEEncodingCanConvertYenSign(String.Encoding.japaneseEUC.rawValue))  // ? (U+003F)
        XCTAssertFalse(CEEncodingCanConvertYenSign(String.Encoding.ascii.rawValue))  // Y (U+0059)
        
        let string = "yen \\ ¥ yen" as NSString
        XCTAssertEqual(string.convertingYenSign(forEncoding: String.Encoding.utf8.rawValue), "yen \\ ¥ yen")
        XCTAssertEqual(string.convertingYenSign(forEncoding: String.Encoding.ascii.rawValue), "yen \\ \\ yen")
    }
    
    
    func testIANACharsetName() {
        XCTAssertEqual(NSString.ianaCharSetName(ofStringEncoding: String.Encoding.utf8.rawValue), "utf-8")
        XCTAssertEqual(NSString.ianaCharSetName(ofStringEncoding: String.Encoding.isoLatin1.rawValue), "iso-8859-1")
    }
    
    
    // MARK: Private Methods
    
    func encodedStringForFileName(_ fileName: String, usedEncoding: UnsafeMutablePointer<UInt>) -> NSString? {
        let data = self.dataForFileName(fileName)
        
        return try? NSString(data: data, suggestedCFEncodings: [], usedEncoding: usedEncoding)
    }
    
    
    func dataForFileName(_ fileName: String) -> Data {
        let fileURL = self.bundle?.urlForResource(fileName, withExtension: "txt", subdirectory: "Encodings")
        let data = try? Data(contentsOf: fileURL!)
        
        XCTAssertNotNil(data)
        
        return data!
    }
    
    
    func toNSEncoding(_ cfEncodings: CFStringEncodings) -> String.Encoding {
        let rawValue = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncodings.rawValue));
        return String.Encoding(rawValue: rawValue)
    }

}
