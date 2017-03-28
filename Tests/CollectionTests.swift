/*
 
 CollectionTests.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-03-29.
 
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

class CollectionTests: XCTestCase {
    
    func testCount() {
        
        XCTAssertEqual([1, 2, 0, -1, 3].count(while: { $0 > 0 }), 2)
        XCTAssertEqual([0, 1, 2, 0, -1].count(while: { $0 > 0 }), 0)
        XCTAssertEqual([1, 2, 3, 4, 5].count(while: { $0 > 0 }), 5)
    }
    
}
