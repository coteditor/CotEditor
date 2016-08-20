/*
 
 KeyBindingManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-09-01.
 
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

struct KeyBinding: Hashable, CustomStringConvertible {
    
    let action: Selector
    let shortcut: Shortcut?
    
    
    var description: String {
        
        return "<KeyBinding: \(self.action) - \(self.shortcut)>"
    }
    
    
    var hashValue: Int {
        
        return (self.shortcut?.hashValue ?? -1) ^ self.action.hashValue
    }
    
    
    static func ==(lhs: KeyBinding, rhs: KeyBinding) -> Bool {
        
        return lhs.shortcut == rhs.shortcut && lhs.action == rhs.action
    }
    
}



// MARK: Error

struct InvalidKeySpecCharactersError: LocalizedError {
    
    enum ErrorKind {
        case singleType
        case alreadyTaken
        case lackingCommandKey
        case unwantedCommandKey
    }
    
    let kind: ErrorKind
    let keySpecChars: String
    
    
    var errorDescription: String? {
        
        switch self.kind {
        case .singleType:
            return NSLocalizedString("Single type is invalid for a shortcut.", comment: "")
            
        case .alreadyTaken:
            return String(format: NSLocalizedString("“%@” is already taken.", comment: ""), self.printableKey)
            
        case .lackingCommandKey:
            return String(format: NSLocalizedString("“%@” does not include the Command key.", comment: ""), self.printableKey)
            
        case .unwantedCommandKey:
            return String(format: NSLocalizedString("“%@” includes the Command key.", comment: ""), self.printableKey)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        return NSLocalizedString("Please combinate with another keys.", comment: "")
    }
    
    
    private var printableKey: String {
        
        return Shortcut(keySpecChars: self.keySpecChars).description
    }
    
}



// MARK: -

protocol KeyBindingManagerProtocol: class {
    
    var settingFileName: String { get }
    var keyBindings: Set<KeyBinding> { get }
    var defaultKeyBindings: Set<KeyBinding> { get }
    
    func outlineTree(defaults usesDefaults: Bool) -> [NSTreeNode]
}



class KeyBindingManager: SettingManager, KeyBindingManagerProtocol {
    
    // MARK: Public Properties
    
    lazy var keyBindings: Set<KeyBinding> = {
        
        guard
            let data = try? Data(contentsOf: self.keyBindingSettingFileURL),
            let keyBindings = try? KeyBindingSerialization.keyBindings(from: data)
            else {
                return self.defaultKeyBindings
        }
        
        return keyBindings
    }()
    
    
    
    // MARK: Setting Manager Methods
    
    /// directory name in both Application Support and bundled Resources
    override var directoryName: String {
        
        return "KeyBindings"
    }
    
    
    
    // MARK: Abstract Properties/Methods
    
    /// name of file to save custom key bindings in the plist file form (without extension)
    var settingFileName: String {
        
        preconditionFailure()
    }
    
    
    /// default key bindings
    var defaultKeyBindings: Set<KeyBinding> {
        
        preconditionFailure()
    }
    
    
    /// create a KVO-compatible collection for outlineView in preferences from the key binding setting
    /// - parameter usesDefaults:   `true` for default setting and `false` for the current setting
    func outlineTree(defaults usesDefaults: Bool) -> [NSTreeNode] {
        
        preconditionFailure()
    }
    
    
    
    // MARK: Public Methods
    
    /// file URL to save custom key bindings file
    var keyBindingSettingFileURL: URL {
        
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
        
        let keyBindings = self.keyBindings(from: outlineTree)
        let fileURL = self.keyBindingSettingFileURL
        
        // write to file
        if keyBindings == self.defaultKeyBindings {
            // just remove setting file if the new setting is exactly the same as the default
            try FileManager.default.removeItem(at: fileURL)
        } else {
            let data = try KeyBindingSerialization.data(from: keyBindings)
            try data.write(to: fileURL, options: .atomic)
        }
        
        // store new values
        self.keyBindings = keyBindings
    }
    
    
    /// validate new key spec chars are settable
    /// - throws: InvalidKeySpecCharactersError
    func validate(keySpecChars: String, oldKeySpecChars: String?) throws {
        
        // blank key is always valid
        if keySpecChars.isEmpty { return }
        
        // single key is invalid
        guard keySpecChars.characters.count > 1 else {
            throw InvalidKeySpecCharactersError(kind: .singleType, keySpecChars: keySpecChars)
        }
        
        // duplication check
        let registeredKeySpecChars = self.keyBindings.flatMap { $0.shortcut?.keySpecChars }
        guard keySpecChars == oldKeySpecChars || !registeredKeySpecChars.contains(keySpecChars) else {
            throw InvalidKeySpecCharactersError(kind: .alreadyTaken, keySpecChars: keySpecChars)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// create a plist-compatible collection to save from outlineView data
    private func keyBindings(from outlineTree: [NSTreeNode]) -> Set<KeyBinding> {
    
        var keyBindings = Set<KeyBinding>()
        
        for node in outlineTree {
            if let children = node.children, !children.isEmpty {
                keyBindings.formUnion(self.keyBindings(from: children))
                
            } else {
                guard
                    let keyItem = node.representedObject as? KeyBindingItem,
                    let keySpecChars = keyItem.keySpecChars,
                    !keySpecChars.isEmpty else { continue }
                
                let shortcut = Shortcut(keySpecChars: keySpecChars)
                let action = Selector(keyItem.selector)
                let keyBinding = KeyBinding(action: action, shortcut: shortcut)
                
                keyBindings.insert(keyBinding)
            }
        }
        
        return keyBindings
    }
    
}



// MARK: -

private final class KeyBindingSerialization {
    
    private struct Key {
        static let action = "action"
        static let shortcut = "shortcut"
    }
    
    
    /// create keyBinding collection from the specified data
    static func keyBindings(from data: Data) throws -> Set<KeyBinding> {
        
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        
        guard let plistDict = plist as? [[String: String]], !plistDict.isEmpty else {
            throw NSError(domain: CocoaError.errorDomain, code: CocoaError.propertyListReadCorruptError.rawValue)
        }
        
        let keyBindings: [KeyBinding] = plistDict.flatMap { item in
            guard let action = item[Key.action] else { return nil }
            
            let shortcut: Shortcut? = {
                guard let keySpecChars = item[Key.shortcut] else { return nil }
                return Shortcut(keySpecChars: keySpecChars)
            }()
            
            return KeyBinding(action: Selector(action), shortcut: shortcut)
        }
        
        return Set<KeyBinding>(keyBindings)
    }
    
    
    /// create data to store from a keyBinding collection
    static func data(from keyBindings: Set<KeyBinding>) throws -> Data {
        
        let plist: [[String: String]] = keyBindings.map { keyBinding in
            if let shortcut = keyBinding.shortcut {
                return [Key.action: NSStringFromSelector(keyBinding.action),
                        Key.shortcut: shortcut.keySpecChars]
            } else {
                return [Key.action: NSStringFromSelector(keyBinding.action)]
            }
            }.sorted { $0[Key.action]! < $1[Key.action]! }
        
        return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    }
    
}
