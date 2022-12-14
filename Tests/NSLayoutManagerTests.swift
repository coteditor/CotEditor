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
//  © 2019-2022 1024jp
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
        layoutManager.addTemporaryAttribute(.backgroundColor, value: NSColor.white, forCharacterRange: NSRange(6..<8))
        XCTAssertTrue(layoutManager.hasTemporaryAttribute(.foregroundColor))
        XCTAssertFalse(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(..<4)))
        XCTAssertTrue(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(3..<6)))
        XCTAssertTrue(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(6..<8)))
        XCTAssertFalse(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(7..<7)))
        XCTAssertFalse(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(7..<textStorage.length)))
    }
    
    
    func testLeftCharacterIndex() {
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(NSTextContainer())
        let textStorage = NSTextStorage(string: "dog\r\n 🐕")
        textStorage.addLayoutManager(layoutManager)
        
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 0, baseWritingDirection: .leftToRight), 0)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 1, baseWritingDirection: .leftToRight), 0)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 2, baseWritingDirection: .leftToRight), 1)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 3, baseWritingDirection: .leftToRight), 2)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 4, baseWritingDirection: .leftToRight), 2)
        
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 5, baseWritingDirection: .leftToRight), 3)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 6, baseWritingDirection: .leftToRight), 5)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 7, baseWritingDirection: .leftToRight), 5)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 8, baseWritingDirection: .leftToRight), 6)
    }
    
    
    func testRightCharacterIndex() {
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(NSTextContainer())
        let textStorage = NSTextStorage(string: "dog\r\n 🐕")
        textStorage.addLayoutManager(layoutManager)
        
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 0, baseWritingDirection: .leftToRight), 1)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 1, baseWritingDirection: .leftToRight), 2)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 2, baseWritingDirection: .leftToRight), 3)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 3, baseWritingDirection: .leftToRight), 5)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 4, baseWritingDirection: .leftToRight), 5)
        
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 5, baseWritingDirection: .leftToRight), 6)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 6, baseWritingDirection: .leftToRight), 8)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 7, baseWritingDirection: .leftToRight), 8)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 8, baseWritingDirection: .leftToRight), 8)
    }
    
    
    func testBidiLeftCharacterIndex() {
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(NSTextContainer())
        let textStorage = NSTextStorage(string: "كلب\r\n 🐕")
        textStorage.addLayoutManager(layoutManager)
        
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 0, baseWritingDirection: .leftToRight), 1)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 1, baseWritingDirection: .leftToRight), 2)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 2, baseWritingDirection: .leftToRight), 3)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 3, baseWritingDirection: .leftToRight), 0)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 4, baseWritingDirection: .leftToRight), 1)
        
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 5, baseWritingDirection: .leftToRight), 3)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 6, baseWritingDirection: .leftToRight), 5)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 7, baseWritingDirection: .leftToRight), 5)
        XCTAssertEqual(layoutManager.leftCharacterIndex(of: 8, baseWritingDirection: .leftToRight), 6)
    }
    
    
    func testBidiRightCharacterIndex() {
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(NSTextContainer())
        let textStorage = NSTextStorage(string: "كلب\r\n 🐕")
        textStorage.addLayoutManager(layoutManager)
        
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 0, baseWritingDirection: .leftToRight), 5)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 1, baseWritingDirection: .leftToRight), 0)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 2, baseWritingDirection: .leftToRight), 1)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 3, baseWritingDirection: .leftToRight), 2)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 4, baseWritingDirection: .leftToRight), 5)
        
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 5, baseWritingDirection: .leftToRight), 6)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 6, baseWritingDirection: .leftToRight), 8)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 7, baseWritingDirection: .leftToRight), 8)
        XCTAssertEqual(layoutManager.rightCharacterIndex(of: 8, baseWritingDirection: .leftToRight), 8)
    }
}
