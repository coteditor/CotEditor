//
//  NSLayoutManagerTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-12-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2019 1024jp
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

final class NSLayoutManagerTests: XCTestCase {
    
    func testTemporaryAttributeExistance() {
        
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage(string: "cat dog cow")
        textStorage.addLayoutManager(layoutManager)
        
        XCTAssertFalse(layoutManager.hasTemporaryAttribute(.foregroundColor))
        XCTAssertFalse(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(..<0)))
        
        layoutManager.addTemporaryAttribute(.foregroundColor, value: NSColor.green, forCharacterRange: NSRange(4..<7))
        XCTAssertTrue(layoutManager.hasTemporaryAttribute(.foregroundColor))
        XCTAssertFalse(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(..<4)))
        XCTAssertTrue(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(3..<6)))
        XCTAssertTrue(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(6..<8)))
        XCTAssertFalse(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(7..<textStorage.length)))
    }
    
}
