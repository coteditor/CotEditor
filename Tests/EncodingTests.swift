/*

EncodingTests.swift
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

class EncodingTests: XCTestCase {
    
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
        
        XCTAssertEqual(string, "あ")
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

}
