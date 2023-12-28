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
import IOKit

/// Modifier keys for keyboard shortcut.
///
/// - Note: The order of cases (control, option, shift, and command) is determined in the HIG.
private enum ModifierKey: CaseIterable {
    
    case control
    case option
    case shift
    case command
    case function  // This key modifier is reserved for system applications.
    
    static let validCases: [Self] = Array(Self.allCases[0..<4])
    
    
    /// NSEvent.ModifierFlags representation.
    var mask: NSEvent.ModifierFlags {
        
        switch self {
            case .control: .control
            case .option: .option
            case .shift: .shift
            case .command: .command
            case .function: .function
        }
    }
    
    
    /// Symbol to display in GUI.
    var symbol: String {
        
        switch self {
            case .control: "^"
            case .option: "⌥"
            case .shift: "⇧"
            case .command: "⌘"
            case .function: Self.supportsGlobeKey ? "🌐︎" : "fn"
        }
    }
    
    
    /// SF Symbol name to display in GUI.
    var symbolName: String {
        
        switch self {
            case .control: "control"
            case .option: "option"
            case .shift: "shift"
            case .command: "command"
            case .function: Self.supportsGlobeKey ? "globe" : "fn"
        }
    }
    
    
    /// Symbol to store.
    var keySpecChar: String {
        
        switch self {
            case .control: "^"
            case .option: "~"
            case .shift: "$"
            case .command: "@"
            case .function: preconditionFailure("Fn/Globe key cannot be used for custom shortcuts.")
        }
    }
    
    
    /// Returns `true` if the user keyboard is supposed to have the Globe key.
    private static let supportsGlobeKey = {
        
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleHIDKeyboardEventDriverV2"))
        defer { IOObjectRelease(entry) }
        
        guard let property = IORegistryEntryCreateCFProperty(entry, "SupportsGlobeKey" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else { return false }
        
        return (property as? Int) == 1
    }()
}


private extension [ModifierKey] {
    
    /// NSEvent.ModifierFlags representation.
    var mask: NSEvent.ModifierFlags {
        
        self.reduce(into: []) { $0.formUnion($1.mask) }
    }
}


struct Shortcut {
    
    let keyEquivalent: String
    let modifiers: NSEvent.ModifierFlags
    
    
    // MARK: Lifecycle
    
    /// Initializes Shortcut directly from a key equivalent character and modifiers.
    ///
    /// - Note: This initializer accepts the fn key while the others not.
    init?(_ keyEquivalent: String, modifiers: NSEvent.ModifierFlags) {
        
        guard !keyEquivalent.isEmpty else { return nil }
        
        self.keyEquivalent = keyEquivalent
        self.modifiers = modifiers
    }
    
    
    /// Initializes Shortcut from a stored string.
    ///
    /// - Parameter keySpecChars: The storable representation.
    init?(keySpecChars: String) {
        
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
    init?(symbolRepresentation string: String) {
        
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
    init?(keyDownEvent event: NSEvent) {
        
        assert(event.type == .keyDown)
        
        guard
            let charactersIgnoringModifiers = event.charactersIgnoringModifiers,
            charactersIgnoringModifiers.count == 1
        else { return nil }
        
        // correct the Backspace key
        //  -> Backspace:      The key above the Return.
        //     Forward Delete: The key with printed "Delete" where next to the ten key pad.
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
    
    /// Unique string to store in plist.
    var keySpecChars: String {
        
        let shortcut = self.normalized
        let modifierCharacters = ModifierKey.validCases
            .filter { shortcut.modifiers.contains($0.mask) }
            .map(\.keySpecChar)
            .joined()
        
        return modifierCharacters + shortcut.keyEquivalent
    }
    
    
    /// Shortcut string to display.
    var symbol: String {
        
        let shortcut = self.normalized
        
        return (shortcut.modifierSymbols + [shortcut.keyEquivalentSymbol]).joined(separator: .thinSpace)
    }
    
    
    /// Whether key combination is valid for a shortcut.
    var isValid: Bool {
        
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
    var modifierSymbols: [String] {
        
        ModifierKey.allCases
            .filter { self.modifiers.contains($0.mask) }
            .map(\.symbol)
    }
    
    
    /// SF Symbol name for modifier keys to display.
    var modifierSymbolNames: [String] {
        
        ModifierKey.allCases
            .filter { self.modifiers.contains($0.mask) }
            .map(\.symbolName)
    }
    
    
    /// Key equivalent to display.
    var keyEquivalentSymbol: String {
        
        guard let scalar = self.keyEquivalent.unicodeScalars.first else { return "" }
        
        return Self.keyEquivalentSymbols[scalar] ?? String(scalar).uppercased()
    }
    
    
    /// SF Symbol name for key equivalent if exists
    var keyEquivalentSymbolName: String? {
        
        guard let scalar = self.keyEquivalent.unicodeScalars.first else { return nil }
        
        return Self.keyEquivalentSymbolNames[scalar]
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
    
    
    /// Table for key equivalent that have special symbols to display.
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
        .space: String(localized: "Space", comment: "keyboard key name"),
        .mic: "🎤︎",  // U+1F3A4, U+FE0E
    ].mapKeys(\.unicodeScalar)
    
    
    /// Table for key equivalent that have SF Symbols to display.
    private static let keyEquivalentSymbolNames: [Unicode.Scalar: String] = [
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
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        
        let lhs = lhs.normalized
        let rhs = rhs.normalized
        
        return lhs.modifiers == rhs.modifiers && lhs.keyEquivalent == rhs.keyEquivalent
    }
    
    
    /// Normalizes Shortcut by preferring to use the Shift key rather than an upper key equivalent character.
    ///
    /// According to the AppKit's specification, the Command-Shift-c and Command-C should be considered to be identical.
    var normalized: Self {
        
        let needsShift = self.keyEquivalent.last?.isUppercase == true
        
        let keyEquivalent = self.keyEquivalent.lowercased()
        let modifiers = self.modifiers.union(needsShift ? .shift : [])
        
        return Shortcut(keyEquivalent, modifiers: modifiers) ?? self
    }
}


extension Shortcut: CustomDebugStringConvertible {
    
    var debugDescription: String {
        
        self.symbol
    }
}


extension Shortcut: Hashable {
    
    func hash(into hasher: inout Hasher) {
        
        hasher.combine(self.keyEquivalent)
        hasher.combine(self.modifiers.rawValue)
    }
}


extension Shortcut: Codable {
    
    init(from decoder: any Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        
        guard let shortcut = Shortcut(keySpecChars: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid shortcut format: \(string)")
        }
        
        self = shortcut
    }
    
    
    func encode(to encoder: any Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        try container.encode(self.keySpecChars)
    }
}
