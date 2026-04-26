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
        #expect(Shortcut("a", modifiers: [])?.isValid == false)
        #expect(Shortcut("", modifiers: [.control, .shift]) == nil)
        #expect(Shortcut("a", modifiers: [.control, .shift])?.isValid == true)
        #expect(Shortcut("ab", modifiers: [.control, .shift])?.isValid == false)
        
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
        #expect(shortcut.isValid)
    }
    
    
    @Test func shortcutWithFnKey() throws {
        
        let shortcut = try #require(Shortcut("a", modifiers: [.function]))
        
        #expect(!shortcut.isValid)
        #expect(shortcut.keyEquivalent == "a")
        #expect(shortcut.modifiers == [.function])
        #expect(shortcut.symbol == "fn A" || shortcut.symbol == "🌐︎ A")
        #expect(shortcut.keySpecChars == "a", "The fn key should be ignored.")
    }
    
    
    @Test(arguments: ModifierKey.allCases)
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
    
    
    @Test func modifierKeyBasics() {
        
        #expect(ModifierKey.validCases == [.control, .option, .shift, .command])
        #expect([.control, .shift].mask == [.control, .shift])
        
        #expect(ModifierKey.control.keySpecChar == "^")
        #expect(ModifierKey.option.keySpecChar == "~")
        #expect(ModifierKey.shift.keySpecChar == "$")
        #expect(ModifierKey.command.keySpecChar == "@")
    }
}
