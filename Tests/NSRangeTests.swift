//
//  NSRangeTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-02-14.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

final class NSRangeTests: XCTestCase {

    func testBoundaryTouch() {
        
        XCTAssert(NSRange(location: 2, length: 2).touches(NSRange(location: 4, length: 2)))
        XCTAssert(NSRange(location: 2, length: 2).touches(NSRange(location: 0, length: 2)))
        
        XCTAssert(NSRange(location: 2, length: 0).touches(NSRange(location: 2, length: 2)))
        XCTAssert(NSRange(location: 2, length: 0).touches(NSRange(location: 0, length: 2)))
        XCTAssert(NSRange(location: 2, length: 2).touches(NSRange(location: 2, length: 0)))
        XCTAssert(NSRange(location: 2, length: 2).touches(NSRange(location: 4, length: 0)))
        
        XCTAssert(NSRange(location: 2, length: 2).touches(2))
        XCTAssert(NSRange(location: 2, length: 2).touches(4))
    }
    
    
    func testNotFound() {
        
        XCTAssert(NSRange.notFound.isNotFound)
        XCTAssert(NSRange.notFound.isEmpty)
        XCTAssert(NSRange(location: NSNotFound, length: 1).isNotFound)
        XCTAssertFalse(NSRange(location: 1, length: 1).isNotFound)
    }

}
