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
        XCTAssertEqual(CEKeyBindingUtils.keySpecChars(fromKeyEquivalent: "a", modifierMask: [.control, .shift]), "^$a")
        XCTAssertEqual(CEKeyBindingUtils.keySpecChars(fromKeyEquivalent: "b", modifierMask: [.command, .option]), "~@b")
        XCTAssertEqual(CEKeyBindingUtils.keySpecChars(fromKeyEquivalent: "A", modifierMask: [.control]), "^$A")  // uppercase for Shift key
        
        XCTAssertEqual(CEKeyBindingUtils.keySpecChars(fromKeyEquivalent: "a", modifierMask: []), "a")
        XCTAssertEqual(CEKeyBindingUtils.keySpecChars(fromKeyEquivalent: "", modifierMask: [.control, .shift]), "")
    }
    
    
    func testStringToKeyEquivalentAndModifierMask() {
        var modifierMask = NSEventModifierFlags()
        let keyEquivalent = CEKeyBindingUtils.keyEquivalentAndModifierMask(&modifierMask, fromKeySpecChars: "^$a", requiresCommandKey: false)
        
        XCTAssertEqual(keyEquivalent, "a")
        XCTAssertEqual(modifierMask, [.control, .shift])
    }
    
    
    func testStringToKeyEquivalentAndModifierMaskWithoutCommandKey() {
        var modifierMask = NSEventModifierFlags()
        let keyEquivalent = CEKeyBindingUtils.keyEquivalentAndModifierMask(&modifierMask, fromKeySpecChars: "^$a", requiresCommandKey: true)
        
        XCTAssertEqual(keyEquivalent, "")
        XCTAssertEqual(modifierMask, [])
    }
    
    
    func testPrintableShortcutKey () {
        // test modifier symbols
        XCTAssertEqual(CEKeyBindingUtils.printableKeyString(fromKeySpecChars: "^$a"), "^⇧A")
        XCTAssertEqual(CEKeyBindingUtils.printableKeyString(fromKeySpecChars: "~@b"), "⌥⌘B")
        
        // test unprintable keys
        let F10 = String(UnicodeScalar(NSF10FunctionKey))
        XCTAssertEqual(CEKeyBindingUtils.printableKeyString(fromKeySpecChars: "@" + F10), "⌘F10")
        
        let delete = String(UnicodeScalar(NSDeleteCharacter))
        XCTAssertEqual(CEKeyBindingUtils.printableKeyString(fromKeySpecChars: "@" + delete), "⌘⌦")
    }

}
