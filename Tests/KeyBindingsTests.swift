/*
 
 KeyBindingsTests.swift
 Tests
 
 CotEditor
 http://coteditor.com
 
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
    
    func testStringToKeyEquivalentAndModifierMask() {
        var modifierMask = NSEventModifierFlags()
        let keyEquivalent = CEKeyBindingUtils.keyEquivalentAndModifierMask(&modifierMask, fromString: "$^a", includingCommandKey: false)
        
        XCTAssertEqual(keyEquivalent, "a")
        XCTAssertEqual(modifierMask, [.ControlKeyMask, .ShiftKeyMask])
    }
    
    
    func testStringToKeyEquivalentAndModifierMaskWithoutCommandKey() {
        var modifierMask = NSEventModifierFlags()
        let keyEquivalent = CEKeyBindingUtils.keyEquivalentAndModifierMask(&modifierMask, fromString: "$^a", includingCommandKey: true)
        
        XCTAssertEqual(keyEquivalent, "")
        XCTAssertEqual(modifierMask, [])
    }

}
