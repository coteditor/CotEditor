/*
 
 EncodingDetectionTests.swift
 Tests
 
 CotEditor
 http://coteditor.com
 
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
        
        self.bundle = Bundle(for: type(of: self))
    }
    
    
    func testUTF8BOM() {
        var encoding: String.Encoding = String.Encoding(rawValue: UInt(0))
        let string = self.encodedStringForFileName("UTF-8 BOM", usedEncoding: &encoding.rawValue)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, String.Encoding.utf8)
    }
    
    
    func testUTF16() {
        var encoding: String.Encoding = String.Encoding(rawValue: UInt(0))
        let string = self.encodedStringForFileName("UTF-16", usedEncoding: &encoding.rawValue)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, String.Encoding.utf16)
    }
    
    
    func testUTF32() {
        var encoding: String.Encoding = String.Encoding(rawValue: UInt(0))
        let string = self.encodedStringForFileName("UTF-32", usedEncoding: &encoding.rawValue)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, String.Encoding.utf32)
    }
    
    
    func testISO2022() {
        var encoding: String.Encoding = String.Encoding(rawValue: UInt(0))
        let string = self.encodedStringForFileName("ISO 2022-JP", usedEncoding: &encoding.rawValue)
        
        XCTAssertEqual(string, "dog犬")
        XCTAssertEqual(encoding, String.Encoding.iso2022JP)
    }
    
    
    func testUTF8() {  // this should fail
        var encoding: String.Encoding = String.Encoding(rawValue: UInt(0))
        let string = self.encodedStringForFileName("UTF-8", usedEncoding: &encoding.rawValue)
        
        XCTAssertNil(string)
        XCTAssertEqual(encoding.rawValue, UInt(NSNotFound))
    }
    
    
    func testSuggestedCFEncoding() {
        let data = self.dataForFileName("UTF-8")
        
        var encoding: String.Encoding = String.Encoding(rawValue: UInt(0))
        let invalidNumber = NSNumber(value: UInt32(kCFStringEncodingInvalidId) as UInt32)
        let utf8Number = NSNumber(value: UInt32(CFStringBuiltInEncodings.UTF8.rawValue) as UInt32)
        let string = try! NSString(data: data, suggestedCFEncodings: [invalidNumber, utf8Number], usedEncoding: &encoding.rawValue)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, String.Encoding.utf8)
    }
    
    
    func testEmptyData() {
        let data = Data()
        
        var encoding: String.Encoding = String.Encoding(rawValue: UInt(0))
        var string: NSString?
        var didCatchError = false
        do {
            string = try NSString(data: data, suggestedCFEncodings: [], usedEncoding: &encoding.rawValue)
        } catch let error as NSError {
            XCTAssertEqual(error.domain, NSCocoaErrorDomain)
            XCTAssertEqual(error.code, NSFileReadUnknownStringEncodingError)
            XCTAssertNotNil(error.localizedDescription)
            didCatchError = true
        }
        
        XCTAssertTrue(didCatchError, "NSString+CEEncoding didn't throw error.")
        XCTAssertNil(string)
        XCTAssertEqual(encoding.rawValue, UInt(NSNotFound))
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
        let utf8Number = NSNumber(value: UInt32(CFStringBuiltInEncodings.UTF8.rawValue) as UInt32)
        let shiftJISNumber = NSNumber(value: UInt32(CFStringEncodings.shiftJIS.rawValue) as UInt32)
        let shiftJISX0213Number = NSNumber(value: UInt32(CFStringEncodings.shiftJIS_X0213.rawValue) as UInt32)
        
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
    
    
    // MARK: Private Methods
    
    func encodedStringForFileName(_ fileName: String, usedEncoding: UnsafeMutablePointer<UInt>) -> NSString? {
        let data = self.dataForFileName(fileName)
        
        return try? NSString(data: data, suggestedCFEncodings: [], usedEncoding: usedEncoding)
    }
    
    
    func dataForFileName(_ fileName: String) -> Data {
        let fileURL = self.bundle?.url(forResource: fileName, withExtension: "txt", subdirectory: "Encodings")
        let data = try? Data(contentsOf: fileURL!)
        
        XCTAssertNotNil(data)
        
        return data!
    }
    
    
    func toNSEncoding(_ cfEncodings: CFStringEncodings) -> String.Encoding {
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncodings.rawValue)));
    }

}
