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
    
    let testFileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("com.coteditor.CotEditor.test.txt")
    
    
    override func setUp() {
        super.setUp()
       
        if let data = "🐕".dataUsingEncoding(NSUTF8StringEncoding) {
            data.writeToURL(self.testFileURL, atomically: true)
        }
    }
    
    
    override func tearDown() {
        
        try! NSFileManager.defaultManager().removeItemAtURL(self.testFileURL)
        
        super.tearDown()
    }

    
    // MARK: -
    
    func testEncodingReadWrite() {
        let fileURL = self.testFileURL
        let encoding = NSUTF16StringEncoding  // This may not be the same as the real file encoding.
        
        // try getting xattr before set (should fail)
        XCTAssertEqual(fileURL.getXattrEncoding(), UInt(NSNotFound))
        
        // set xattr
        if !fileURL.setXattrEncoding(encoding) {
            XCTFail("Failed setting xattr encoding.")
        }
        
        XCTAssertEqual(fileURL.getXattrEncoding(), encoding)
    }
    
    
    func testBooleanReadWrite() {
        let fileURL = self.testFileURL
        let xattrName = "test"
        
        // unset key returns false
        XCTAssertFalse(fileURL.getXattrBoolForName(xattrName))
        
        // write `true`
        if !fileURL.setXattrBool(true, forName: xattrName) {
            XCTFail("Failed setting xattr boolean.")
        }
        
        XCTAssertTrue(fileURL.getXattrBoolForName(xattrName))
        
        // overwrite
        fileURL.setXattrBool(false, forName: xattrName)
        XCTAssertFalse(fileURL.getXattrBoolForName(xattrName))
    }

}
