//
//  ModifierKey.swift
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

/// Modifier keys for keyboard shortcut.
///
/// - Note: The order of cases (control, option, shift, and command) is determined in the HIG.
enum ModifierKey: CaseIterable {
    
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
    
    
    /// The symbol string to display in GUI.
    var symbol: String {
        
        switch self {
            case .control: "^"
            case .option: "⌥"
            case .shift: "⇧"
            case .command: "⌘"
            case .function: Self.supportsGlobeKey ? "🌐︎" : "fn"
        }
    }
    
    
    /// The SF Symbol name to display in GUI.
    var symbolName: String {
        
        switch self {
            case .control: "control"
            case .option: "option"
            case .shift: "shift"
            case .command: "command"
            case .function: Self.supportsGlobeKey ? "globe" : "fn"
        }
    }
    
    
    /// The symbol string to store.
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


extension [ModifierKey] {
    
    /// The `NSEvent.ModifierFlags` representation.
    var mask: NSEvent.ModifierFlags {
        
        NSEvent.ModifierFlags(self.map(\.mask))
    }
}
