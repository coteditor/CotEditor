/*
 
 SnippetKeyBindingManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-22.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class SnippetKeyBindingManager: KeyBindingManager {
    
    // MARK: Public Properties
    
    static let shared = SnippetKeyBindingManager()
    
    
    // MARK: Private Properties
    
    private let defaultSnippets: [String]
    private let _defaultKeyBindings: Set<KeyBinding>
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        _defaultKeyBindings = [KeyBinding(action: SnippetKeyBindingManager.action(index: 0),
                                          shortcut: Shortcut(modifierMask: .shift, keyEquivalent: "\r"))]
        self.defaultSnippets = UserDefaults.standard[.insertCustomTextArray] ?? []
        
        super.init()
        
        self.migrateIfNeeded()
    }
    
    
    
    // MARK: Key Binding Manager Methods
    
    /// name of file to save custom key bindings in the plist file form (without extension)
    override var settingFileName: String {
        
        return "SnippetKeyBindings"
    }
    
    
    /// default key bindings
    override var defaultKeyBindings: Set<KeyBinding> {
        
        return _defaultKeyBindings
    }
    
    
    /// create a KVO-compatible collection for outlineView in preferences from the key binding setting
    /// - parameter usesDefaults:   `true` for default setting and `false` for the current setting
    override func outlineTree(defaults usesDefaults: Bool) -> [NSTreeNode] {
        
        let keyBindings = usesDefaults ? self.defaultKeyBindings : self.keyBindings
        
        return (0...30).map { index in
            let title = String(format: NSLocalizedString("Insert Text %li", comment: ""), index)
            let action = type(of: self).action(index: index)
            let keyBinding = keyBindings.first { $0.action == action }
            
            let item = KeyBindingItem(action: action, shortcut: keyBinding?.shortcut, defaultShortcut: .none)
            
            return NamedTreeNode(name: title, representedObject: item)
        }
    }
    
    
    /// whether key bindings are not customized
    override var usesDefaultKeyBindings: Bool {
        
        let usesDefaultSnippets = self.snippets(defaults: false) == self.defaultSnippets
        
        return usesDefaultSnippets && super.usesDefaultKeyBindings
    }
    
    
    /// validate new key spec chars are settable
    override func validate(shortcut: Shortcut, oldShortcut: Shortcut?) throws {
        
        try super.validate(shortcut: shortcut, oldShortcut: oldShortcut)
        
        // command key existance check
        if shortcut.modifierMask.contains(.command) {
            throw InvalidKeySpecCharactersError(kind: .unwantedCommandKey, shortcut: shortcut)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// return snippet string for key binding if exists
    func snippet(keyEquivalent: String?, modifierMask: NSEvent.ModifierFlags) -> Snippet? {
        
        guard let keyEquivalent = keyEquivalent else { return nil }
        guard !modifierMask.contains(.deviceIndependentFlagsMask) else { return nil }  // check modifier key is pressed  (just in case)
        
        // selector string for the key press
        let shortcut = Shortcut(modifierMask: modifierMask, keyEquivalent: keyEquivalent)
        
        guard let keyBinding = self.keyBindings.first(where: { $0.shortcut == shortcut }) else { return nil }
        
        let snippets = self.snippets(defaults: false)
        
        guard
            let index = type(of: self).snippetIndex(for: keyBinding.action),
            index < snippets.count
            else { return nil }
        
        let snippetString = snippets[index]
        
        return Snippet(snippetString)
    }
    
    
    /// return snippet texts to insert with key binding
    /// param: usesFactoryDefaults   YES for default setting and NO for the current setting
    func snippets(defaults usesDefaults: Bool) -> [String] {
        
        if usesDefaults {
            return self.defaultSnippets
        } else {
            return UserDefaults.standard[.insertCustomTextArray] ?? []
        }
    }
    
    
    /// save texts to insert
    func saveSnippets(_ snippets: [String]) {
        
        UserDefaults.standard[.insertCustomTextArray] = snippets
    }
    
    
    // MARK: Private Methods
    
    /// build selector name for index
    private static func action(index: Int) -> Selector {
        
        return Selector(String(format: "insertCustomText_%02li:", index))
    }
    
    
    /// extract index number of snippet from selector name
    private static func snippetIndex(for action: Selector) -> Int? {
        
        let selectorString = NSStringFromSelector(action)
        
        guard !selectorString.isEmpty else { return nil }
        
        let regex = try! NSRegularExpression(pattern: "^insertCustomText_([0-9]{2}):$")
        let result = regex.firstMatch(in: selectorString, range: selectorString.nsRange)
        
        guard let numberRange = result?.range(at: 1), numberRange.location != NSNotFound else { return nil }
        
        return Int((selectorString as NSString).substring(with: numberRange))
    }

}



// MARK: Migration

private extension SnippetKeyBindingManager {
    
    /// migrate snippet settings if needed
    func migrateIfNeeded() {
        
        guard
            let lastVersionString = UserDefaults.standard[.lastVersion],
            let lastVersion = Int(lastVersionString),
            lastVersion < AppVersion.version3_0,
            !self.keyBindingSettingFileURL.isReachable
            else { return }
        
        self.migrate()
    }
    
    
    /// migrate snippet shortcuts file to CotEditor 3 format (2016-09)
    private func migrate() {
        
        let legacySettingsURL = self.userSettingDirectoryURL.appendingPathComponent("TextKeyBindings.plist")
        
        // -> just abort if failed
        guard
            legacySettingsURL.isReachable,
            let legacyData = try? Data(contentsOf: legacySettingsURL),
            let keyBindings = try? KeyBindingSerialization.keyBindings(migratingFrom: legacyData),
            let data = try? KeyBindingSerialization.data(from: keyBindings)
            else { return }
        
        // save new format file
        try? data.write(to: self.keyBindingSettingFileURL, options: .atomic)
    }
    
}



private extension KeyBindingSerialization {
    
    /// load legacy format (<= CotEditor 2) key bindings setting
    static func keyBindings(migratingFrom data: Data) throws -> [KeyBinding] {
        
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        
        guard let plistDict = plist as? [String: String], !plistDict.isEmpty else {
            throw CocoaError(.propertyListReadCorrupt)
        }
        
        let keyBindings = plistDict.map { KeyBinding(action: Selector($0.value), shortcut: Shortcut(keySpecChars: $0.key)) }
        
        return Set(keyBindings).sorted()
    }
    
}
