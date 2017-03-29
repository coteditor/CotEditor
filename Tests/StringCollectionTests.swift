/*
 
 StringCollectionTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-03-19.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import XCTest
@testable import CotEditor

class StringCollectionTests: XCTestCase {
    
    func testAvailableNameCreation() {
        
        let names = ["foo", "foo 3", "foo copy 3", "foo 4", "foo 7"]
        let copy = "copy"
        
        XCTAssertEqual(names.createAvailableName(for: "foo"), "foo 2")
        XCTAssertEqual(names.createAvailableName(for: "foo 3"), "foo 5")
        
        XCTAssertEqual(names.createAvailableName(for: "foo", suffix: copy), "foo copy")
        XCTAssertEqual(names.createAvailableName(for: "foo 3", suffix: copy), "foo 3 copy")
        XCTAssertEqual(names.createAvailableName(for: "foo copy 3", suffix: copy), "foo copy 4")
    }
    
}
