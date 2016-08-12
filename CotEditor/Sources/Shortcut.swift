/*
 
 Shortcut.swift
 
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



struct Shortcut: Hashable, CustomStringConvertible {
    
    let modifierMask: NSEventModifierFlags
    let keyEquivalent: String
    
    static let none = Shortcut(modifierMask: [], keyEquivalent: "")
    
    
    init(modifierMask: NSEventModifierFlags, keyEquivalent: String) {
        
        self.modifierMask = {
            // -> For in case that a modifierMask taken from a menu item can lack Shift definition if the combination is "Shift + alphabet character" keys.
            if let keyEquivalentScalar = keyEquivalent.unicodeScalars.last,
                CharacterSet.uppercaseLetters.contains(keyEquivalentScalar) {
                return modifierMask.union(.shift)
            }
            
            return modifierMask
        }()
        
        self.keyEquivalent = keyEquivalent
    }
    
    
    init(keySpecChars: String) {
        
        guard keySpecChars.characters.count > 1 else {
            self.init(modifierMask: [], keyEquivalent: "")
            return
        }
        
        let splitIndex = keySpecChars.index(before: keySpecChars.endIndex)
        let modifierCharacters = keySpecChars.substring(to: splitIndex)
        let keyEquivalent = keySpecChars.substring(from: splitIndex)
        
        let modifierMask = ModifierKey.all
            .filter { key in modifierCharacters.contains(key.keySpecChar) }
            .reduce(NSEventModifierFlags()) { (mask, key) in mask.union(key.mask) }
        
        self.init(modifierMask: modifierMask, keyEquivalent: keyEquivalent)
    }
    
    
    /// unique string to store in plist
    var keySpecChars: String {
        
        let modifierCharacters = ModifierKey.all
            .filter { key in self.modifierMask.contains(key.mask) }
            .reduce("") { (chars, key) in chars + key.keySpecChar }
        
        return modifierCharacters + self.keyEquivalent
    }
    
    
    
    // MARK: Protocols
    
    /// shortcut string to display
    var description: String {
        
        return self.printableModifierMask + self.printableKeyEquivalent
    }
    
    
    var hashValue: Int {
        
        return self.modifierMask.rawValue.hashValue ^ self.keyEquivalent.hashValue
    }
    
    
    static func ==(lhs: Shortcut, rhs: Shortcut) -> Bool {
        
        return lhs.keySpecChars == rhs.keySpecChars
    }
    
    
    
    // MARK: Private Methods
    
    /// modifier keys string to display
    private var printableModifierMask: String {
        
        return ModifierKey.all
            .filter { key in self.modifierMask.contains(key.mask) }
            .reduce("") { (partical, key) in partical + key.symbol }
    }
    
    
    /// key equivalent to display
    private var printableKeyEquivalent: String {
        
        guard let scalar = self.keyEquivalent.unicodeScalars.first else { return "" }
        
        if CharacterSet.alphanumerics.contains(scalar) {
            return self.keyEquivalent.uppercased()
        }
        
        return Shortcut.printableKeyEquivalents[scalar] ?? self.keyEquivalent
    }
    
    
    /// table for characters that cannot be displayed as is with their printable substitutions
    private static let printableKeyEquivalents: [UnicodeScalar: String] = {
        
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
