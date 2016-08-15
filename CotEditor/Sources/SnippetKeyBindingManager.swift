/*
 
 SnippetKeyBindingManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-22.
 
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

final class SnippetKeyBindingManager: KeyBindingManager {
    
    // MARK: Public Properties
    
    static let shared = SnippetKeyBindingManager()
    
    
    // MARK: Private Properties
    
    private let defaultSnippets: [String]
    private let _defaultKeyBindings: KeyBindings
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override private init() {
        
        _defaultKeyBindings = [Shortcut(modifierMask: .shift, keyEquivalent: "\r"): SnippetKeyBindingManager.selectorString(index: 0)]
        self.defaultSnippets = Defaults[.insertCustomTextArray] ?? []
        
        super.init()
    }
    
    
    
    // MARK: Key Binding Manager Methods
    
    /// name of file to save custom key bindings in the plist file form (without extension)
    override var settingFileName: String {
        
        return "TextKeyBindings"
    }
    
    
    override var defaultKeyBindings: KeyBindings {
        
        return _defaultKeyBindings
    }
    
    
    /// create a KVO-compatible collection for outlineView in preferences from the key binding setting
    /// - parameter usesDefaults:   `true` for default setting and `false` for the current setting
    override func outlineTree(defaults usesDefaults: Bool) -> [NSTreeNode] {
        
        let dict = usesDefaults ? self.defaultKeyBindings : self.keyBindings
        
        var tree = [NSTreeNode]()
        
        for index in 0...30 {
            let title = String(format: NSLocalizedString("Insert Text %li", comment: ""), index)
            let selectorString = self.dynamicType.selectorString(index: index)
            let definition = dict.first { (key, value) in value == selectorString }
            
            let item = KeyBindingItem(selector: selectorString, keySpecChars: definition?.key.keySpecChars)
            let node = NamedTreeNode(name:title, representedObject: item)
            
            tree.append(node)
        }
        
        return tree
    }
    
    
    /// whether key bindings are not customized
    override var usesDefaultKeyBindings: Bool {
        
        let usesDefaultSnippets = self.snippets(defaults: false) == self.defaultSnippets
        
        return usesDefaultSnippets && super.usesDefaultKeyBindings
    }
    
    
    /// validate new key spec chars are settable
    override func validate(keySpecChars: String, oldKeySpecChars: String?) throws {
        
        do {
            try super.validate(keySpecChars: keySpecChars, oldKeySpecChars: oldKeySpecChars)
        }
        
        // command key existance check
        if keySpecChars.contains(ModifierKey.command.keySpecChar) {
            throw InvalidKeySpecCharactersError(kind: .unwantedCommandKey, keySpecChars: keySpecChars)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// return snippet string for key binding if exists
    func snippet(keyEquivalent: String?, modifierMask: NSEventModifierFlags) -> String? {
        
        guard let keyEquivalent = keyEquivalent else { return nil }
        guard !modifierMask.contains(.deviceIndependentFlagsMask) else { return nil }  // check modifier key is pressed  (just in case)
        
        // selector string for the key press
        let shortcut = Shortcut(modifierMask: modifierMask, keyEquivalent: keyEquivalent)
        
        guard let selectorString = self.keyBindings[shortcut] else { return nil }
        
        let snippets = self.snippets(defaults: false)
        guard let index = self.dynamicType.snippetIndex(forSelectorWithString: selectorString), index < snippets.count else { return nil }
        
        return snippets[index]
    
    }
    
    
    /// return snippet texts to insert with key binding
    /// param: usesFactoryDefaults   YES for default setting and NO for the current setting
    func snippets(defaults usesDefaults: Bool) -> [String] {
        
        if usesDefaults {
            return self.defaultSnippets
        } else {
            return Defaults[.insertCustomTextArray] ?? []
        }
    }
    
    
    /// save texts to insert
    func saveSnippets(_ snippets: [String]) {
        
        Defaults[.insertCustomTextArray] = snippets
    }
    
    
    // MARK: Private Methods
    
    /// build selector name for index
    private static func selectorString(index: Int) -> String {
        
        return String(format: "insertCustomText_%02li:", index)
    }
    
    
    /// extract index number of snippet from selector name
    private static func snippetIndex(forSelectorWithString selectorString: String) -> Int? {
        
        guard !selectorString.isEmpty else { return nil }
        
        let regex = try! NSRegularExpression(pattern: "^insertCustomText_([0-9]{2}):$")
        let result = regex.firstMatch(in: selectorString, range: selectorString.nsRange)
        
        guard let numberRange = result?.rangeAt(1), numberRange.location != NSNotFound else { return nil }
        
        return Int((selectorString as NSString).substring(with: numberRange))
    }

}
