//
//  ShortcutFormatterTests.swift
//  ShortcutTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-06-19.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2026 1024jp
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

struct ShortcutFormatterTests {
    
    @Test func formatter() {
        
        let formatter = ShortcutFormatter()
        
        let shortcut = Shortcut("a", modifiers: [.control, .shift])
        #expect(formatter.string(for: shortcut) ==
                "^ ⇧ A")
        
        var value: AnyObject?
        #expect(unsafe formatter.getObjectValue(&value, for: "^ ⇧ A", errorDescription: nil))
        #expect(value as? Shortcut == shortcut)
    }
    
    
    /// Tests that editing preserves a key even when its display representation is ambiguous.
    ///
    /// - Parameter key: The key string to preserve.
    /// - Throws: If creating the shortcut or editing string fails.
    @Test(arguments: ["ß", "ss", "SS", "aB", "a b", "F10", "Help", "⌦"])
    func editingString(_ key: String) throws {
        
        let formatter = ShortcutFormatter()
        let shortcut = try #require(Shortcut(key, modifiers: [.control, .option]))
        let string = try #require(formatter.editingString(for: shortcut))
        
        var value: AnyObject?
        #expect(unsafe formatter.getObjectValue(&value, for: string, errorDescription: nil))
        #expect((value as? Shortcut)?.keyEquivalent == key)
        #expect((value as? Shortcut)?.modifiers == shortcut.modifiers)
        
        #expect(unsafe formatter.getObjectValue(&value, for: "", errorDescription: nil))
        #expect(value == nil)
    }
    
    
    /// Tests AppKit's validation and focus-loss paths when recording a new shortcut during editing.
    ///
    /// - Parameter key: The newly recorded key string.
    /// - Throws: If creating the shortcut or field editor fails.
    @Test(arguments: ["ß", "ss", "aB", "SS", "a b", "F10", "Help", "⌦"])
    @MainActor func textFieldEditing(_ key: String) throws {
        
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 100), styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        defer { window.close() }
        
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        field.formatter = ShortcutFormatter()
        field.objectValue = Shortcut("ß", modifiers: [.control, .option])
        window.contentView?.addSubview(field)
        #expect(window.makeFirstResponder(field))
        let editor = try #require(field.currentEditor())
        
        let shortcut = try #require(Shortcut(key, modifiers: [.control, .option]))
        field.objectValue = shortcut
        editor.string = field.stringValue
        field.validateEditing()
        #expect((field.objectValue as? Shortcut)?.keyEquivalent == key)
        #expect(window.makeFirstResponder(nil))
        #expect((field.objectValue as? Shortcut)?.keyEquivalent == key)
        #expect((field.objectValue as? Shortcut)?.modifiers == shortcut.modifiers)
    }
}
