//
//  ShortcutTests.swift
//  ShortcutTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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

import AppKit.NSEvent
import Foundation
import Testing
@testable import Shortcut

struct ShortcutTests {
    
    @Test func equivalent() throws {
        
        let uppercase = try #require(Shortcut("A", modifiers: [.control]))
        let shifted = try #require(Shortcut("a", modifiers: [.control, .shift]))
        
        #expect(uppercase == shifted)
        #expect(Set([uppercase, shifted]).count == 1)
        
        #expect(Shortcut(keySpecChars: "^A") ==
                Shortcut(keySpecChars: "^$a"))
    }
    
    
    @Test func createKeySpecChars() throws {
        
        #expect(Shortcut("", modifiers: []) == nil)
        #expect(Shortcut("a", modifiers: [.control, .shift])?.keySpecChars == "^$a")
        #expect(Shortcut("b", modifiers: [.command, .option])?.keySpecChars == "~@b")
        #expect(Shortcut("A", modifiers: [.control])?.keySpecChars == "^$a")  // uppercase for Shift key
        #expect(Shortcut("a", modifiers: [.control, .shift])?.keySpecChars == "^$a")
        
        #expect(Shortcut("a", modifiers: [])?.keySpecChars == "a")
        #expect(Shortcut("a", modifiers: [])?.isAssignable == false)
        #expect(Shortcut("", modifiers: [.control, .shift]) == nil)
        #expect(Shortcut("a", modifiers: [.control, .shift])?.isAssignable == true)
        #expect(Shortcut("ab", modifiers: [.control, .shift])?.isAssignable == true)
        
        let backspace = try #require(UnicodeScalar(NSBackspaceCharacter).map(String.init))
        let delete = try #require(UnicodeScalar(NSDeleteCharacter).map(String.init))
        let deleteForward = try #require(UnicodeScalar(NSDeleteFunctionKey).map(String.init))
        
        #expect(Shortcut(.backspace, modifiers: []).keyEquivalent == backspace)
        #expect(Shortcut(.delete, modifiers: []).keyEquivalent == backspace)
        #expect(Shortcut(.deleteForward, modifiers: []).keyEquivalent == delete)
        #expect(Shortcut(deleteForward, modifiers: .command)?.keyEquivalent == delete)
    }
    
    
    @Test func keyDownEventDeletionKeys() throws {
        
        let backspace = try #require(UnicodeScalar(NSBackspaceCharacter).map(String.init))
        let delete = try #require(UnicodeScalar(NSDeleteCharacter).map(String.init))
        let deleteForward = try #require(UnicodeScalar(NSDeleteFunctionKey).map(String.init))
        
        let backspaceEvent = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command,
                                                           timestamp: 0, windowNumber: 0, context: nil, characters: delete,
                                                           charactersIgnoringModifiers: delete, isARepeat: false, keyCode: 51))
        let deleteForwardEvent = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command,
                                                               timestamp: 0, windowNumber: 0, context: nil, characters: deleteForward,
                                                               charactersIgnoringModifiers: deleteForward, isARepeat: false, keyCode: 117))
        
        #expect(Shortcut(keyDownEvent: backspaceEvent)?.keyEquivalent == backspace)
        #expect(Shortcut(keyDownEvent: deleteForwardEvent)?.keyEquivalent == delete)
    }
    
    
    @Test func stringToShortcut() throws {
        
        let shortcut = try #require(Shortcut(keySpecChars: "^$a"))
        
        #expect(shortcut.keyEquivalent == "a")
        #expect(shortcut.modifiers == [.control, .shift])
        #expect(shortcut.isAssignable)
    }
    
    
    @Test func shortcutWithFnKey() throws {
        
        let shortcut = try #require(Shortcut("a", modifiers: [.function]))
        
        #expect(!shortcut.isAssignable)
        #expect(shortcut.keyEquivalent == "a")
        #expect(shortcut.modifiers == [.function])
        #expect(shortcut.symbol == "fn A" || shortcut.symbol == "🌐︎ A")
        #expect(shortcut.keySpecChars == "a", "The fn key should be ignored.")
    }
    
    
    /// Tests that Fn/Globe display strings can be parsed without allowing their customization.
    ///
    /// - Parameter modifiers: The modifiers containing Fn/Globe.
    /// - Throws: If creating or parsing the shortcut fails.
    @Test(arguments: [NSEvent.ModifierFlags.function, [.command, .function]])
    func parseFnShortcut(_ modifiers: NSEvent.ModifierFlags) throws {
        
        let shortcut = try #require(Shortcut("a", modifiers: modifiers))
        let parsed = try #require(Shortcut(symbolRepresentation: shortcut.symbol))
        
        #expect(parsed.keyEquivalent == "a")
        #expect(parsed.modifiers == modifiers)
        #expect(!parsed.isAssignable)
    }
    
    
    @Test(arguments: ModifierKey.displayCases)
    func symbol(modifierKey: ModifierKey) {
        
        #expect(NSImage(systemSymbolName: modifierKey.symbolName, accessibilityDescription: nil) != nil)
    }
    
    
    @Test(arguments: Set(Shortcut.keyEquivalentSymbolNames.values))
    func symbol(name: String) {
        
        #expect(NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil)
    }
    
    
    @Test func menuItemShortcut() throws {
        
        let menuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "C")
        menuItem.keyEquivalentModifierMask = [.command]
        
        let shortcut = try #require(Shortcut(menuItem.keyEquivalent, modifiers: menuItem.keyEquivalentModifierMask))
        
        #expect(shortcut.symbol == "⇧ ⌘ C")
        #expect(shortcut == menuItem.shortcut)
        
        let shortcutA = Shortcut("A", modifiers: [.shift])
        menuItem.shortcut = shortcutA
        #expect(menuItem.shortcut == shortcutA)
        
        menuItem.shortcut = Shortcut("C", modifiers: .option)
        #expect(menuItem.keyEquivalent == "C")
        #expect(menuItem.keyEquivalentModifierMask == .option)
        
        let delete = try #require(UnicodeScalar(NSDeleteCharacter).map(String.init))
        menuItem.shortcut = Shortcut(.deleteForward, modifiers: .command)
        #expect(menuItem.keyEquivalent == delete)
        #expect(menuItem.shortcut?.symbol == "⌘ ⌦")
    }
    
    
    @Test func menuItemCommand() throws {
        
        let menu = NSMenu()
        menu.items = [
            NSMenuItem(title: "aaa", action: nil, keyEquivalent: "A"),
            NSMenuItem(title: "bbb", action: nil, keyEquivalent: "B"),
            NSMenuItem(title: "ccc", action: nil, keyEquivalent: "C"),
        ]
        let shortcut = try #require(Shortcut("B", modifiers: .command))
        
        #expect(menu.commandName(for: shortcut) == "bbb")
    }
    
    
    @Test func shortcutSymbols() throws {
        
        // test modifier symbols
        #expect(Shortcut(keySpecChars: "") == nil)
        #expect(Shortcut(keySpecChars: "^$a")?.symbol == "^ ⇧ A")
        #expect(Shortcut(keySpecChars: "~@b")?.symbol == "⌥ ⌘ B")
        
        // test unprintable keys
        let f10 = String(NSEvent.SpecialKey.f10.unicodeScalar)
        #expect(Shortcut(keySpecChars: "@" + f10)?.symbol == "⌘ F10")
        
        let backspace = try #require(UnicodeScalar(NSBackspaceCharacter).map(String.init))
        #expect(Shortcut(keySpecChars: "@" + backspace)?.symbol == "⌘ ⌫")
        
        let delete = try #require(UnicodeScalar(NSDeleteCharacter).map(String.init))
        #expect(Shortcut(keySpecChars: "@" + delete)?.symbol == "⌘ ⌦")
        
        let deleteForward = String(NSEvent.SpecialKey.deleteForward.unicodeScalar)
        #expect(Shortcut(keySpecChars: "@" + deleteForward)?.keySpecChars == "@" + delete)
        #expect(Shortcut(keySpecChars: "@" + deleteForward)?.symbol == "⌘ ⌦")
        
        // test creation
        #expect(Shortcut(symbolRepresentation: "") == nil)
        #expect(Shortcut(symbolRepresentation: "^ ⇧ A")?.keySpecChars == "^$a")
        #expect(Shortcut(symbolRepresentation: "⌥ ⌘ B")?.keySpecChars == "~@b")
        #expect(Shortcut(symbolRepresentation: "⌘ F10")?.keySpecChars == "@" + f10)
        #expect(Shortcut(symbolRepresentation: "⌘ ⌦")?.keySpecChars == "@" + delete)
    }
    
    
    /// Tests that complete key strings and modifiers survive storage and Codable conversion.
    ///
    /// - Parameters:
    ///   - key: The key string to preserve.
    ///   - modifiers: The shortcut modifiers.
    /// - Throws: If creating or decoding a shortcut fails.
    @Test(arguments: ["ab", "aB", "SS", "ß", "e\u{301}", "@a", "^@", "#0", "\\", "\\\\", "\\\u{301}", "a b", "\u{301}", "@\u{301}", "a^b", "F10"],
          [NSEvent.ModifierFlags(), .command, .shift, [.control, .option], [.control, .option, .shift, .command], [.command, .numericPad]])
    func storedKeyStrings(_ key: String, modifiers: NSEvent.ModifierFlags) throws {
        
        let shortcut = try #require(Shortcut(key, modifiers: modifiers))
        let restored = try #require(Shortcut(keySpecChars: shortcut.keySpecChars))
        
        #expect(Array(restored.keyEquivalent.unicodeScalars) == Array(shortcut.normalized.keyEquivalent.unicodeScalars))
        #expect(restored.modifiers == shortcut.normalized.modifiers)
        
        let data = try PropertyListEncoder().encode([shortcut])
        let decoded = try #require(PropertyListDecoder().decode([Shortcut].self, from: data).first)
        #expect(decoded.keyEquivalent == restored.keyEquivalent)
        #expect(decoded.modifiers == restored.modifiers)
    }
    
    
    /// Tests Cocoa key-binding notation and compatibility with older CotEditor settings.
    ///
    /// - Parameters:
    ///   - stored: The key specification.
    ///   - key: The expected key string.
    ///   - modifiers: The expected modifier flags.
    /// - Throws: If decoding the shortcut fails.
    @Test(arguments: [
        ("^$a", "a", NSEvent.ModifierFlags([.control, .shift])),
        ("@@", "@", .command),  // legacy CotEditor representation
        ("@#", "#", .command),  // legacy CotEditor representation
        ("@\\", "\\", .command),
        ("@@\u{301}", "\u{301}", .command),
        ("@ab", "ab", .command),
        ("@aB", "aB", .command),
        ("@a b", "a b", .command),
        ("@\\@", "@", .command),
        ("@\\@ab", "@ab", .command),
        ("@\\\\@ab", "\\@ab", .command),
        ("@\\\\", "\\", .command),
        ("@a\\b", "a\\b", .command),
        ("@\\ab", "ab", .command),
        ("@#0", "0", NSEvent.ModifierFlags([.command, .numericPad])),
        ("@\\#0", "#0", .command),
        ("@\\@\u{301}", "@\u{301}", .command),
        ("@\\\u{301}", "\\\u{301}", .command),
    ])
    func keySpecifications(_ stored: String, key: String, modifiers: NSEvent.ModifierFlags) throws {
        
        let shortcut = try #require(Shortcut(keySpecChars: stored))
        #expect(shortcut.keyEquivalent == key)
        #expect(shortcut.modifiers == modifiers)
    }
    
    
    /// Tests that reserved key prefixes use Cocoa's single-backslash quoting.
    ///
    /// - Parameters:
    ///   - key: The key string to encode with Command.
    ///   - stored: The expected Cocoa key-binding string.
    @Test(arguments: [
        ("@", "@\\@"),
        ("@ab", "@\\@ab"),
        ("#0", "@\\#0"),
        ("\\", "@\\\\"),
        ("\\@ab", "@\\\\@ab"),
        ("@\u{301}", "@\\@\u{301}"),
        ("a\\b", "@a\\b"),
        ("ab", "@ab"),
    ])
    func quoteKeySpecifications(_ key: String, stored: String) {
        
        #expect(Shortcut(key, modifiers: .command)?.keySpecChars == stored)
    }
    
    
    /// Tests that a single event preserves its complete key string and Shift modifier.
    ///
    /// - Parameter key: The string produced by one key event.
    /// - Throws: If creating the event or shortcut fails.
    @Test(arguments: ["ab", "aB", "=/*", "\u{F728}a", "e\u{301}"])
    func keyDownEventStrings(_ key: String) throws {
        
        let modifiers: NSEvent.ModifierFlags = [.command, .shift]
        let event = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers,
                                                timestamp: 0, windowNumber: 0, context: nil, characters: key,
                                                charactersIgnoringModifiers: key, isARepeat: false, keyCode: 0))
        let shortcut = try #require(Shortcut(keyDownEvent: event))
        
        #expect(shortcut.keyEquivalent == key)
        #expect(shortcut.modifiers == modifiers)
        #expect(shortcut.isAssignable)
    }
    
    
    /// Tests that the numeric keypad flag does not change captured shortcuts or modifier symbols.
    ///
    /// - Parameter key: The string produced by a numeric keypad or arrow key.
    /// - Throws: If creating the event or shortcut fails.
    @Test(arguments: ["0", "\u{F700}"])
    func numericPadModifier(_ key: String) throws {
        
        let event = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [.command, .numericPad],
                                                timestamp: 0, windowNumber: 0, context: nil, characters: key,
                                                charactersIgnoringModifiers: key, isARepeat: false, keyCode: 0))
        let captured = try #require(Shortcut(keyDownEvent: event))
        #expect(captured.modifiers == .command)
        #expect(captured.isAssignable)
        
        let stored = try #require(Shortcut(key, modifiers: [.command, .numericPad]))
        #expect(!stored.isAssignable)
        #expect(stored.modifierSymbols == ["⌘"])
        #expect(stored.modifierSymbolNames == ["command"])
    }
    
    
    /// Tests that multi-character keys retain their case during normalization.
    ///
    /// - Throws: If creating a shortcut fails.
    @Test func normalizeKeyStrings() throws {
        
        let shortcut = try #require(Shortcut("aB", modifiers: .command))
        #expect(shortcut.normalized.keyEquivalent == "aB")
        #expect(shortcut.normalized.modifiers == .command)
        #expect(shortcut != Shortcut("ab", modifiers: [.command, .shift]))
    }
    
    
    /// Tests that display names preserve all scalars and do not use a partial special-key symbol.
    ///
    /// - Parameters:
    ///   - key: The key string to display.
    ///   - symbol: The expected display string.
    /// - Throws: If creating a shortcut fails.
    @Test(arguments: [("ab", "AB"), ("e\u{301}", "E\u{301}"), ("👩‍💻", "👩‍💻"), ("\u{F700}a", "\u{F700}A")])
    func keyStringSymbols(_ key: String, symbol: String) throws {
        
        let shortcut = try #require(Shortcut(key, modifiers: .command))
        #expect(shortcut.keyEquivalentSymbol == symbol)
        #expect(shortcut.keyEquivalentSymbolName == nil)
    }
    
    
    /// Tests that parsing a display string preserves spaces and the case of multi-character keys.
    ///
    /// - Parameter key: The displayed key string.
    @Test(arguments: ["AB", "aB", "SS", "a b", " a ", "a b"])
    func parseKeyStrings(_ key: String) {
        
        let shortcut = Shortcut(symbolRepresentation: "⌘ " + key)
        #expect(shortcut?.keyEquivalent == key)
        #expect(shortcut?.modifiers == .command)
    }
    
    
    /// Tests that an empty key remains invalid after mutating a shortcut.
    ///
    /// - Throws: If creating the shortcut fails.
    @Test func emptyKey() throws {
        
        var shortcut = try #require(Shortcut("ab", modifiers: .command))
        shortcut.keyEquivalent = ""
        #expect(!shortcut.isAssignable)
    }
    
    
    @Test func modifierKeyBasics() {
        
        #expect([.control, .shift].mask == [.control, .shift])
        
        #expect(ModifierKey.control.keySpecChar == "^")
        #expect(ModifierKey.option.keySpecChar == "~")
        #expect(ModifierKey.shift.keySpecChar == "$")
        #expect(ModifierKey.command.keySpecChar == "@")
        #expect(ModifierKey.numericPad.keySpecChar == "#")
        #expect(ModifierKey.numericPad.mask == .numericPad)
    }
}
