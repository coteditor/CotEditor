/*
 
 KeyBindingsTests.swift
 Tests
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-04.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

class KeyBindingsTests: XCTestCase {
    
    func testKeySpecCharsCreation() {
        XCTAssertEqual(KeyBindingUtils.keySpecChars(keyEquivalent: "a", modifierMask: [.control, .shift]), "^$a")
        XCTAssertEqual(KeyBindingUtils.keySpecChars(keyEquivalent: "b", modifierMask: [.command, .option]), "~@b")
        XCTAssertEqual(KeyBindingUtils.keySpecChars(keyEquivalent: "A", modifierMask: [.control]), "^$A")  // uppercase for Shift key
        
        XCTAssertEqual(KeyBindingUtils.keySpecChars(keyEquivalent: "a", modifierMask: []), "a")
        XCTAssertEqual(KeyBindingUtils.keySpecChars(keyEquivalent: "", modifierMask: [.control, .shift]), "")
    }
    
    
    func testStringToKeyEquivalentAndModifierMask() {
        let (keyEquivalent, modifierMask) = KeyBindingUtils.keyEquivalentAndModifierMask(keySpecChars: "^$a", requiresCommandKey: false)
        
        XCTAssertEqual(keyEquivalent, "a")
        XCTAssertEqual(modifierMask, [.control, .shift])
    }
    
    
    func testStringToKeyEquivalentAndModifierMaskWithoutCommandKey() {
        let (keyEquivalent, modifierMask) = KeyBindingUtils.keyEquivalentAndModifierMask(keySpecChars: "^$a", requiresCommandKey: true)
        
        XCTAssertEqual(keyEquivalent, "")
        XCTAssertEqual(modifierMask, [])
    }
    
    
    func testPrintableShortcutKey () {
        // test modifier symbols
        XCTAssertEqual(KeyBindingUtils.printableKeyString(keySpecChars: "^$a"), "^⇧A")
        XCTAssertEqual(KeyBindingUtils.printableKeyString(keySpecChars: "~@b"), "⌥⌘B")
        
        // test unprintable keys
        let F10 = String(UnicodeScalar(NSF10FunctionKey))
        XCTAssertEqual(KeyBindingUtils.printableKeyString(keySpecChars: "@" + F10), "⌘F10")
        
        let delete = String(UnicodeScalar(NSDeleteCharacter))
        XCTAssertEqual(KeyBindingUtils.printableKeyString(keySpecChars: "@" + delete), "⌘⌦")
    }

}
