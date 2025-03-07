//
//  Shortcut.swift
//  Shortcut
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2025 1024jp
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

extension NSEvent.SpecialKey: @retroactive @unchecked Sendable { }


public struct Shortcut: Sendable {
    
    public var keyEquivalent: String
    public var modifiers: NSEvent.ModifierFlags
    
    
    // MARK: Lifecycle
    
    /// Initializes Shortcut directly from a key equivalent character and modifiers.
    ///
    /// - Note: This initializer accepts the Fn key while the others not.
    public init?(_ keyEquivalent: String, modifiers: NSEvent.ModifierFlags) {
        
        guard !keyEquivalent.isEmpty else { return nil }
        
        self.keyEquivalent = keyEquivalent
        self.modifiers = modifiers
    }
    
    
    public init(_ specialKey: NSEvent.SpecialKey, modifiers: NSEvent.ModifierFlags) {
        
        self.keyEquivalent = String(specialKey.unicodeScalar)
        self.modifiers = modifiers
    }
    
    
    /// Initializes Shortcut from a stored string.
    ///
    /// - Parameter keySpecChars: The storable representation.
    public init?(keySpecChars: String) {
        
        guard let keyEquivalent = keySpecChars.last else { return nil }
        
        let modifierCharacters = keySpecChars.dropLast()
        let modifiers = ModifierKey.validCases
            .filter { modifierCharacters.contains($0.keySpecChar) }
            .mask
        
        self.keyEquivalent = String(keyEquivalent)
        self.modifiers = modifiers
    }
    
    
    /// Initializes Shortcut from a display representation.
    ///
    /// - Parameter string: The shortcut string to display in GUI.
    public init?(symbolRepresentation string: String) {
        
        let components = string.split(whereSeparator: \.isWhitespace)
        
        guard let lastSymbol = components.last, !lastSymbol.isEmpty else { return nil }
        
        let keyEquivalent = Self.keyEquivalentSymbols
            .first { $0.value == lastSymbol }
            .map(\.key)
            .map(String.init) ?? lastSymbol.lowercased()
        
        let modifierCharacters = components.dropLast().joined()
        let modifiers = ModifierKey.validCases
            .filter { modifierCharacters.contains($0.symbol) }
            .mask
        
        self.keyEquivalent = keyEquivalent
        self.modifiers = modifiers
    }
    
    
    /// Initializes Shortcut from a key down event.
    ///
    /// - Parameter event: The key down event.
    public init?(keyDownEvent event: NSEvent) {
        
        assert(event.type == .keyDown)
        
        guard
            let charactersIgnoringModifiers = event.charactersIgnoringModifiers,
            charactersIgnoringModifiers.count == 1
        else { return nil }
        
        // correct the Backspace key
        // -> Backspace:      The key above the Return.
        //    Forward Delete: The key with printed "Delete" where next to the ten key pad.
        // cf. https://developer.apple.com/documentation/appkit/nsmenuitem/1514842-keyequivalent
        let keyEquivalent: String = switch event.specialKey {
            case NSEvent.SpecialKey.delete: String(NSEvent.SpecialKey.backspace.unicodeScalar)
            default: charactersIgnoringModifiers
        }
        
        // remove unwanted Shift
        let ignoresShift = "`~!@#$%^&()_{}|\":<>?=/*-+.'".contains(keyEquivalent)
        let modifiers = event.modifierFlags
            .intersection(ModifierKey.allCases.mask)
            .subtracting(ignoresShift ? .shift : [])
        
        self.keyEquivalent = keyEquivalent
        self.modifiers = modifiers
    }
    
    
    // MARK: Public Methods
    
    /// The unique string to store in plist.
    public var keySpecChars: String {
        
        let shortcut = self.normalized
        let modifierCharacters = ModifierKey.validCases
            .filter { shortcut.modifiers.contains($0.mask) }
            .map(\.keySpecChar)
            .joined()
        
        return modifierCharacters + shortcut.keyEquivalent
    }
    
    
    /// The shortcut string to display.
    public var symbol: String {
        
        let shortcut = self.normalized
        
        return (shortcut.modifierSymbols + [shortcut.keyEquivalentSymbol]).joined(separator: .thinSpace)
    }
    
    
    /// Whether key combination is valid for a shortcut.
    public var isValid: Bool {
        
        guard
            self.keyEquivalent.count == 1,
            !self.modifiers.contains(.function)
        else { return false }
        
        if Self.singleKeys.map(\.unicodeScalar).map(String.init).contains(self.keyEquivalent) {
            return true
        }
        
        guard !self.modifiers.isEmpty else { return false }
        
        return self.modifiers.isSubset(of: ModifierKey.validCases.mask)
    }
    
    
    /// Modifier key strings to display.
    public var modifierSymbols: [String] {
        
        ModifierKey.allCases
            .filter { self.modifiers.contains($0.mask) }
            .map(\.symbol)
    }
    
    
    /// The SF Symbol names for modifier keys to display.
    public var modifierSymbolNames: [String] {
        
        ModifierKey.allCases
            .filter { self.modifiers.contains($0.mask) }
            .map(\.symbolName)
    }
    
    
    /// The key equivalent to display.
    public var keyEquivalentSymbol: String {
        
        guard let scalar = self.keyEquivalent.unicodeScalars.first else { return "" }
        
        return Self.keyEquivalentSymbols[scalar] ?? String(scalar).uppercased()
    }
    
    
    /// The SF Symbol name for key equivalent, if exists.
    public var keyEquivalentSymbolName: String? {
        
        guard let scalar = self.keyEquivalent.unicodeScalars.first else { return nil }
        
        return Self.keyEquivalentSymbolNames[scalar]
    }
    
    
    /// The normalized Shortcut by preferring to use the Shift key rather than an upper key equivalent character.
    ///
    /// According to the AppKit's specification, Command-Shift-c and Command-C should be considered to be identical.
    public var normalized: Self {
        
        let needsShift = self.keyEquivalent.last?.isUppercase == true
        
        let keyEquivalent = self.keyEquivalent.lowercased()
        let modifiers = self.modifiers.union(needsShift ? .shift : [])
        
        return Shortcut(keyEquivalent, modifiers: modifiers) ?? self
    }
    
    
    // MARK: Private Methods
    
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
        .f20,
        .f21,
        .f22,
        .f23,
        .f24,
        .f25,
        .f26,
        .f27,
        .f28,
        .f29,
        .f30,
        .f31,
        .f32,
        .f33,
        .f34,
        .f35,
    ]
    
    
    /// The table for key equivalents that have special symbols to display.
    private static let keyEquivalentSymbols: [Unicode.Scalar: String] = [
        NSEvent.SpecialKey
        .backspace: "⌫",
        .carriageReturn: "↩",
        .newline: "↩",
        .enter: "⌅",
        .delete: "⌫",
        .deleteForward: "⌦",
        .tab: "⇥",
        .backTab: "⇤",
        .upArrow: "↑",
        .downArrow: "↓",
        .leftArrow: "←",
        .rightArrow: "→",
        .pageUp: "⇞",
        .pageDown: "⇟",
        .home: "↖",
        .end: "↘",
        .clearDisplay: "⌧",
        .clearLine: "⌧",
        .help: "Help",
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
        .f20: "F20",
        .f21: "F21",
        .f22: "F22",
        .f23: "F23",
        .f24: "F24",
        .f25: "F25",
        .f26: "F26",
        .f27: "F27",
        .f28: "F28",
        .f29: "F29",
        .f30: "F30",
        .f31: "F31",
        .f32: "F32",
        .f33: "F33",
        .f34: "F34",
        .f35: "F35",
        .space: String(localized: "Space", bundle: .module, comment: "keyboard key name"),
        .mic: "🎤︎",  // U+1F3A4, U+FE0E
    ].mapKeys(\.unicodeScalar)
    
    
    /// The table for key equivalents that have SF Symbols to display.
    static let keyEquivalentSymbolNames: [Unicode.Scalar: String] = [
        NSEvent.SpecialKey
        .backspace: "delete.backward",
        .carriageReturn: "return",
        .newline: "return",
        .enter: "projective",
        .delete: "delete.backward",
        .deleteForward: "delete.forward",
        .tab: "arrow.right.to.line.compact",
        .backTab: "arrow.left.to.line.compact",
        .upArrow: "arrowtriangle.up.fill",
        .downArrow: "arrowtriangle.down.fill",
        .leftArrow: "arrowtriangle.left.fill",
        .rightArrow: "arrowtriangle.right.fill",
        .pageUp: "arrow.up",
        .pageDown: "arrow.down",
        .home: "arrow.up.to.line.compact",
        .end: "arrow.down.to.line.compact",
        .clearDisplay: "clear",
        .clearLine: "clear",
        .formFeed: "arrow.down",
        .help: "questionmark.circle",
        .escape: "escape",
        .mic: "mic",
    ].mapKeys(\.unicodeScalar)
}


private extension NSEvent.SpecialKey {
    
    static let space = Self(rawValue: 0x20)
    static let escape = Self(rawValue: 0x1b)
    static let mic = Self(rawValue: 0x1f3a4)
}


extension Shortcut: Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        
        let lhs = lhs.normalized
        let rhs = rhs.normalized
        
        return lhs.modifiers == rhs.modifiers && lhs.keyEquivalent == rhs.keyEquivalent
    }
}


extension Shortcut: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        
        self.symbol
    }
}


extension Shortcut: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        
        hasher.combine(self.keyEquivalent)
        hasher.combine(self.modifiers.rawValue)
    }
}


extension Shortcut: Codable {
    
    public init(from decoder: any Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        guard let shortcut = Shortcut(keySpecChars: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid shortcut format: \(string)")
        }
        
        self = shortcut
    }
    
    
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        try container.encode(self.keySpecChars)
    }
}


private extension String {
    
    static let thinSpace = "\u{2009}"
}


private extension Dictionary {
    
    /// Returns a new dictionary containing the keys transformed by the given closure with the values of this dictionary.
    ///
    /// - Parameter transform: A closure that transforms a key. Every transformed key must be unique.
    /// - Returns: A dictionary containing transformed keys and the values of this dictionary.
    func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        
        try self.reduce(into: [:]) { $0[try transform($1.key)] = $1.value }
    }
    
    
    /// Returns a new dictionary containing the keys transformed by the given keyPath with the values of this dictionary.
    ///
    /// - Parameter keyPath: The keyPath to the value to transform key. Every transformed key must be unique.
    /// - Returns: A dictionary containing transformed keys and the values of this dictionary.
    func mapKeys<T>(_ keyPath: KeyPath<Key, T>) -> [T: Value] {
        
        self.mapKeys { $0[keyPath: keyPath] }
    }
}
