//
//  StringIndentationTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-11-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2018 1024jp
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

class StringIndentationTests: XCTestCase {
    
    // MARK: Indentation Style Detection Tests
    
    func testIndentStyleDetection() {
        
        let string = "\t\tfoo\tbar"
        
        XCTAssertNil(string.detectedIndentStyle)
    }
    
    
    // MARK: Indentation Style Standardization Tests
    
    func testIndentStyleStandardizationToTab() {
        
        let string = "     foo    bar\n  "
        
        // spaces to tab
        XCTAssertEqual(string.standardizingIndent(to: .tab, tabWidth: 2), "\t\t foo    bar\n\t")
        XCTAssertEqual(string.standardizingIndent(to: .space, tabWidth: 2), string)
    }
    
    
    func testIndentStyleStandardizationToSpace() {
        
        let string = "\t\tfoo\tbar"
        
        XCTAssertEqual(string.standardizingIndent(to: .space, tabWidth: 2), "    foo\tbar")
        XCTAssertEqual(string.standardizingIndent(to: .tab, tabWidth: 2), string)
    }
    
    
    // MARK: Other Tests
    
    func testIndentLevelDetection() {
        
        XCTAssertEqual("    foo".indentLevel(at: 0, tabWidth: 4), 1)
        XCTAssertEqual("    foo".indentLevel(at: 4, tabWidth: 2), 2)
        XCTAssertEqual("\tfoo".indentLevel(at: 4, tabWidth: 2), 1)
        
        // tab-space mix
        XCTAssertEqual("  \t foo".indentLevel(at: 4, tabWidth: 2), 2)
        XCTAssertEqual("   \t foo".indentLevel(at: 4, tabWidth: 2), 3)
        
        // multiline
        XCTAssertEqual("    foo\n  bar".indentLevel(at: 10, tabWidth: 2), 1)
    }
    
    
    func testSoftTabDeletion() {
        
        let string = "     foo\n  bar"
        
        XCTAssertNil(string.rangeForSoftTabDeletion(in: NSRange(0..<0), tabWidth: 2))
        XCTAssertNil(string.rangeForSoftTabDeletion(in: NSRange(4..<5), tabWidth: 2))
        XCTAssertNil(string.rangeForSoftTabDeletion(in: NSRange(6..<6), tabWidth: 2))
        XCTAssertEqual(string.rangeForSoftTabDeletion(in: NSRange(5..<5), tabWidth: 2)!, NSRange(4..<5))
        XCTAssertEqual(string.rangeForSoftTabDeletion(in: NSRange(4..<4), tabWidth: 2)!, NSRange(2..<4))
        XCTAssertEqual(string.rangeForSoftTabDeletion(in: NSRange(10..<10), tabWidth: 2)!, NSRange(9..<10))
    }

}


private extension String {
    
    func indentLevel(at location: Int, tabWidth: Int) -> Int {
        
        let index = self.index(self.startIndex, offsetBy: location)
        
        return self.indentLevel(at: index, tabWidth: tabWidth)
    }
    
}
