//
//  TextKeyBindingCommandTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-25.
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
import Foundation
import Testing
import Shortcut
@testable import CotEditor

@MainActor struct TextKeyBindingCommandTests {
    
    /// Tests that actual key-event representations match the default text editing bindings.
    ///
    /// - Parameters:
    ///   - command: The command invoked by the event.
    ///   - input: The event's key character, modifier flags, and virtual key code.
    /// - Throws: If creating the event or shortcut fails.
    @Test(arguments: [
        (TextKeyBindingCommand.deleteBackward, ("h", NSEvent.ModifierFlags.control, UInt16(4))),
        (.deleteForward, ("d", .control, 2)),
        (.deleteToEndOfParagraph, ("k", .control, 40)),
        (.moveToBeginningOfParagraph, ("a", .control, 0)),
        (.moveToEndOfParagraph, ("e", .control, 14)),
        (.moveForward, ("f", .control, 3)),
        (.moveBackward, ("b", .control, 11)),
        (.moveUp, ("p", .control, 35)),
        (.moveDown, ("n", .control, 45)),
        (.transpose, ("t", .control, 17)),
        (.deleteForward, ("\u{F728}", .function, 117)),
        (.deleteWordBackward, ("\u{7F}", .option, 51)),
        (.scrollPageUp, ("\u{F72C}", .function, 116)),
        (.scrollPageDown, ("\u{F72D}", .function, 121)),
        (.scrollToBeginningOfDocument, ("\u{F729}", .function, 115)),
        (.scrollToEndOfDocument, ("\u{F72B}", .function, 119)),
        (.moveToLeftEndOfLine, ("\u{F702}", [.command, .function, .numericPad], 123)),
        (.moveToRightEndOfLine, ("\u{F703}", [.command, .function, .numericPad], 124)),
        (.moveLeftAndModifySelection, ("\u{F702}", [.shift, .function, .numericPad], 123)),
        (.moveRightAndModifySelection, ("\u{F703}", [.shift, .function, .numericPad], 124)),
    ] as [(TextKeyBindingCommand, (String, NSEvent.ModifierFlags, UInt16))])
    func defaultEvent(_ command: TextKeyBindingCommand, input: (key: String, modifiers: NSEvent.ModifierFlags, keyCode: UInt16)) throws {
        
        let event = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: input.modifiers,
                                                  timestamp: 0, windowNumber: 0, context: nil, characters: input.key,
                                                  charactersIgnoringModifiers: input.key, isARepeat: false, keyCode: input.keyCode))
        let shortcut = try #require(Shortcut(keyDownEvent: event))
        
        #expect(command.shortcuts.contains(shortcut))
    }
    
    
    /// Tests that default text bindings preserve their shortcuts through property-list storage.
    ///
    /// - Parameter command: The command whose default bindings are encoded.
    /// - Throws: If encoding or decoding the bindings fails.
    @Test(arguments: TextKeyBindingCommand.allCases)
    func defaultBindingsRoundTrip(_ command: TextKeyBindingCommand) throws {
        
        let binding = TextKeyBinding(action: command.action, shortcuts: command.shortcuts)
        let data = try PropertyListEncoder().encode(binding)
        let decoded = try PropertyListDecoder().decode(TextKeyBinding.self, from: data)
        
        #expect(decoded.action == command.action)
        #expect(decoded.shortcuts == command.shortcuts)
    }
}
