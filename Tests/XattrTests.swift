/*
 
 XattrTests.swift
 Tests
 
 CotEditor
 http://coteditor.com
 
 Created by 1024jp on 2016-01-24.
 
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

class XattrTests: XCTestCase {
    
    let testFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("com.coteditor.CotEditor.test.txt")
    
    
    override func setUp() {
        super.setUp()
       
        if let data = "🐕".data(using: String.Encoding.utf8) {
            try? data.write(to: self.testFileURL, options: [.atomic])
        }
    }
    
    
    override func tearDown() {
        
        try! FileManager.default.removeItem(at: self.testFileURL)
        
        super.tearDown()
    }

    
    // MARK: -
    
    func testEncodingReadWrite() {
        let fileURL = self.testFileURL
        let encoding = String.Encoding.utf16  // This may not be the same as the real file encoding.
        
        // try getting xattr before set (should fail)
        XCTAssertEqual((fileURL as NSURL).getXattrEncoding(), UInt(NSNotFound))
        
        // set xattr
        if !(fileURL as NSURL).setXattrEncoding(encoding.rawValue) {
            XCTFail("Failed setting xattr encoding.")
        }
        
        XCTAssertEqual((fileURL as NSURL).getXattrEncoding(), encoding.rawValue)
    }
    
    
    func testBooleanReadWrite() {
        let fileURL = self.testFileURL
        let xattrName = "test"
        
        // unset key returns false
        XCTAssertFalse((fileURL as NSURL).getXattrBool(forName: xattrName))
        
        // write `true`
        if !(fileURL as NSURL).setXattrBool(true, forName: xattrName) {
            XCTFail("Failed setting xattr boolean.")
        }
        
        XCTAssertTrue((fileURL as NSURL).getXattrBool(forName: xattrName))
        
        // overwrite
        (fileURL as NSURL).setXattrBool(false, forName: xattrName)
        XCTAssertFalse((fileURL as NSURL).getXattrBool(forName: xattrName))
    }

}
