//
//  TextKeyBindingInputTests.swift
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
import LineEnding
import Shortcut
@testable import CotEditor

@MainActor struct TextKeyBindingInputTests {
    
    /// Tests that configured Home/End keys invoke the existing movement and selection actions.
    ///
    /// - Parameters:
    ///   - input: The key, modifiers, and virtual key code.
    ///   - expected: The resulting selection range.
    /// - Throws: If creating the bindings or event fails.
    @Test(arguments: [
        ((NSEvent.SpecialKey.home, NSEvent.ModifierFlags.function, UInt16(115)), NSRange(location: 6, length: 0)),
        ((.end, .function, 119), NSRange(location: 13, length: 0)),
        ((.home, [.function, .shift], 115), NSRange(location: 6, length: 4)),
        ((.end, [.function, .shift], 119), NSRange(location: 10, length: 3)),
    ] as [((NSEvent.SpecialKey, NSEvent.ModifierFlags, UInt16), NSRange)])
    func assignedKeys(_ input: (key: NSEvent.SpecialKey, modifiers: NSEvent.ModifierFlags, keyCode: UInt16), expected: NSRange) throws {
        
        let (window, textView) = try makeKeyBindingEditor()
        defer { window.close() }
        let bindings = try makeHomeEndBindings()
        let key = String(input.key.unicodeScalar)
        let event = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: input.modifiers,
                                                  timestamp: 0, windowNumber: window.windowNumber, context: nil, characters: key,
                                                  charactersIgnoringModifiers: key, isARepeat: false, keyCode: input.keyCode))
        
        withTextKeyBindings(bindings) {
            textView.keyDown(with: event)
            #expect(textView.selectedRange == expected)
            #expect(textView.string == "first\nabc def\nlast")
        }
    }
    
    
    /// Tests that the original Command-Arrow keys no longer move or expand the selection.
    ///
    /// - Parameters:
    ///   - key: The arrow key.
    ///   - modifiers: The modifier flags, including navigation-key metadata.
    /// - Throws: If creating the bindings or event fails.
    @Test(arguments: [
        (NSEvent.SpecialKey.leftArrow, NSEvent.ModifierFlags([.command, .function, .numericPad])),
        (.rightArrow, [.command, .function, .numericPad]),
        (.leftArrow, [.command, .shift, .function, .numericPad]),
        (.rightArrow, [.command, .shift, .function, .numericPad]),
    ] as [(NSEvent.SpecialKey, NSEvent.ModifierFlags)])
    func suppressedKeys(_ key: NSEvent.SpecialKey, modifiers: NSEvent.ModifierFlags) throws {
        
        let (window, textView) = try makeKeyBindingEditor()
        defer { window.close() }
        let bindings = try makeHomeEndBindings()
        let character = String(key.unicodeScalar)
        let event = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers,
                                                  timestamp: 0, windowNumber: window.windowNumber, context: nil, characters: character,
                                                  charactersIgnoringModifiers: character, isARepeat: false,
                                                  keyCode: (key == .leftArrow) ? 123 : 124))
        
        withTextKeyBindings(bindings) {
            textView.keyDown(with: event)
            #expect(textView.selectedRange == NSRange(location: 10, length: 0))
            #expect(textView.string == "first\nabc def\nlast")
        }
    }
    
    
    /// Tests that an unrelated event still passes through the text system.
    ///
    /// - Parameter customized: Whether custom bindings are installed.
    /// - Throws: If creating the bindings or event fails.
    @Test(arguments: [false, true])
    func unassignedKeyUsesStandardInput(customized: Bool) throws {
        
        let (window, textView) = try makeKeyBindingEditor()
        defer { window.close() }
        let bindings = try (customized ? makeHomeEndBindings() : TextKeyBindingMap())
        let event = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [],
                                                  timestamp: 0, windowNumber: window.windowNumber, context: nil, characters: "x",
                                                  charactersIgnoringModifiers: "x", isARepeat: false, keyCode: 7))
        
        withTextKeyBindings(bindings) {
            textView.keyDown(with: event)
            #expect(textView.string == "first\nabc xdef\nlast")
            #expect(textView.selectedRange == NSRange(location: 11, length: 0))
        }
    }
}


/// Creates an editor with a selection in the middle of its second line.
///
/// - Returns: A hidden window and its editor configured for keyboard input tests.
/// - Throws: If the editor cannot become the first responder.
@MainActor private func makeKeyBindingEditor() throws -> (NSWindow, EditorTextView) {
    
    let textStorage = NSTextStorage(string: "first\nabc def\nlast")
    let scanner = LineEndingScanner(textStorage: textStorage, lineEnding: .lf)
    let textView = EditorTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 200), textStorage: textStorage, lineEndingScanner: scanner)
    textView.isEditable = true
    textView.isSelectable = true
    textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    textView.didChangeText()
    textView.selectedRange = NSRange(location: 10, length: 0)
    
    let window = NSWindow(contentRect: textView.frame, styleMask: .titled, backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.contentView = textView
    try #require(window.makeFirstResponder(textView))
    
    return (window, textView)
}


/// Creates the Home/End assignments previously exercised by the prototype.
///
/// - Returns: The key binding map for movement and selection.
/// - Throws: If configuring a shortcut fails.
private func makeHomeEndBindings() throws -> TextKeyBindingMap {
    
    var bindings = TextKeyBindingMap()
    try bindings.setShortcuts([Shortcut(.home, modifiers: [])], for: .moveToLeftEndOfLine)
    try bindings.setShortcuts([Shortcut(.end, modifiers: [])], for: .moveToRightEndOfLine)
    try bindings.setShortcuts([Shortcut(.home, modifiers: .shift)], for: .moveToLeftEndOfLineAndModifySelection)
    try bindings.setShortcuts([Shortcut(.end, modifiers: .shift)], for: .moveToRightEndOfLineAndModifySelection)
    
    return bindings
}


/// Installs bindings for one synchronous test operation and restores the shared state afterward.
///
/// - Parameters:
///   - bindings: The bindings to install.
///   - operation: The operation to run with the test bindings.
@MainActor private func withTextKeyBindings(_ bindings: TextKeyBindingMap, operation: () -> Void) {
    
    let manager = KeyBindingManager.shared
    let previous = manager.textKeyBindings
    manager.textKeyBindings = bindings
    defer { manager.textKeyBindings = previous }
    
    operation()
}
