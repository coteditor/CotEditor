//
//  TextKeyBindingMap.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-25.
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

import AppKit
import Shortcut

struct TextKeyBinding: Codable {
    
    var action: Selector
    var shortcuts: [Shortcut]
}


struct TextKeyBindingMap: Equatable {
    
    enum Action: Equatable {
        
        case perform(TextKeyBindingCommand)
        case suppress
    }
    
    
    /// Customized shortcuts; a missing command inherits the system bindings, and an empty array disables its default shortcuts.
    private(set) var customizations: [TextKeyBindingCommand: [Shortcut]] = [:]
    
    private var actions: [Shortcut: Action] = [:]
    
    
    /// Whether any text editing key bindings are customized.
    var isCustomized: Bool {
        
        !self.customizations.isEmpty
    }
    
    
    /// Returns a command's custom shortcuts or its unclaimed default shortcuts.
    ///
    /// - Parameter command: The command whose shortcuts are returned.
    /// - Returns: The custom shortcuts, or default shortcuts not overridden by another customization.
    func shortcuts(for command: TextKeyBindingCommand) -> [Shortcut] {
        
        if let shortcuts = self.customizations[command] {
            return shortcuts
        }
        
        return command.shortcuts.filter { self.actions[$0] == nil }
    }
    
    
    /// Replaces a command's shortcuts, disables them with an empty array, or restores defaults with `nil`.
    ///
    /// - Parameters:
    ///   - shortcuts: The new shortcuts, or `nil` to inherit the system bindings.
    ///   - command: The command to customize.
    /// - Throws: If a shortcut is already assigned to another customized command.
    mutating func setShortcuts(_ shortcuts: [Shortcut]?, for command: TextKeyBindingCommand) throws(Shortcut.CustomizationError) {
        
        var seen: Set<Shortcut> = []
        let shortcuts = shortcuts?.filter { seen.insert($0).inserted }
        
        if let shortcuts, Set(shortcuts) != Set(command.shortcuts) {
            for shortcut in shortcuts {
                if case .perform(let owner)? = self.actions[shortcut], owner != command {
                    throw .alreadyTaken(shortcut, name: String(localized: owner.label))
                }
            }
            self.customizations[command] = shortcuts
            
        } else {
            self.customizations.removeValue(forKey: command)
        }
        
        self.rebuildActions()
    }
    
    
    /// Removes all customizations and restores system key handling.
    mutating func restoreDefaults() {
        
        self = .init()
    }
    
    
    /// Resolves a shortcut to a custom command or suppression.
    ///
    /// - Parameter shortcut: The shortcut to resolve.
    /// - Returns: The custom action, or `nil` to let AppKit interpret the key event.
    func action(for shortcut: Shortcut) -> Action? {
        
        self.actions[shortcut]
    }
    
    
    /// Rebuilds the lookup table, giving explicit assignments priority over suppressed default shortcuts.
    private mutating func rebuildActions() {
        
        var actions: [Shortcut: Action] = [:]
        
        for command in self.customizations.keys {
            for shortcut in command.shortcuts {
                actions[shortcut] = .suppress
            }
        }
        
        for (command, shortcuts) in self.customizations {
            for shortcut in shortcuts {
                actions[shortcut] = .perform(command)
            }
        }
        
        self.actions = actions
    }
}


extension TextKeyBindingMap: Codable {
    
    init(from decoder: any Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let entries = try container.decode([TextKeyBinding].self)
        
        var seenActions: Set<Selector> = []
        for entry in entries {
            guard seenActions.insert(entry.action).inserted else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Duplicate text key binding action: \(entry.action)")
            }
            guard let command = TextKeyBindingCommand.allCases.first(where: { $0.action == entry.action }) else { continue }
            
            try self.setShortcuts(entry.shortcuts, for: command)
        }
    }
    
    
    func encode(to encoder: any Encoder) throws {
        
        var container = encoder.singleValueContainer()
        let entries = self.customizations
            .map { TextKeyBinding(action: $0.key.action, shortcuts: $0.value) }
            .sorted(using: KeyPathComparator(\.action.description))
        
        for entry in entries {
            for shortcut in entry.shortcuts where shortcut.modifiers.contains(.function) {
                throw EncodingError.invalidValue(shortcut, .init(codingPath: encoder.codingPath,
                                                                 debugDescription: "The Fn modifier cannot be stored in a text key binding."))
            }
        }
        
        try container.encode(entries)
    }
}
