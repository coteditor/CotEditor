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
    
    var bundle: NSBundle?
    

    override func setUp() {
        super.setUp()
        
        self.bundle = NSBundle(forClass: self.dynamicType)
    }
    
    
    func testUTF8BOM() {
        var encoding: NSStringEncoding = 0
        let string = self.encodedStringForFileName("UTF-8 BOM", usedEncoding: &encoding)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, NSUTF8StringEncoding)
    }
    
    
    func testUTF16() {
        var encoding: NSStringEncoding = 0
        let string = self.encodedStringForFileName("UTF-16", usedEncoding: &encoding)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, NSUTF16StringEncoding)
    }
    
    
    func testUTF32() {
        var encoding: NSStringEncoding = 0
        let string = self.encodedStringForFileName("UTF-32", usedEncoding: &encoding)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, NSUTF32StringEncoding)
    }
    
    
    func testISO2022() {
        var encoding: NSStringEncoding = 0
        let string = self.encodedStringForFileName("ISO 2022-JP", usedEncoding: &encoding)
        
        XCTAssertEqual(string, "dog犬")
        XCTAssertEqual(encoding, NSISO2022JPStringEncoding)
    }
    
    
    func testUTF8() {  // this should fail
        var encoding: NSStringEncoding = 0
        let string = self.encodedStringForFileName("UTF-8", usedEncoding: &encoding)
        
        XCTAssertNil(string)
        XCTAssertEqual(Int(encoding), NSNotFound)
    }
    
    
    func testSuggestedCFEncoding() {
        let data = self.dataForFileName("UTF-8")
        
        var encoding: NSStringEncoding = 0
        let invalidNumber = NSNumber(unsignedInt: UInt32(kCFStringEncodingInvalidId))
        let utf8Number = NSNumber(unsignedInt: UInt32(CFStringBuiltInEncodings.UTF8.rawValue))
        let string = try! NSString(data: data, suggestedCFEncodings: [invalidNumber, utf8Number], usedEncoding: &encoding)
        
        XCTAssertEqual(string, "0")
        XCTAssertEqual(encoding, NSUTF8StringEncoding)
    }
    
    
    func testEmptyData() {
        let data = NSData()
        
        var encoding: NSStringEncoding = 0
        var string: NSString?
        var didCatchError = false
        do {
            string = try NSString(data: data, suggestedCFEncodings: [], usedEncoding: &encoding)
        } catch let error as NSError {
            XCTAssertEqual(error.domain, NSCocoaErrorDomain)
            XCTAssertEqual(error.code, NSFileReadUnknownStringEncodingError)
            XCTAssertNotNil(error.localizedDescription)
            didCatchError = true
        }
        
        XCTAssertTrue(didCatchError, "NSString+CEEncoding didn't throw error.")
        XCTAssertNil(string)
        XCTAssertEqual(Int(encoding), NSNotFound)
        XCTAssertFalse(data.hasUTF8BOM())
    }
    
    
    func testUTF8BOMData() {
        let withBOMData = self.dataForFileName("UTF-8 BOM")
        XCTAssertTrue(withBOMData.hasUTF8BOM())
        
        let data = self.dataForFileName("UTF-8")
        XCTAssertFalse(data.hasUTF8BOM())
        XCTAssertTrue(data.dataByAddingUTF8BOM().hasUTF8BOM())
    }
    
    
    func testEncodingDeclarationScan() {
        let string = "<meta charset=\"Shift_JIS\"/>" as NSString
        let tags = ["encoding=", "charset="]
        let utf8Number = NSNumber(unsignedInt: UInt32(CFStringBuiltInEncodings.UTF8.rawValue))
        let shiftJISNumber = NSNumber(unsignedInt: UInt32(CFStringEncodings.ShiftJIS.rawValue))
        let shiftJISX0213Number = NSNumber(unsignedInt: UInt32(CFStringEncodings.ShiftJIS_X0213.rawValue))
        
        XCTAssertEqual(Int(string.scanEncodingDeclarationForTags(tags, upToIndex: 16,
            suggestedCFEncodings: [utf8Number, shiftJISNumber, shiftJISX0213Number])),
            NSNotFound)
        
        XCTAssertEqual(string.scanEncodingDeclarationForTags(tags, upToIndex: 128,
            suggestedCFEncodings: [utf8Number, shiftJISNumber, shiftJISX0213Number]),
            toNSEncoding(.ShiftJIS))
        
        XCTAssertEqual(string.scanEncodingDeclarationForTags(tags, upToIndex: 128,
            suggestedCFEncodings: [utf8Number, shiftJISX0213Number, shiftJISNumber]),
            toNSEncoding(.ShiftJIS_X0213))
    }
    
    
    func testIANACharSetEncodingCompatibility() {
        XCTAssertTrue(CEIsCompatibleIANACharSetEncoding(NSUTF8StringEncoding, NSUTF8StringEncoding));
        XCTAssertFalse(CEIsCompatibleIANACharSetEncoding(NSUTF8StringEncoding, NSUTF16StringEncoding));
        
        XCTAssertTrue(CEIsCompatibleIANACharSetEncoding(toNSEncoding(.ShiftJIS), toNSEncoding(.ShiftJIS)))
        XCTAssertTrue(CEIsCompatibleIANACharSetEncoding(toNSEncoding(.ShiftJIS), toNSEncoding(.ShiftJIS_X0213)))
        XCTAssertTrue(CEIsCompatibleIANACharSetEncoding(toNSEncoding(.ShiftJIS_X0213), toNSEncoding(.ShiftJIS)))
    }
    
    
    func testXattrEncoding() {
        let utf8Data = "utf-8;134217984".dataUsingEncoding(NSUTF8StringEncoding)
        
        XCTAssertEqual(encodeXattrEncoding(NSUTF8StringEncoding), utf8Data)
        XCTAssertEqual(decodeXattrEncoding(utf8Data), NSUTF8StringEncoding)
        XCTAssertEqual(decodeXattrEncoding("utf-8".dataUsingEncoding(NSUTF8StringEncoding)), NSUTF8StringEncoding)
        
        
        let eucJPData = "euc-jp;2336".dataUsingEncoding(NSUTF8StringEncoding)
        
        XCTAssertEqual(encodeXattrEncoding(NSJapaneseEUCStringEncoding), eucJPData)
        XCTAssertEqual(decodeXattrEncoding(eucJPData), NSJapaneseEUCStringEncoding)
        XCTAssertEqual(decodeXattrEncoding("euc-jp".dataUsingEncoding(NSUTF8StringEncoding)), NSJapaneseEUCStringEncoding)
    }
    
    
    func testYenConvertion() {
        XCTAssertTrue(CEEncodingCanConvertYenSign(NSUTF8StringEncoding))
        XCTAssertTrue(CEEncodingCanConvertYenSign(toNSEncoding(.ShiftJIS)))
        XCTAssertFalse(CEEncodingCanConvertYenSign(NSJapaneseEUCStringEncoding))  // ? (U+003F)
        XCTAssertFalse(CEEncodingCanConvertYenSign(NSASCIIStringEncoding))  // Y (U+0059)
        
        let string = "yen \\ ¥ yen" as NSString
        XCTAssertEqual(string.stringByConvertingYenSignForEncoding(NSUTF8StringEncoding), "yen \\ ¥ yen")
        XCTAssertEqual(string.stringByConvertingYenSignForEncoding(NSASCIIStringEncoding), "yen \\ \\ yen")
    }
    
    
    func testIANACharsetName() {
        XCTAssertEqual(NSString.IANACharSetNameOfStringEncoding(NSUTF8StringEncoding), "utf-8")
        XCTAssertEqual(NSString.IANACharSetNameOfStringEncoding(NSISOLatin1StringEncoding), "iso-8859-1")
    }
    
    
    // MARK: Private Methods
    
    func encodedStringForFileName(fileName: String, usedEncoding: UnsafeMutablePointer<UInt>) -> NSString? {
        let data = self.dataForFileName(fileName)
        
        return try? NSString(data: data, suggestedCFEncodings: [], usedEncoding: usedEncoding)
    }
    
    
    func dataForFileName(fileName: String) -> NSData {
        let fileURL = self.bundle?.URLForResource(fileName, withExtension: "txt", subdirectory: "Encodings")
        let data = NSData(contentsOfURL: fileURL!)
        
        XCTAssertNotNil(data)
        
        return data!
    }
    
    
    func toNSEncoding(cfEncodings: CFStringEncodings) -> NSStringEncoding {
        return CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncodings.rawValue));
    }

}
