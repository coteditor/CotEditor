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
//  © 2014-2022 1024jp
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

import Cocoa

struct InvalidShortcutError: LocalizedError {
    
    enum ErrorKind {
        case singleType
        case alreadyTaken(name: String)
        case lackingCommandKey
        case unwantedCommandKey
        case shiftOnlyModifier
    }
    
    let kind: ErrorKind
    let shortcut: Shortcut
    
    
    var errorDescription: String? {
        
        switch self.kind {
            case .singleType:
                return "Single type is invalid for a shortcut.".localized
            
            case let .alreadyTaken(name):
                return String(format: "“%@” is already taken by the “%@” command.".localized, self.shortcut.description, name)
            
            case .lackingCommandKey:
                return String(format: "“%@” does not include the Command key.".localized, self.shortcut.description)
            
            case .unwantedCommandKey:
                return String(format: "“%@” includes the Command key.".localized, self.shortcut.description)
                
            case .shiftOnlyModifier:
                return "The Shift key can be used only with another modifier key.".localized
        }
    }
    
    
    var recoverySuggestion: String? {
        
        return "Please combine with other keys.".localized
    }
    
}



// MARK: -

protocol KeyBindingManagerProtocol: AnyObject {
    
    var settingFileName: String { get }
    var keyBindings: Set<KeyBinding> { get }
    var defaultKeyBindings: Set<KeyBinding> { get }
    
    func outlineTree(defaults usesDefaults: Bool) -> [NSTreeNode]
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
            .filter { kb in !keyBindings.contains { $0.action == kb.action || $0.shortcut == kb.shortcut } }
        
        return Set(defaultKeyBindings + keyBindings).filter { $0.shortcut != nil }
    }()
    
    
    
    // MARK: Setting File Managing Protocol
    
    /// directory name in both Application Support and bundled Resources
    static let directoryName: String = "KeyBindings"
    
    
    
    // MARK: Abstract Properties/Methods
    
    /// name of file to save custom key bindings in the plist file form (without extension)
    var settingFileName: String { preconditionFailure() }
    
    /// default key bindings
    var defaultKeyBindings: Set<KeyBinding> { preconditionFailure() }
    
    
    /// create a KVO-compatible collection for outlineView in preferences from the key binding setting
    ///
    /// - Parameter usesDefaults: `true` for default setting and `false` for the current setting.
    func outlineTree(defaults usesDefaults: Bool) -> [NSTreeNode] { preconditionFailure() }
    
    
    
    // MARK: Public Methods
    
    /// file URL to save custom key bindings file
    final var keyBindingSettingFileURL: URL {
        
        return self.userSettingDirectoryURL.appendingPathComponent(self.settingFileName).appendingPathExtension("plist")
    }
    
    
    /// whether key bindings are not customized
    var usesDefaultKeyBindings: Bool {
        
        return self.keyBindings == self.defaultKeyBindings
    }
    
    
    /// save passed-in key binding settings
    func saveKeyBindings(outlineTree: [NSTreeNode]) throws {
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        let keyBindings = outlineTree.keyBindings
        let fileURL = self.keyBindingSettingFileURL
        
        let defaultExistsAction = self.defaultKeyBindings.map(\.action)
        let diff = keyBindings.subtracting(self.defaultKeyBindings)
            .filter { $0.shortcut != nil || defaultExistsAction.contains($0.action) }
        
        // write to file
        if diff.isEmpty {
            // just remove setting file if the new setting is exactly the same as the default
            if fileURL.isReachable {
                try FileManager.default.removeItem(at: fileURL)
            }
        } else {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(diff.sorted())
            try data.write(to: fileURL, options: .atomic)
        }
        
        // store new values
        self.keyBindings = keyBindings.filter { $0.shortcut != nil }
    }
    
    
    /// validate new key spec chars are settable
    ///
    /// - Throws: `InvalidShortcutError`
    func validate(shortcut: Shortcut, oldShortcut: Shortcut?) throws {
        
        // blank key is always valid
        if shortcut.isEmpty { return }
        
        // single key is invalid
        guard !shortcut.modifierMask.isEmpty, !shortcut.keyEquivalent.isEmpty else {
            throw InvalidShortcutError(kind: .singleType, shortcut: shortcut)
        }
        
        // duplication check
        if shortcut != oldShortcut,
           let duplicatedShortcut = self.keyBindings.first(where: { $0.shortcut == shortcut })
        {
            let name = duplicatedShortcut.name.trimmingCharacters(in: .whitespaces.union(.punctuationCharacters))
            throw InvalidShortcutError(kind: .alreadyTaken(name: name), shortcut: shortcut)
        }
    }
    
}



private extension Collection where Element == NSTreeNode {
    
    var keyBindings: Set<KeyBinding> {
        
        let keyBindings: [KeyBinding] = self.flatMap { node -> [KeyBinding] in
            if let children = node.children, !children.isEmpty {
                return children.keyBindings.sorted()
            }
            
            guard
                let keyItem = node.representedObject as? KeyBindingItem,
                let shortcut = keyItem.shortcut
                else { return [] }
            
            return [KeyBinding(name: keyItem.name, action: keyItem.action, shortcut: shortcut.isValid ? shortcut : nil)]
        }
        
        return Set(keyBindings)
    }
    
}
