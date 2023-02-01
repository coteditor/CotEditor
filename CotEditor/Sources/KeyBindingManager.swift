//
//  KeyBindingManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2005-09-01.
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

struct InvalidShortcutError: LocalizedError {
    
    enum ErrorKind {
        
        case singleType
        case alreadyTaken(name: String)
        case shiftOnlyModifier
        case unsupported
    }
    
    var kind: ErrorKind
    var shortcut: Shortcut
    
    
    var errorDescription: String? {
        
        switch self.kind {
            case .singleType:
                return String(localized: "Single type is invalid for a shortcut.")
            
            case let .alreadyTaken(name):
                return String(localized: "“\(self.shortcut.symbol)” is already taken by the “\(name)” command.")
                
            case .shiftOnlyModifier:
                return String(localized: "The Shift key can be used only with another modifier key.")
                
            case .unsupported:
                return String(localized: "The combination “\(self.shortcut.symbol)” is not supported for the key binding customization.")
        }
    }
}



// MARK: -

protocol KeyBindingManagerProtocol: AnyObject {
    
    var settingFileName: String { get }
    var keyBindings: Set<KeyBinding> { get }
    var defaultKeyBindings: Set<KeyBinding> { get }
    
    func outlineTree(defaults usesDefaults: Bool) -> [Node<KeyBindingItem>]
    func commandName(for shortcut: Shortcut) -> String?
}



class KeyBindingManager: SettingManaging, KeyBindingManagerProtocol {
    
    // MARK: Public Properties
    
    final private(set) lazy var keyBindings: Set<KeyBinding> = {
        
        guard
            let data = try? Data(contentsOf: self.keyBindingSettingFileURL),
            let customKeyBindings = try? PropertyListDecoder().decode([KeyBinding].self, from: data)
        else { return self.defaultKeyBindings }
        
        let keyBindings = customKeyBindings.filter { $0.shortcut?.isValid ?? true }
        let defaultKeyBindings = self.defaultKeyBindings
            .filter { kb in !keyBindings.contains { ($0.action == kb.action && $0.tag == kb.tag) || $0.shortcut == kb.shortcut } }
        
        return Set(defaultKeyBindings + keyBindings).filter { $0.shortcut != nil }
    }()
    
    
    
    // MARK: Setting File Managing Protocol
    
    /// Directory name in both Application Support and bundled Resources.
    static let directoryName: String = "KeyBindings"
    
    
    
    // MARK: Abstract Properties/Methods
    
    /// Name of file to save custom key bindings in the plist file form (without extension).
    var settingFileName: String { preconditionFailure() }
    
    /// Default key bindings.
    var defaultKeyBindings: Set<KeyBinding> { preconditionFailure() }
    
    
    /// Create a KVO-compatible collection for NSOutlineView in the settings from the key binding setting.
    ///
    /// - Parameter usesDefaults: `true` for default setting and `false` for the current setting.
    func outlineTree(defaults usesDefaults: Bool) -> [Node<KeyBindingItem>] { preconditionFailure() }
    
    
    /// Find the action that has the given shortcut.
    ///
    /// - Parameter shortcut: The shortcut to find.
    /// - Returns: The command name for the user.
    func commandName(for shortcut: Shortcut) -> String? { preconditionFailure() }
    
    
    
    // MARK: Public Methods
    
    /// File URL to save custom key bindings file.
    final var keyBindingSettingFileURL: URL {
        
        self.userSettingDirectoryURL.appendingPathComponent(self.settingFileName, conformingTo: .propertyList)
    }
    
    
    /// Whether key bindings are not customized.
    var usesDefaultKeyBindings: Bool {
        
        self.keyBindings == self.defaultKeyBindings
    }
    
    
    /// Save passed-in key binding settings.
    ///
    /// - Parameter keyBindings: The key bindings to save.
    func saveKeyBindings(_ keyBindings: [KeyBinding]) throws {
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        let fileURL = self.keyBindingSettingFileURL
        
        let keyBindingsSet = Set(keyBindings)
        let defaultExistsActions = self.defaultKeyBindings.map(\.action)
        let diff = keyBindingsSet.subtracting(self.defaultKeyBindings)
            .filter { $0.shortcut != nil || defaultExistsActions.contains($0.action) }
        
        // write to file
        if diff.isEmpty {
            // just remove setting file if the new setting is exactly the same as the default
            if fileURL.isReachable {
                try FileManager.default.removeItem(at: fileURL)
            }
        } else {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(diff.sorted(\.action.description))
            try data.write(to: fileURL, options: .atomic)
        }
        
        // store new values
        self.keyBindings = keyBindingsSet.filter { $0.shortcut != nil }
    }
    
    
    /// Validate whether the new shortcut is settable.
    ///
    /// - Throws: `InvalidShortcutError`
    /// - Parameters:
    ///   - shortcut: The shortcut to test.
    final class func validate(shortcut: Shortcut) throws {
        
        if shortcut.keyEquivalent == "\u{9}" || shortcut.keyEquivalent == "\u{19}" {  // Tab or Backtab
            throw InvalidShortcutError(kind: .unsupported, shortcut: shortcut)
        }
        
        // avoid shift-only modifier with a letter
        // -> typing Shift + letter inserting an uppercase letter instead of invoking a shortcut
        if shortcut.modifierMask == .shift,
           shortcut.keyEquivalent.contains(where: { $0.isLetter || $0.isNumber })
        {
            throw InvalidShortcutError(kind: .shiftOnlyModifier, shortcut: shortcut)
        }
        
        // single key is invalid
        guard shortcut.isValid else {
            throw InvalidShortcutError(kind: .singleType, shortcut: shortcut)
        }
        
        // duplication check
        if let duplicatedName = [MenuKeyBindingManager.shared,
                                 SnippetKeyBindingManager.shared].lazy
            .compactMap({ $0.commandName(for: shortcut) }).first
        {
            throw InvalidShortcutError(kind: .alreadyTaken(name: duplicatedName), shortcut: shortcut)
        }
    }
}
