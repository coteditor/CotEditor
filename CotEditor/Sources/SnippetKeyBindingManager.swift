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

class SnippetKeyBindingManager: KeyBindingManager {
    
    // MARK: Public Properties
    
    static let shared = SnippetKeyBindingManager()
    
    
    // MARK: Private Properties
    
    private let defaultSnippets: [String]
    private let _defaultKeyBindingDict: [String: String]
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init() {
        
        _defaultKeyBindingDict = ["$\r": SnippetKeyBindingManager.selectorString(index: 0)]
        self.defaultSnippets = UserDefaults().volatileDomain(forName: UserDefaults.registrationDomain)[CEDefaultInsertCustomTextArrayKey]! as! [String]
        
        super.init()
        
        // read user key bindings if available
        self.keyBindingDict = NSDictionary(contentsOf: self.keyBindingSettingFileURL) as? [String: String] ?? self.defaultKeyBindingDict
    }
    
    
    
    // MARK: Key Binding Manager Methods
    
    /// name of file to save custom key bindings in the plist file form (without extension)
    override var settingFileName: String {
        
        return "TextKeyBindings"
    }
    
    
    override var defaultKeyBindingDict: [String : String] {
        
        return _defaultKeyBindingDict
    }
    
    
    /// create a KVO-compatible dictionary for outlineView in preferences from the key binding setting
    /// @param usesFactoryDefaults   YES for default setting and NO for the current setting
    override func outlineTree(defaults usesDefaults: Bool) -> [NSTreeNode] {
        
        let dict = usesDefaults ? self.defaultKeyBindingDict : self.keyBindingDict
        
        var tree = [NSTreeNode]()
        
        for index in 0...30 {
            let title = String(format: NSLocalizedString("Insert Text %li", comment: ""), index)
            let selectorString = self.dynamicType.selectorString(index: index)
            let definition = (dict.first { (key, value) in value == selectorString })
            
            let item = KeyBindingItem(selector: selectorString, keySpecChars: definition?.key)
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
        if keySpecChars.contains("@") {  // TODO: use const for "@"
            throw self.error(messageFormat: "“%@” includes the Command key.", keySpecChars: keySpecChars)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// return snippet string for key binding if exists
    func snippet(keyEquivalent: String?, modifierMask: NSEventModifierFlags) -> String? {
        
        guard let keyEquivalent = keyEquivalent else { return nil }
        guard !modifierMask.contains(.deviceIndependentFlagsMask) else { return nil }  // check modifier key is pressed  (just in case)
        
        // selector string for the key press
        let keySpecChars = CEKeyBindingUtils.keySpecChars(fromKeyEquivalent: keyEquivalent, modifierMask: modifierMask)
        
        guard let selectorString = self.keyBindingDict[keySpecChars] else { return nil }
        
        let snippets = self.snippets(defaults: false)
        guard let index = self.snippetIndex(forSelectorWithString: selectorString) where index < snippets.count else { return nil }
        
        return snippets[index]
    
    }
    
    
    /// return snippet texts to insert with key binding
    /// param: usesFactoryDefaults   YES for default setting and NO for the current setting
    func snippets(defaults usesDefaults: Bool) -> [String] {
        
        if usesDefaults {
            return self.defaultSnippets
        } else {
            return UserDefaults.standard().stringArray(forKey: CEDefaultInsertCustomTextArrayKey)!
        }
    }
    
    
    /// save texts to insert
    func saveSnippets(_ snippets: [String]) {
        
        UserDefaults.standard().set(snippets, forKey: CEDefaultInsertCustomTextArrayKey)
    }
    
    
    // MARK: Private Methods
    
    /// build selector name for index
    private static func selectorString(index: Int) -> String {
        
        return String(format: "insertCustomText_%02li:", index)
    }
    
    
    /// extract index number of snippet from selector name
    private func snippetIndex(forSelectorWithString selectorString: String) -> Int? {
        
        guard !selectorString.isEmpty else { return nil }
        
        let regex = try! RegularExpression(pattern: "^insertCustomText_([0-9]{2}):$", options: [])
        let result = regex.firstMatch(in: selectorString, options: [], range: selectorString.nsRange)
        
        guard let numberRange = result?.range(at: 1) where numberRange.location != NSNotFound else { return nil }
        
        return Int((selectorString as NSString).substring(with: numberRange))
    }

}
