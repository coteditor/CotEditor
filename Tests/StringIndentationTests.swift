/*
 
 StringIndentationTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-11-24.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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

class StringIndentationTests: XCTestCase {
    
    // MARK: Indentation Style Detection Tests
    
    func testIndentStyleDetection() {
        let string = "\t\tfoo\tbar"
        
        XCTAssertEqual(string.detectIndentStyle(), CEIndentStyle.notFound)
    }
    
    
    // MARK: Indentation Style Standardization Tests
    
    func testIndentStyleStandardizationToTab() {
        let string = "     foo    bar\n  "
        
        // NotFound
        XCTAssertEqual(string.standardizingIndentStyle(to: .notFound, tabWidth: 2), string)
        
        // spaces to tab
        XCTAssertEqual(string.standardizingIndentStyle(to: .tab, tabWidth: 2), "\t\t foo    bar\n\t")
        XCTAssertEqual(string.standardizingIndentStyle(to: .space, tabWidth: 2), string)
    }
    
    
    func testIndentStyleStandardizationToSpace() {
        let string = "\t\tfoo\tbar"
        
        XCTAssertEqual(string.standardizingIndentStyle(to: .space, tabWidth: 2), "    foo\tbar")
        XCTAssertEqual(string.standardizingIndentStyle(to: .tab, tabWidth: 2), string)
    }
    
    
    // MARK: Other Tests
    
    func testIndentCreation() {
        XCTAssertEqual(NSString(spaces: 1), " ")
        XCTAssertEqual(NSString(spaces: 4), "    ")
    }
    
    
    func testIndentLevelDetection() {
        XCTAssertEqual("    foo".indentLevel(atLocation: 0, tabWidth:0), 0)
        
        XCTAssertEqual("    foo".indentLevel(atLocation: 0, tabWidth:4), 1)
        XCTAssertEqual("    foo".indentLevel(atLocation: 4, tabWidth:2), 2)
        XCTAssertEqual("\tfoo".indentLevel(atLocation: 4, tabWidth:2), 1)
        
        // tab-space mix
        XCTAssertEqual("  \t foo".indentLevel(atLocation: 4, tabWidth:2), 2)
        XCTAssertEqual("   \t foo".indentLevel(atLocation: 4, tabWidth:2), 3)
        
        // multiline
        XCTAssertEqual("    foo\n  bar".indentLevel(atLocation: 10, tabWidth:2), 1)
    }

}
