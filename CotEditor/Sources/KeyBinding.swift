/*
 
 KeyBinding.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-20.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

enum ModifierKey {
    
    case control
    case option
    case shift
    case command
    
    
    static let all: [ModifierKey] = [.control, .option, .shift, .command]
    
    
    var mask: NSEventModifierFlags {
        
        switch self {
        case .control: return .control
        case .option:  return .option
        case .shift:   return .shift
        case .command: return .command
        }
    }
    
    
    /// printable symbol
    var symbol: String {
        
        switch self {
        case .control: return "^"
        case .option:  return "⌥"
        case .shift:   return "⇧"
        case .command: return "⌘"
        }
    }
    
    
    /// storeble symbol
    var keySpecChar: String {
        
        switch self {
        case .control: return "^"
        case .option:  return "~"
        case .shift:   return "$"
        case .command: return "@"
        }
    }
    
}



// MARK:

final class KeyBindingUtils {
    
    /// create keySpecChars to store from keyEquivalent and modifierMask
    static func keySpecChars(keyEquivalent: String, modifierMask: NSEventModifierFlags) -> String {
        
        guard let keyCharacter = keyEquivalent.unicodeScalars.first else { return "" }
        
        let isUppercase = CharacterSet.uppercaseLetters.contains(keyCharacter)
        
        var keySpecChars = ""
        
        for modifierKey in ModifierKey.all {
            guard modifierMask.contains(modifierKey.mask) || (modifierKey == .shift && isUppercase) else { continue }
            // -> For in case that a modifierMask taken from a menu item can lack Shift definition if binding is "aplhabet character + Shift" keys.
            
            keySpecChars += modifierKey.keySpecChar
        }
        
        keySpecChars += keyEquivalent
        
        return keySpecChars
    }
    
    
    /// return keyEquivalent and modifierMask from keySpecChars to store
    static func keyEquivalentAndModifierMask(keySpecChars: String, requiresCommandKey: Bool) -> (String, NSEventModifierFlags) {
        
        guard keySpecChars.characters.count > 1 else { return ("", []) }
        
        var modifierMask = NSEventModifierFlags()
        
        let splitIndex = keySpecChars.index(before: keySpecChars.endIndex)
        let keyEquivalent = keySpecChars.substring(from: splitIndex)
        let modifierCharacters = keySpecChars.substring(to: splitIndex)
        
        let isUppercase = CharacterSet.uppercaseLetters.contains(keyEquivalent.unicodeScalars.first!)
        
        for modifierKey in ModifierKey.all {
            guard modifierCharacters.contains(modifierKey.keySpecChar) || (modifierKey == .shift && isUppercase) else { continue }

            modifierMask.update(with: modifierKey.mask)
        }
        
        guard !requiresCommandKey || modifierMask.contains(.command) else { return ("", []) }
        guard !modifierMask.isEmpty else { return ("", []) }
        
        return (keyEquivalent, modifierMask)
    }
    
    
    /// return shortcut string to display from keySpecChars to store
    static func printableKeyString(keySpecChars: String?) -> String {
        
        guard let keySpecChars = keySpecChars, keySpecChars.characters.count > 1 else { return "" }
        
        let splitIndex = keySpecChars.index(before: keySpecChars.endIndex)
        let keyEquivalent = keySpecChars.substring(from: splitIndex)
        let modifierCharacters = keySpecChars.substring(to: splitIndex)
        let isUppercase = CharacterSet.uppercaseLetters.contains(keyEquivalent.unicodeScalars.first!)
        
        let modifierKeyString = self.printableKeyString(modKeySpecChars: modifierCharacters, withShiftKey: isUppercase)
        let keyString = self.printableKeyString(keyEquivalent: keyEquivalent)
        
        return modifierKeyString + keyString
    }
    
    
    
    // MARK: Private Methods
    
    /// create printable modifier key string from key binding definition string
    private static func printableKeyString(modKeySpecChars: String, withShiftKey: Bool) -> String {
        
        var keyString = ""
        
        for modifierKey in ModifierKey.all {
            if modKeySpecChars.contains(modifierKey.keySpecChar) || (modifierKey == .shift && withShiftKey) {
                keyString += modifierKey.symbol
            }
        }
        
        return keyString
    }
    
    
    /// create string to display from keyboard shortcut in menu
    private static func printableKeyString(keyEquivalent: String) -> String {
        
        guard let keyCharacter = keyEquivalent.unicodeScalars.first else { return "" }
        
        if CharacterSet.alphanumerics.contains(keyCharacter) {
            return keyEquivalent.uppercased()
        }
        
        return self.printableKeys[keyCharacter] ?? keyEquivalent
    }
    
    
    /// table for characters that cannot be displayed as is with their printable substitutions
    private static let printableKeys: [UnicodeScalar: String] = {
        
        // keys:  unprintable key int
        // value: printable representation
        let table: [Int: String] = [
            NSUpArrowFunctionKey:   "↑",
            NSDownArrowFunctionKey: "↓",
            NSLeftArrowFunctionKey: "←",
            NSRightArrowFunctionKey:"→",
            NSF1FunctionKey:        "F1",
            NSF2FunctionKey:        "F2",
            NSF3FunctionKey:        "F3",
            NSF4FunctionKey:        "F4",
            NSF5FunctionKey:        "F5",
            NSF6FunctionKey:        "F6",
            NSF7FunctionKey:        "F7",
            NSF8FunctionKey:        "F8",
            NSF9FunctionKey:        "F9",
            NSF10FunctionKey:       "F10",
            NSF11FunctionKey:       "F11",
            NSF12FunctionKey:       "F12",
            NSF13FunctionKey:       "F13",
            NSF14FunctionKey:       "F14",
            NSF15FunctionKey:       "F15",
            NSF16FunctionKey:       "F16",
            NSDeleteCharacter:      "⌦",  // = "Delete forward" (do not use NSDeleteFunctionKey)
            NSHomeFunctionKey:      "↖",
            NSEndFunctionKey:       "↘",
            NSPageUpFunctionKey:    "⇞",
            NSPageDownFunctionKey:  "⇟",
            NSClearLineFunctionKey: "⌧",
            NSHelpFunctionKey:      "Help",
            0x20:                   NSLocalizedString("Space", comment: "keyboard key name"),  // = Space
            0x09:                   "⇥",  // = Tab
            0x0d:                   "↩",  // = Return
            0x08:                   "⌫",  // = Backspace, (delete backword)
            0x03:                   "⌅",  // = Enter
            0x31:                   "⇤",  // = Backtab
            0x33:                   "⎋",  // = Escape
        ]
        
        // Int to String
        var printableTable = [UnicodeScalar: String]()
        for (key, value) in table {
            printableTable[UnicodeScalar(key)] = value
        }
        
        return printableTable
    }()
    
}
