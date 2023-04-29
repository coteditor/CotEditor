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
//  © 2016-2023 1024jp
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
    
    func testEquivalent() {
        
        XCTAssertEqual(Shortcut(modifierMask: [.control], keyEquivalent: "A"),
                       Shortcut(modifierMask: [.control, .shift], keyEquivalent: "a"))
        
        XCTAssertEqual(Shortcut(keySpecChars: "^A"),
                       Shortcut(keySpecChars: "^$a"))
    }
    
    
    func testKeySpecCharsCreation() {
        
        XCTAssertNil(Shortcut(modifierMask: [], keyEquivalent: ""))
        XCTAssertEqual(Shortcut(modifierMask: [.control, .shift], keyEquivalent: "a")?.keySpecChars, "^$a")
        XCTAssertEqual(Shortcut(modifierMask: [.command, .option], keyEquivalent: "b")?.keySpecChars, "~@b")
        XCTAssertEqual(Shortcut(modifierMask: [.control], keyEquivalent: "A")?.keySpecChars, "^$a")  // uppercase for Shift key
        XCTAssertEqual(Shortcut(modifierMask: [.control, .shift], keyEquivalent: "a")?.keySpecChars, "^$a")
        
        XCTAssertEqual(Shortcut(modifierMask: [], keyEquivalent: "a")?.keySpecChars, "a")
        XCTAssertNil(Shortcut(modifierMask: [.control, .shift], keyEquivalent: ""))
        XCTAssertEqual(Shortcut(modifierMask: [.control, .shift], keyEquivalent: "a")?.isValid, true)
        XCTAssertEqual(Shortcut(modifierMask: [.control, .shift], keyEquivalent: "ab")?.isValid, false)
    }
    
    
    func testStringToShortcut() throws {
        
        let shortcut = try XCTUnwrap(Shortcut(keySpecChars: "^$a"))
        
        XCTAssertEqual(shortcut.keyEquivalent, "a")
        XCTAssertEqual(shortcut.modifierMask, [.control, .shift])
    }
    
    
    func testMenuItemShortcut() {
        
        let menuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "C")
        menuItem.keyEquivalentModifierMask = [.command]
        
        let shortcut = Shortcut(modifierMask: menuItem.keyEquivalentModifierMask, keyEquivalent: menuItem.keyEquivalent)
        
        XCTAssertEqual(shortcut?.symbol, "⇧ ⌘ C")
    }
    
    
    func testShortcutSymbols() throws {
        
        // test modifier symbols
        XCTAssertNil(Shortcut(keySpecChars: ""))
        XCTAssertEqual(Shortcut(keySpecChars: "^$a")?.symbol, "^ ⇧ A")
        XCTAssertEqual(Shortcut(keySpecChars: "~@b")?.symbol, "⌥ ⌘ B")
        
        // test unprintable keys
        
        let f10 = try XCTUnwrap(UnicodeScalar(NSF10FunctionKey).flatMap(String.init))
        XCTAssertEqual(Shortcut(keySpecChars: "@" + f10)?.symbol, "⌘ F10")
        
        let delete = try XCTUnwrap(UnicodeScalar(NSDeleteCharacter).flatMap(String.init))
        XCTAssertEqual(Shortcut(keySpecChars: "@" + String(delete))?.symbol, "⌘ ⌦")
        
        // test creation
        XCTAssertNil(Shortcut(symbolRepresentation: ""))
        XCTAssertEqual(Shortcut(symbolRepresentation: "^ ⇧ A")?.keySpecChars, "^$a")
        XCTAssertEqual(Shortcut(symbolRepresentation: "⌥ ⌘ B")?.keySpecChars, "~@b")
        XCTAssertEqual(Shortcut(symbolRepresentation: "⌘ F10")?.keySpecChars, "@" + f10)
        XCTAssertEqual(Shortcut(symbolRepresentation: "⌘ ⌦")?.keySpecChars, "@" + delete)
    }
}
