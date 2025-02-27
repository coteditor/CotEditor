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
//  © 2016-2025 1024jp
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
    
    @Test func equivalent() {
        
        #expect(Shortcut("A", modifiers: [.control]) ==
                Shortcut("a", modifiers: [.control, .shift]))
        
        #expect(Shortcut(keySpecChars: "^A") ==
                Shortcut(keySpecChars: "^$a"))
    }
    
    
    @Test func createKeySpecChars() {
        
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
        
        #expect(Shortcut(.backspace, modifiers: []).keyEquivalent == String(NSEvent.SpecialKey.backspace.unicodeScalar))
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
    
    
    @Test(arguments: ModifierKey.allCases) func symbol(modifierKey: ModifierKey) {
        
        #expect(NSImage(systemSymbolName: modifierKey.symbolName, accessibilityDescription: nil) != nil)
    }
    
    
    @Test(arguments: Set(Shortcut.keyEquivalentSymbolNames.values)) func symbol(name: String) {
        
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
        
        let delete = try #require(UnicodeScalar(NSDeleteCharacter).map(String.init))
        #expect(Shortcut(keySpecChars: "@" + delete)?.symbol == "⌘ ⌫")
        
        // test creation
        let deleteForward = String(NSEvent.SpecialKey.deleteForward.unicodeScalar)
        #expect(Shortcut(symbolRepresentation: "") == nil)
        #expect(Shortcut(symbolRepresentation: "^ ⇧ A")?.keySpecChars == "^$a")
        #expect(Shortcut(symbolRepresentation: "⌥ ⌘ B")?.keySpecChars == "~@b")
        #expect(Shortcut(symbolRepresentation: "⌘ F10")?.keySpecChars == "@" + f10)
        #expect(Shortcut(symbolRepresentation: "⌘ ⌦")?.keySpecChars == "@" + deleteForward)
    }
}
