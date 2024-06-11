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
//  © 2019-2024 1024jp
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

import AppKit
import Testing
@testable import CotEditor

struct NSLayoutManagerTests {
    
    @Test func checkTemporaryAttribute() {
        
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage(string: "cat dog cow")
        textStorage.addLayoutManager(layoutManager)
        
        #expect(!layoutManager.hasTemporaryAttribute(.foregroundColor))
        #expect(!layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(..<0)))
        
        layoutManager.addTemporaryAttribute(.foregroundColor, value: NSColor.green, forCharacterRange: NSRange(4..<7))
        layoutManager.addTemporaryAttribute(.backgroundColor, value: NSColor.white, forCharacterRange: NSRange(6..<8))
        #expect(layoutManager.hasTemporaryAttribute(.foregroundColor))
        #expect(!layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(..<4)))
        #expect(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(3..<6)))
        #expect(layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(6..<8)))
        #expect(!layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(7..<7)))
        #expect(!layoutManager.hasTemporaryAttribute(.foregroundColor, in: NSRange(7..<textStorage.length)))
    }
    
    
    @Test func characterIndex() {
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(NSTextContainer())
        let textStorage = NSTextStorage(string: "dog\r\n 🐕")
        textStorage.addLayoutManager(layoutManager)
        
        // left characters
        #expect(layoutManager.leftCharacterIndex(of: 0, baseWritingDirection: .leftToRight) == 0)
        #expect(layoutManager.leftCharacterIndex(of: 1, baseWritingDirection: .leftToRight) == 0)
        #expect(layoutManager.leftCharacterIndex(of: 2, baseWritingDirection: .leftToRight) == 1)
        #expect(layoutManager.leftCharacterIndex(of: 3, baseWritingDirection: .leftToRight) == 2)
        #expect(layoutManager.leftCharacterIndex(of: 4, baseWritingDirection: .leftToRight) == 2)
        
        #expect(layoutManager.leftCharacterIndex(of: 5, baseWritingDirection: .leftToRight) == 3)
        #expect(layoutManager.leftCharacterIndex(of: 6, baseWritingDirection: .leftToRight) == 5)
        #expect(layoutManager.leftCharacterIndex(of: 7, baseWritingDirection: .leftToRight) == 5)
        #expect(layoutManager.leftCharacterIndex(of: 8, baseWritingDirection: .leftToRight) == 6)

        // right characters
        #expect(layoutManager.rightCharacterIndex(of: 0, baseWritingDirection: .leftToRight) == 1)
        #expect(layoutManager.rightCharacterIndex(of: 1, baseWritingDirection: .leftToRight) == 2)
        #expect(layoutManager.rightCharacterIndex(of: 2, baseWritingDirection: .leftToRight) == 3)
        #expect(layoutManager.rightCharacterIndex(of: 3, baseWritingDirection: .leftToRight) == 5)
        #expect(layoutManager.rightCharacterIndex(of: 4, baseWritingDirection: .leftToRight) == 5)
        
        #expect(layoutManager.rightCharacterIndex(of: 5, baseWritingDirection: .leftToRight) == 6)
        #expect(layoutManager.rightCharacterIndex(of: 6, baseWritingDirection: .leftToRight) == 8)
        #expect(layoutManager.rightCharacterIndex(of: 7, baseWritingDirection: .leftToRight) == 8)
        #expect(layoutManager.rightCharacterIndex(of: 8, baseWritingDirection: .leftToRight) == 8)
    }
    
    
    @Test func bidiCharacterIndex() {
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(NSTextContainer())
        let textStorage = NSTextStorage(string: "كلب\r\n 🐕")
        textStorage.addLayoutManager(layoutManager)
        
        // left characters
        #expect(layoutManager.leftCharacterIndex(of: 0, baseWritingDirection: .leftToRight) == 1)
        #expect(layoutManager.leftCharacterIndex(of: 1, baseWritingDirection: .leftToRight) == 2)
        #expect(layoutManager.leftCharacterIndex(of: 2, baseWritingDirection: .leftToRight) == 3)
        #expect(layoutManager.leftCharacterIndex(of: 3, baseWritingDirection: .leftToRight) == 0)
        #expect(layoutManager.leftCharacterIndex(of: 4, baseWritingDirection: .leftToRight) == 1)
        
        #expect(layoutManager.leftCharacterIndex(of: 5, baseWritingDirection: .leftToRight) == 3)
        #expect(layoutManager.leftCharacterIndex(of: 6, baseWritingDirection: .leftToRight) == 5)
        #expect(layoutManager.leftCharacterIndex(of: 7, baseWritingDirection: .leftToRight) == 5)
        #expect(layoutManager.leftCharacterIndex(of: 8, baseWritingDirection: .leftToRight) == 6)

        // right characters
        #expect(layoutManager.rightCharacterIndex(of: 0, baseWritingDirection: .leftToRight) == 5)
        #expect(layoutManager.rightCharacterIndex(of: 1, baseWritingDirection: .leftToRight) == 0)
        #expect(layoutManager.rightCharacterIndex(of: 2, baseWritingDirection: .leftToRight) == 1)
        #expect(layoutManager.rightCharacterIndex(of: 3, baseWritingDirection: .leftToRight) == 2)
        #expect(layoutManager.rightCharacterIndex(of: 4, baseWritingDirection: .leftToRight) == 5)
        
        #expect(layoutManager.rightCharacterIndex(of: 5, baseWritingDirection: .leftToRight) == 6)
        #expect(layoutManager.rightCharacterIndex(of: 6, baseWritingDirection: .leftToRight) == 8)
        #expect(layoutManager.rightCharacterIndex(of: 7, baseWritingDirection: .leftToRight) == 8)
        #expect(layoutManager.rightCharacterIndex(of: 8, baseWritingDirection: .leftToRight) == 8)
    }
}
