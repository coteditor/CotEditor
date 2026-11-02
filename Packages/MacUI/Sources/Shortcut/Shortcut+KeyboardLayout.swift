//
//  Shortcut+KeyboardLayout.swift
//  Shortcut
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

public import AppKit.NSEvent
import Carbon.HIToolbox

extension Shortcut {
    
    /// Initializes Shortcut from a key down event using the keyboard layout's Command-key characters and the event's original modifiers.
    ///
    /// Returns `nil` for ordinary input, special keys, or Control/Option input on an ASCII-capable keyboard layout.
    ///
    /// - Note: Try `init(keyDownEvent:)` first to preserve explicit assignments and disabled shortcuts.
    ///
    /// - Parameter event: The key down event to translate.
    @MainActor public init?(keyDownEventUsingCommandLayout event: NSEvent) {
        
        // special keys do not depend on the keyboard layout
        guard event.specialKey == nil else { return nil }
        
        let modifiers = event.modifierFlags.intersection(.shift).union(.command)
        
        self.init(commandLayoutCharacters: event.characters(byApplyingModifiers: modifiers),
                  modifierFlags: event.modifierFlags,
                  isASCIICapableKeyboardLayout: Self.isCurrentKeyboardLayoutASCIICapable)
    }
    
    
    /// Initializes Shortcut from the properties of a key down event using the keyboard layout's Command-key characters.
    ///
    /// Returns `nil` when translation should not be used.
    ///
    /// - Parameters:
    ///   - characters: The characters of the key in the keyboard layout's Command-key mode, applying only Shift, evaluated only when needed.
    ///   - modifierFlags: The modifier flags of the event.
    ///   - isASCIICapableKeyboardLayout: Whether the current keyboard layout supports ASCII, evaluated only when needed.
    @MainActor init?(commandLayoutCharacters characters: @autoclosure () -> String?, modifierFlags: NSEvent.ModifierFlags, isASCIICapableKeyboardLayout: @autoclosure () -> Bool) {
        
        guard
            !modifierFlags.isDisjoint(with: [.control, .option, .command]),
            modifierFlags.contains(.command) || !isASCIICapableKeyboardLayout()
        else { return nil }
        
        self.init(charactersIgnoringModifiers: characters(), specialKey: nil, modifierFlags: modifierFlags)
    }
    
    
    /// Whether the current keyboard layout supports ASCII, preserving ordinary input if its metadata is unavailable.
    @MainActor private static var isCurrentKeyboardLayoutASCIICapable: Bool {
        
        guard
            let source = unsafe TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
            let value = unsafe TISGetInputSourceProperty(source, kTISPropertyInputSourceIsASCIICapable)
        else { return true }
        
        return unsafe CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(value).takeUnretainedValue())
    }
}
