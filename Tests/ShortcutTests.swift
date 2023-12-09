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
        
        XCTAssertEqual(Shortcut("A", modifiers: [.control]),
                       Shortcut("a", modifiers: [.control, .shift]))
        
        XCTAssertEqual(Shortcut(keySpecChars: "^A"),
                       Shortcut(keySpecChars: "^$a"))
    }
    
    
    func testKeySpecCharsCreation() {
        
        XCTAssertNil(Shortcut("", modifiers: []))
        XCTAssertEqual(Shortcut("a", modifiers: [.control, .shift])?.keySpecChars, "^$a")
        XCTAssertEqual(Shortcut("b", modifiers: [.command, .option])?.keySpecChars, "~@b")
        XCTAssertEqual(Shortcut("A", modifiers: [.control])?.keySpecChars, "^$a")  // uppercase for Shift key
        XCTAssertEqual(Shortcut("a", modifiers: [.control, .shift])?.keySpecChars, "^$a")
        
        XCTAssertEqual(Shortcut("a", modifiers: [])?.keySpecChars, "a")
        XCTAssertEqual(Shortcut("a", modifiers: [])?.isValid, false)
        XCTAssertNil(Shortcut("", modifiers: [.control, .shift]))
        XCTAssertEqual(Shortcut("a", modifiers: [.control, .shift])?.isValid, true)
        XCTAssertEqual(Shortcut("ab", modifiers: [.control, .shift])?.isValid, false)
    }
    
    
    func testStringToShortcut() throws {
        
        let shortcut = try XCTUnwrap(Shortcut(keySpecChars: "^$a"))
        
        XCTAssertEqual(shortcut.keyEquivalent, "a")
        XCTAssertEqual(shortcut.modifiers, [.control, .shift])
        XCTAssert(shortcut.isValid)
    }
    
    
    func testShortcutWithFnKey() throws {
        
        let shortcut = try XCTUnwrap(Shortcut("a", modifiers: [.function]))
        
        XCTAssertFalse(shortcut.isValid)
        XCTAssertEqual(shortcut.keyEquivalent, "a")
        XCTAssertEqual(shortcut.modifiers, [.function])
        XCTAssert(shortcut.symbol == "fn A" || shortcut.symbol == "🌐︎ A")
        XCTAssertEqual(shortcut.keySpecChars, "a", "The fn key should be ignored.")
        
        let symbolName = try XCTUnwrap(shortcut.modifierSymbolNames.first)
        XCTAssertNotNil(NSImage(systemSymbolName: symbolName, accessibilityDescription: nil))
    }
    
    
    func testMenuItemShortcut() {
        
        let menuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "C")
        menuItem.keyEquivalentModifierMask = [.command]
        
        let shortcut = Shortcut(menuItem.keyEquivalent, modifiers: menuItem.keyEquivalentModifierMask)
        
        XCTAssertEqual(shortcut?.symbol, "⇧ ⌘ C")
        XCTAssertEqual(shortcut, menuItem.shortcut)
    }
    
    
    func testShortcutSymbols() throws {
        
        // test modifier symbols
        XCTAssertNil(Shortcut(keySpecChars: ""))
        XCTAssertEqual(Shortcut(keySpecChars: "^$a")?.symbol, "^ ⇧ A")
        XCTAssertEqual(Shortcut(keySpecChars: "~@b")?.symbol, "⌥ ⌘ B")
        
        // test unprintable keys
        let f10 = try XCTUnwrap(String(NSEvent.SpecialKey.f10.unicodeScalar))
        XCTAssertEqual(Shortcut(keySpecChars: "@" + f10)?.symbol, "⌘ F10")
        
        let delete = try XCTUnwrap(UnicodeScalar(NSDeleteCharacter).flatMap(String.init))
        XCTAssertEqual(Shortcut(keySpecChars: "@" + delete)?.symbol, "⌘ ⌫")
        
        // test creation
        let deleteForward = try XCTUnwrap(String(NSEvent.SpecialKey.deleteForward.unicodeScalar))
        XCTAssertNil(Shortcut(symbolRepresentation: ""))
        XCTAssertEqual(Shortcut(symbolRepresentation: "^ ⇧ A")?.keySpecChars, "^$a")
        XCTAssertEqual(Shortcut(symbolRepresentation: "⌥ ⌘ B")?.keySpecChars, "~@b")
        XCTAssertEqual(Shortcut(symbolRepresentation: "⌘ F10")?.keySpecChars, "@" + f10)
        XCTAssertEqual(Shortcut(symbolRepresentation: "⌘ ⌦")?.keySpecChars, "@" + deleteForward)
    }
}
