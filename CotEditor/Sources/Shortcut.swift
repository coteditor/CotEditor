//
//  Shortcut.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2023 1024jp
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

import Foundation
import AppKit.NSEvent

/// Modifier keys for keyboard shortcut.
///
/// The order of cases (control, option, shift, and command) is determined in the HIG.
enum ModifierKey: CaseIterable {
    
    case control
    case option
    case shift
    case command
    
    
    static var mask: NSEvent.ModifierFlags {
        
        self.allCases.reduce(into: []) { $0.formUnion($1.mask) }
    }
    
    
    var mask: NSEvent.ModifierFlags {
        
        switch self {
            case .control: return .control
            case .option:  return .option
            case .shift:   return .shift
            case .command: return .command
        }
    }
    
    
    /// Symbol to display in GUI.
    var symbol: String {
        
        switch self {
            case .control: return "^"
            case .option:  return "⌥"
            case .shift:   return "⇧"
            case .command: return "⌘"
        }
    }
    
    
    /// Symbol to store.
    var keySpecChar: String {
        
        switch self {
            case .control: return "^"
            case .option:  return "~"
            case .shift:   return "$"
            case .command: return "@"
        }
    }
}



struct Shortcut {
    
    let modifierMask: NSEvent.ModifierFlags
    let keyEquivalent: String
    
    
    // MARK: Lifecycle
    
    init?(modifierMask: NSEvent.ModifierFlags, keyEquivalent: String) {
        
        guard !keyEquivalent.isEmpty else { return nil }
        
        self.modifierMask = modifierMask
        self.keyEquivalent = keyEquivalent
    }
    
    
    /// Initialize Shortcut from a stored string.
    ///
    /// - Parameter keySpecChars: The storeble representation.
    init?(keySpecChars: String) {
        
        guard let keyEquivalent = keySpecChars.last else { return nil }
        
        let modifierCharacters = keySpecChars.dropLast()
        let modifierMask = ModifierKey.allCases
            .filter { modifierCharacters.contains($0.keySpecChar) }
            .reduce(into: NSEvent.ModifierFlags()) { $0.formUnion($1.mask) }
        
        self.modifierMask = modifierMask
        self.keyEquivalent = String(keyEquivalent)
    }
    
    
    /// Initialize Shortcut from a display representation.
    ///
    /// - Parameter string: The shortcut string to display in GUI.
    init?(symbolRepresentation string: String) {
        
        let components = string.components(separatedBy: .whitespaces)
        
        guard let lastSymbol = components.last, !lastSymbol.isEmpty else { return nil }
        
        let keyEquivalent = Self.keyEquivalentSymbols
            .first { $0.value == lastSymbol }
            .map(\.key)
            .map(String.init) ?? lastSymbol.lowercased()
        
        let modifierCharacters = components.dropLast().joined()
        let modifierMask = ModifierKey.allCases
            .filter { modifierCharacters.contains($0.symbol) }
            .reduce(into: NSEvent.ModifierFlags()) { $0.formUnion($1.mask) }
        
        self.modifierMask = modifierMask
        self.keyEquivalent = keyEquivalent
    }
    
    
    /// Initialize Shortcut from a key down event.
    ///
    /// - Parameter event: The key down event.
    init?(keyDownEvent event: NSEvent) {
        
        assert(event.type == .keyDown)
        
        guard let charactersIgnoringModifiers = event.charactersIgnoringModifiers else { return nil }
        
        // correct Backspace and Forward Delete keys
        //  -> Backspace:      The key above the Return.
        //     Forward Delete: The key with printed "Delete" where next to the ten key pad.
        // cf. https://developer.apple.com/documentation/appkit/nsmenuitem/1514842-keyequivalent
        let keyEquivalent: String
        switch event.specialKey {
            case NSEvent.SpecialKey.delete:
                keyEquivalent = String(NSEvent.SpecialKey.backspace.unicodeScalar)
            case NSEvent.SpecialKey.deleteForward:
                keyEquivalent = String(NSEvent.SpecialKey.delete.unicodeScalar)
            default:
                keyEquivalent = charactersIgnoringModifiers
        }
        
        // remove unwanted Shift
        let ignoresShift = "`~!@#$%^&()_{}|\":<>?=/*-+.'".contains(keyEquivalent)
        let modifierMask = event.modifierFlags
            .intersection(ModifierKey.mask)
            .subtracting(ignoresShift ? .shift : [])
        
        self.modifierMask = modifierMask
        self.keyEquivalent = keyEquivalent
    }
    
    
    // MARK: Public Methods
    
    /// Unique string to store in plist.
    var keySpecChars: String {
        
        let shortcut = self.normalized
        let modifierCharacters = ModifierKey.allCases
            .filter { shortcut.modifierMask.contains($0.mask) }
            .map(\.keySpecChar)
            .joined()
        
        return modifierCharacters + shortcut.keyEquivalent
    }
    
    
    /// Shortcut string to display.
    var symbol: String {
        
        let shortcut = self.normalized
        
        return (shortcut.modifierMaskSymbols + [shortcut.keyEquivalentSymbol]).joined(separator: .thinSpace)
    }
    
    
    /// Whether key combination is valid for a shortcut.
    var isValid: Bool {
        
        guard self.keyEquivalent.count == 1 else { return false }
        
        if Self.singleKeys.map(\.unicodeScalar).map(String.init).contains(self.keyEquivalent) {
            return true
        }
        
        return !self.modifierMask.isEmpty
    }
    
    
    
    // MARK: Private Methods
    
    /// Modifier keys string to display.
    private var modifierMaskSymbols: [String] {
        
        ModifierKey.allCases
            .filter { self.modifierMask.contains($0.mask) }
            .map(\.symbol)
    }
    
    
    /// Key equivalent to display.
    private var keyEquivalentSymbol: String {
        
        guard let scalar = self.keyEquivalent.unicodeScalars.first else { return "" }
        
        return Self.keyEquivalentSymbols[scalar]
            ?? self.keyEquivalent.uppercased()
    }
    
    
    /// Some special keys allowed to assign without modifier keys.
    private static let singleKeys: [NSEvent.SpecialKey] = [
        .home,
        .end,
        .pageUp,
        .pageDown,
        .f1,
        .f2,
        .f3,
        .f4,
        .f5,
        .f6,
        .f7,
        .f8,
        .f9,
        .f10,
        .f11,
        .f12,
        .f13,
        .f14,
        .f15,
        .f16,
        .f17,
        .f18,
        .f19,
    ]
    
    
    /// Table for key equivalent that have special symbols to display.
    private static let keyEquivalentSymbols: [Unicode.Scalar: String] = [
        NSEvent.SpecialKey
        .upArrow: "↑",
        .downArrow: "↓",
        .leftArrow: "←",
        .rightArrow: "→",
        .delete: "⌦",
        .backspace: "⌫",
        .home: "↖",
        .end: "↘",
        .pageUp: "⇞",
        .pageDown: "⇟",
        .clearLine: "⌧",
        .carriageReturn: "↩",
        .enter: "⌅",
        .tab: "⇥",
        .backTab: "⇤",
        .escape: "⎋",
        .f1: "F1",
        .f2: "F2",
        .f3: "F3",
        .f4: "F4",
        .f5: "F5",
        .f6: "F6",
        .f7: "F7",
        .f8: "F8",
        .f9: "F9",
        .f10: "F10",
        .f11: "F11",
        .f12: "F12",
        .f13: "F13",
        .f14: "F14",
        .f15: "F15",
        .f16: "F16",
        .f17: "F17",
        .f18: "F18",
        .f19: "F19",
        .help: "Help",
        .space: String(localized: "Space", comment: "keyboard key name"),
        .mic: "🎤︎",  // U+1F3A4, U+FE0E
    ].mapKeys(\.unicodeScalar)
}


private extension NSEvent.SpecialKey {
    
    static let space = Self(rawValue: 0x20)
    static let escape = Self(rawValue: 0x1b)
    static let mic = Self(rawValue: 0x1f3a4)
}


extension Shortcut: Equatable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        
        let lhs = lhs.normalized
        let rhs = rhs.normalized
        
        return lhs.modifierMask == rhs.modifierMask && lhs.keyEquivalent == rhs.keyEquivalent
    }
    
    
    /// Normalize Shortcut by prefering to use the Shift key rather than an upper key equivalent character.
    ///
    /// According to the AppKit's specification, the Command-Shift-c and Command-C should be considered to be identical.
    private var normalized: Self {
        
        let needsShift = self.keyEquivalent.last?.isUppercase == true
        
        let modifierMask = self.modifierMask.union(needsShift ? .shift : [])
        let keyEquivalent = self.keyEquivalent.lowercased()
        
        return Shortcut(modifierMask: modifierMask, keyEquivalent: keyEquivalent)!
    }
}


extension Shortcut: CustomDebugStringConvertible {
    
    var debugDescription: String {
        
        self.symbol
    }
}


extension Shortcut: Hashable {
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(self.modifierMask.rawValue)
        hasher.combine(self.keyEquivalent)
    }
}


extension Shortcut: Codable {
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        guard let shortcut = Shortcut(keySpecChars: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid shortcut format: \(string)")
        }
        
        self = shortcut
    }
    
    
    func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        try container.encode(self.keySpecChars)
    }
}
