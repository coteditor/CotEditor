//
//  ShortcutTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2022 1024jp
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

final class ShortcutTests: XCTestCase {
    
    func testKeySpecCharsCreation() {
        
        XCTAssertEqual(Shortcut(modifierMask: [.control, .shift], keyEquivalent: "a").keySpecChars, "^$a")
        XCTAssertEqual(Shortcut(modifierMask: [.command, .option], keyEquivalent: "b").keySpecChars, "~@b")
        XCTAssertEqual(Shortcut(modifierMask: [.control], keyEquivalent: "A").keySpecChars, "^$A")  // uppercase for Shift key
        
        XCTAssertEqual(Shortcut(modifierMask: [], keyEquivalent: "a").keySpecChars, "a")
        XCTAssertEqual(Shortcut(modifierMask: [.control, .shift], keyEquivalent: "").keySpecChars, "^$")
        XCTAssertFalse(Shortcut(modifierMask: [.control, .shift], keyEquivalent: "").isValid)
        XCTAssertFalse(Shortcut(modifierMask: [.control, .shift], keyEquivalent: "").isEmpty)
        XCTAssertTrue(Shortcut(modifierMask: [.control, .shift], keyEquivalent: "a").isValid)
        XCTAssertFalse(Shortcut(modifierMask: [.control, .shift], keyEquivalent: "ab").isValid)
        XCTAssertTrue(Shortcut.none.isEmpty)
    }
    
    
    func testStringToShortcut() {
        
        let shortcut = Shortcut(keySpecChars: "^$a")
        
        XCTAssertEqual(shortcut.keyEquivalent, "a")
        XCTAssertEqual(shortcut.modifierMask, [.control, .shift])
    }
    
    
    func testShortcutSymbols () {
        
        // test modifier symbols
        XCTAssertEqual(Shortcut(keySpecChars: "^$a").description, "^ ⇧ A")
        XCTAssertEqual(Shortcut(keySpecChars: "~@b").description, "⌥ ⌘ B")
        
        // test unprintable keys
        let f10 = String(UnicodeScalar(NSF10FunctionKey)!)
        XCTAssertEqual(Shortcut(keySpecChars: "@" + f10).description, "⌘ F10")
        
        let delete = String(UnicodeScalar(NSDeleteCharacter)!)
        XCTAssertEqual(Shortcut(keySpecChars: "@" + delete).description, "⌘ ⌦")
    }
}
