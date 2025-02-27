//
//  KeyBindingTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-12-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2025 1024jp
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

import Testing
import Shortcut
import AppKit.NSEvent
@testable import CotEditor

@MainActor struct KeyBindingTests {
    
    /// Shortcuts that are reserved for use with the Accessibility features in macOS.
    ///
    /// - SeeAlso: [Accessibility shortcuts](https://support.apple.com/en-us/102650#accessibility)
    private let accessibilityShortcuts: Set<Shortcut> = [
        // vision shortcuts
        Shortcut("8", modifiers: [.control, .option, .command])!,
        Shortcut(",", modifiers: [.control, .option, .command])!,
        Shortcut(".", modifiers: [.control, .option, .command])!,
        
        // moving keyboard focus
        Shortcut(.f2, modifiers: [.control]),
        Shortcut(.f3, modifiers: [.control]),
        Shortcut(.f4, modifiers: [.control]),
        Shortcut(.f5, modifiers: [.control]),
        Shortcut(.f6, modifiers: [.control]),
        Shortcut(.f6, modifiers: [.control, .shift]),
        Shortcut(.f7, modifiers: [.control]),
        Shortcut(.f8, modifiers: [.control]),
        Shortcut("`", modifiers: [.command])!,
        Shortcut("`", modifiers: [.shift, .command])!,
        Shortcut("`", modifiers: [.option, .command])!,
        Shortcut(.tab, modifiers: [.shift]),
        Shortcut(.tab, modifiers: [.control]),
        Shortcut(.tab, modifiers: [.control, .shift]),
        Shortcut(.upArrow, modifiers: [.control]),
        Shortcut(.downArrow, modifiers: [.control]),
        Shortcut(.leftArrow, modifiers: [.control]),
        Shortcut(.rightArrow, modifiers: [.control]),
        
        /// showing accessibility shortcut panel
        Shortcut(.f5, modifiers: [.option, .command]),
        
        /// toggling VoiceOver
        Shortcut(.f5, modifiers: [.command]),
    ]
    
    private let keyBindings = KeyBindingManager.shared.defaultKeyBindings
    
    
    /// Tests .defaultKeyBindings expectedly contains key bindings determined in CotEditor.
    @Test func defaultKeyBindings() async throws {
        
        let shortcut = try #require(Shortcut("k", modifiers: .command))
        let shortcuts = self.keyBindings.compactMap(\.shortcut)
        
        #expect(shortcuts.contains(shortcut))
    }
    
    
    @Test func reservedShortcuts() async {
        
        for keyBinding in self.keyBindings {
            guard let shortcut = keyBinding.shortcut else { continue }
            
            #expect(!self.accessibilityShortcuts.contains(shortcut),
                    "\(keyBinding.action) overrides the accessibility shortcut “\(shortcut.symbol)”")
        }
    }
}
