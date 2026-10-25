//
//  TextKeyBindingMapTests.swift
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
import Testing
import Shortcut
@testable import CotEditor

@MainActor struct TextKeyBindingMapTests {
    
    /// Tests that an uncustomized map leaves interpretation to AppKit.
    @Test func inheritsSystemBindings() {
        
        let map = TextKeyBindingMap()
        
        #expect(!map.isCustomized)
        #expect(map.action(for: Shortcut(.home, modifiers: [])) == nil)
        #expect(map.action(for: Shortcut(.leftArrow, modifiers: .command)) == nil)
        #expect(map.shortcuts(for: .moveToLeftEndOfLine) == [Shortcut(.leftArrow, modifiers: .command)])
    }
    
    
    /// Tests assigning a key that normally belongs to another system command.
    ///
    /// - Throws: If assigning the shortcut fails.
    @Test func replacesDefaultShortcut() throws {
        
        var map = TextKeyBindingMap()
        let home = Shortcut(.home, modifiers: [])
        try map.setShortcuts([home], for: .moveToLeftEndOfLine)
        
        #expect(map.isCustomized)
        #expect(map.action(for: home) == .perform(.moveToLeftEndOfLine))
        #expect(map.action(for: Shortcut(.leftArrow, modifiers: .command)) == .suppress)
        #expect(map.action(for: Shortcut(.end, modifiers: [])) == nil)
        #expect(map.shortcuts(for: .moveToLeftEndOfLine) == [home])
        #expect(map.shortcuts(for: .scrollToBeginningOfDocument).isEmpty)
    }
    
    
    /// Tests that disabling a command suppresses each of its managed default shortcuts.
    ///
    /// - Throws: If disabling the command fails.
    @Test func disablesAllDefaultAliases() throws {
        
        var map = TextKeyBindingMap()
        try map.setShortcuts([], for: .deleteForward)
        
        #expect(map.isCustomized)
        #expect(map.shortcuts(for: .deleteForward).isEmpty)
        #expect(map.action(for: Shortcut("d", modifiers: .control)) == .suppress)
        #expect(map.action(for: Shortcut(.deleteForward, modifiers: [])) == .suppress)
    }
    
    
    /// Tests that multiple assignments retain their order and discard duplicate keys.
    ///
    /// - Throws: If assigning the shortcuts fails.
    @Test func multipleShortcuts() throws {
        
        var map = TextKeyBindingMap()
        let home = Shortcut(.home, modifiers: [])
        let f6 = Shortcut(.f6, modifiers: [])
        try map.setShortcuts([home, f6, home], for: .deleteForward)
        
        #expect(map.shortcuts(for: .deleteForward) == [home, f6])
        #expect(map.action(for: home) == .perform(.deleteForward))
        #expect(map.action(for: f6) == .perform(.deleteForward))
        #expect(map.action(for: Shortcut(.deleteForward, modifiers: [])) == .suppress)
    }
    
    
    /// Tests retaining one default alias while suppressing another.
    ///
    /// - Throws: If updating the shortcuts fails.
    @Test func keepsOneDefaultAlias() throws {
        
        var map = TextKeyBindingMap()
        let controlD: Shortcut = Shortcut("d", modifiers: .control)
        try map.setShortcuts([controlD], for: .deleteForward)
        
        #expect(map.isCustomized)
        #expect(map.action(for: controlD) == .perform(.deleteForward))
        #expect(map.action(for: Shortcut(.deleteForward, modifiers: [])) == .suppress)
    }
    
    
    /// Tests restoring one command without removing another command's customization.
    ///
    /// - Throws: If updating the shortcuts fails.
    @Test func restoresSingleCommand() throws {
        
        var map = TextKeyBindingMap()
        try map.setShortcuts([Shortcut(.home, modifiers: [])], for: .moveToLeftEndOfLine)
        try map.setShortcuts([Shortcut(.end, modifiers: [])], for: .moveToRightEndOfLine)
        try map.setShortcuts(nil, for: .moveToLeftEndOfLine)
        
        #expect(map.isCustomized)
        #expect(map.action(for: Shortcut(.home, modifiers: [])) == nil)
        #expect(map.action(for: Shortcut(.leftArrow, modifiers: .command)) == nil)
        #expect(map.action(for: Shortcut(.end, modifiers: [])) == .perform(.moveToRightEndOfLine))
        #expect(map.action(for: Shortcut(.rightArrow, modifiers: .command)) == .suppress)
        #expect(map.shortcuts(for: .scrollToBeginningOfDocument) == [Shortcut(.home, modifiers: [])])
    }
    
    
    /// Tests that assigning the default keys, in any order, restores system interpretation.
    ///
    /// - Throws: If updating the shortcuts fails.
    @Test func defaultShortcutsRestoreInheritance() throws {
        
        var map = TextKeyBindingMap()
        try map.setShortcuts([Shortcut(.home, modifiers: [])], for: .deleteForward)
        try map.setShortcuts([Shortcut(.deleteForward, modifiers: []), Shortcut("d", modifiers: .control)], for: .deleteForward)
        
        #expect(!map.isCustomized)
        #expect(map.action(for: Shortcut(.home, modifiers: [])) == nil)
        #expect(map.action(for: Shortcut("d", modifiers: .control)) == nil)
        #expect(map.action(for: Shortcut(.deleteForward, modifiers: [])) == nil)
    }
    
    
    /// Tests that explicit assignments win over suppression even when a command is restored or disabled.
    ///
    /// - Throws: If updating the shortcuts fails.
    @Test func assignmentTakesPriorityOverSuppression() throws {
        
        var map = TextKeyBindingMap()
        let commandLeft = Shortcut(.leftArrow, modifiers: .command)
        try map.setShortcuts([Shortcut(.home, modifiers: [])], for: .moveToLeftEndOfLine)
        try map.setShortcuts([commandLeft], for: .moveToRightEndOfLine)
        
        #expect(map.action(for: commandLeft) == .perform(.moveToRightEndOfLine))
        
        try map.setShortcuts([], for: .moveToLeftEndOfLine)
        #expect(map.action(for: commandLeft) == .perform(.moveToRightEndOfLine))
        #expect(map.action(for: Shortcut(.home, modifiers: [])) == nil)
        
        try map.setShortcuts(nil, for: .moveToLeftEndOfLine)
        #expect(map.action(for: commandLeft) == .perform(.moveToRightEndOfLine))
    }
    
    
    /// Tests that conflicting assignments leave the entire map unchanged.
    ///
    /// - Throws: If creating the initial assignment fails.
    @Test func rejectsConflictingAssignmentAtomically() throws {
        
        var map = TextKeyBindingMap()
        let home = Shortcut(.home, modifiers: [])
        try map.setShortcuts([home], for: .moveToLeftEndOfLine)
        let previous = map
        
        #expect(throws: Shortcut.CustomizationError.self) {
            try map.setShortcuts([Shortcut(.f6, modifiers: []), home], for: .moveToRightEndOfLine)
        }
        #expect(map == previous)
    }
    
    
    /// Tests that equivalent Shift and uppercase-key representations conflict.
    ///
    /// - Throws: If creating the initial assignment fails.
    @Test func rejectsNormalizedDuplicates() throws {
        
        var map = TextKeyBindingMap()
        try map.setShortcuts([Shortcut("H", modifiers: .control)], for: .moveToLeftEndOfLine)
        
        #expect(throws: Shortcut.CustomizationError.self) {
            try map.setShortcuts([Shortcut("h", modifiers: [.control, .shift])], for: .moveToRightEndOfLine)
        }
    }
    
    
    /// Tests that changing an assignment releases the previously customized key.
    ///
    /// - Throws: If updating the shortcuts fails.
    @Test func releasesPreviousShortcut() throws {
        
        var map = TextKeyBindingMap()
        let home = Shortcut(.home, modifiers: [])
        let f6 = Shortcut(.f6, modifiers: [])
        try map.setShortcuts([home], for: .moveToLeftEndOfLine)
        try map.setShortcuts([f6], for: .moveToLeftEndOfLine)
        
        #expect(map.action(for: home) == nil)
        #expect(map.action(for: f6) == .perform(.moveToLeftEndOfLine))
        #expect(map.action(for: Shortcut(.leftArrow, modifiers: .command)) == .suppress)
    }
    
    
    /// Tests restoring all commands, including explicitly disabled commands.
    ///
    /// - Throws: If creating the customizations fails.
    @Test func restoresAllDefaults() throws {
        
        var map = TextKeyBindingMap()
        try map.setShortcuts([Shortcut(.home, modifiers: [])], for: .moveToLeftEndOfLine)
        try map.setShortcuts([], for: .deleteForward)
        map.restoreDefaults()
        
        #expect(map == TextKeyBindingMap())
        #expect(map.customizations.isEmpty)
    }
    
    
    /// Tests preserving multiple aliases, disabled commands, and system inheritance through storage.
    ///
    /// - Throws: If configuring, encoding, or decoding the bindings fails.
    @Test func propertyListRoundTrip() throws {
        
        var map = TextKeyBindingMap()
        let home = Shortcut(.home, modifiers: [])
        try map.setShortcuts([home, Shortcut(.f6, modifiers: [])], for: .moveToLeftEndOfLine)
        try map.setShortcuts([], for: .deleteWordBackward)
        try map.setShortcuts([Shortcut(.deleteForward, modifiers: [])], for: .deleteForward)
        
        let data = try PropertyListEncoder().encode(map)
        let decoded = try PropertyListDecoder().decode(TextKeyBindingMap.self, from: data)
        let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [[String: Any]])
        let actions = try plist.map { try #require($0["action"] as? String) }
        let movement = try #require(plist.first { $0["action"] as? String == "moveToLeftEndOfLine:" })
        let deletion = try #require(plist.first { $0["action"] as? String == "deleteWordBackward:" })
        
        #expect(actions == actions.sorted())
        #expect(!actions.contains("moveUp:"))
        for entry in plist {
            #expect(Set(entry.keys) == ["action", "shortcuts"])
        }
        #expect(movement["shortcuts"] as? [String] == [home.keySpecChars, Shortcut(.f6, modifiers: []).keySpecChars])
        #expect((deletion["shortcuts"] as? [String])?.isEmpty == true)
        #expect(decoded == map)
        #expect(decoded.action(for: home) == .perform(.moveToLeftEndOfLine))
        #expect(decoded.action(for: Shortcut("d", modifiers: .control)) == .suppress)
        #expect(decoded.action(for: Shortcut(.deleteForward, modifiers: [])) == .perform(.deleteForward))
    }
    
    
    /// Tests ignoring command names that this application version does not support.
    ///
    /// - Throws: If encoding or decoding the test data fails.
    @Test func ignoresUnknownStoredCommands() throws {
        
        let entries = [
            TextKeyBinding(action: NSSelectorFromString("unknownCommand:"), shortcuts: [Shortcut("q", modifiers: .control)]),
            TextKeyBinding(action: TextKeyBindingCommand.deleteForward.action, shortcuts: []),
        ]
        let data = try PropertyListEncoder().encode(entries)
        let map = try PropertyListDecoder().decode(TextKeyBindingMap.self, from: data)
        
        #expect(map.customizations == [.deleteForward: []])
    }
    
    
    /// Tests rejecting conflicting shortcuts, malformed shortcuts, and duplicate action records.
    ///
    /// - Parameter entries: The invalid action and shortcut records to decode.
    /// - Throws: If encoding the test data fails.
    @Test(arguments: [
        [("moveToLeftEndOfLine:", ["^q"]), ("moveToRightEndOfLine:", ["^q"])],
        [("moveToLeftEndOfLine:", [""])],
        [("moveToLeftEndOfLine:", []), ("moveToLeftEndOfLine:", ["^q"])],
    ] as [[(String, [String])]])
    func rejectsInvalidStoredBindings(entries: [(action: String, shortcuts: [String])]) throws {
        
        let plist: [[String: Any]] = entries.map { ["action": $0.action, "shortcuts": $0.shortcuts] }
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        
        #expect(throws: (any Error).self) {
            try PropertyListDecoder().decode(TextKeyBindingMap.self, from: data)
        }
    }
    
    
    /// Tests rejecting an Fn customization instead of silently dropping its modifier during encoding.
    ///
    /// - Throws: If configuring the test binding fails.
    @Test func rejectsUnstorableModifier() throws {
        
        var map = TextKeyBindingMap()
        try map.setShortcuts([Shortcut("q", modifiers: .function)], for: .moveToLeftEndOfLine)
        
        #expect(throws: EncodingError.self) {
            try PropertyListEncoder().encode(map)
        }
    }
}
