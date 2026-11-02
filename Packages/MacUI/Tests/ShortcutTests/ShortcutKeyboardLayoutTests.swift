//
//  ShortcutKeyboardLayoutTests.swift
//  ShortcutTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-11-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
@testable import Shortcut

@MainActor struct ShortcutKeyboardLayoutTests {
    
    /// Tests that alternative layout characters fall back to the layout's Command-key characters with the original modifiers.
    ///
    /// - Parameters:
    ///   - input: The Command-key characters and original modifiers.
    ///   - shortcut: The recorded shortcut to execute.
    @Test(arguments: [
        (("f", NSEvent.ModifierFlags.control), Shortcut("f", modifiers: .control)),
        (("F", [.control, .shift]), Shortcut("f", modifiers: [.control, .shift])),
        (("<", [.control, .shift]), Shortcut("<", modifiers: .control)),
        (("q", .option), Shortcut("q", modifiers: .option)),
    ] as [((String, NSEvent.ModifierFlags), Shortcut)])
    func alternativeLayoutKeys(_ input: (characters: String, modifiers: NSEvent.ModifierFlags), shortcut: Shortcut) {
        
        #expect(Shortcut(commandLayoutCharacters: input.characters, modifierFlags: input.modifiers, isASCIICapableKeyboardLayout: false) == shortcut)
    }
    
    
    /// Tests that ASCII-capable keyboard layouts do not translate Control or Option input through the Command-key characters.
    ///
    /// - Parameter modifiers: The event's actual modifiers.
    @Test(arguments: [NSEvent.ModifierFlags.control, .option])
    func asciiLayoutPreservesOriginalCharacters(_ modifiers: NSEvent.ModifierFlags) {
        
        #expect(Shortcut(commandLayoutCharacters: "f", modifierFlags: modifiers, isASCIICapableKeyboardLayout: true) == nil)
    }
    
    
    /// Tests that Command shortcuts use the Command-key characters even on an ASCII-capable keyboard layout.
    @Test func commandUsesCommandLayout() {
        
        #expect(Shortcut(commandLayoutCharacters: "f", modifierFlags: .command, isASCIICapableKeyboardLayout: true) == Shortcut("f", modifiers: .command))
    }
    
    
    /// Tests that ordinary input never acquires an alternative layout shortcut.
    ///
    /// - Parameter modifiers: The original modifier flags.
    @Test(arguments: [NSEvent.ModifierFlags(), .shift])
    func preservesText(_ modifiers: NSEvent.ModifierFlags) {
        
        #expect(Shortcut(commandLayoutCharacters: "q", modifierFlags: modifiers, isASCIICapableKeyboardLayout: false) == nil)
    }
    
    
    /// Tests that special keys never acquire an alternative layout shortcut, such as Backspace turning into Forward Delete.
    ///
    /// - Throws: If creating the event fails.
    @Test func preservesSpecialKeys() throws {
        
        let event = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command,
                                                  timestamp: 0, windowNumber: 0, context: nil, characters: "\u{7F}",
                                                  charactersIgnoringModifiers: "\u{7F}", isARepeat: false, keyCode: 51))
        
        #expect(Shortcut(keyDownEventUsingCommandLayout: event) == nil)
    }
}
