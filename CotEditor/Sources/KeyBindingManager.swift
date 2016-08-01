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

protocol KeyBindingManagerProtocol: class {
    
    var keyBindingDict: [String: String] { get }
    var settingFileName: String { get }
    var defaultKeyBindingDict: [String: String] { get }
    
    func outlineTree(defaults usesDefaults: Bool) -> [NSTreeNode]
}



class KeyBindingManager: SettingManager, KeyBindingManagerProtocol {
    
    // MARK: Public Properties
    
    lazy var keyBindingDict: [String: String] = {
        
        if let data = try? Data(contentsOf: self.keyBindingSettingFileURL),
            let customDict = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: String],
            !customDict.isEmpty
        {
            return customDict
        }
        return self.defaultKeyBindingDict
    }()
    
    
    
    // MARK: Superclass Methods
    
    /// directory name in both Application Support and bundled Resources
    override var directoryName: String {
        
        return "KeyBindings"
    }
    
    
    // MARK: Abstract Properties/Methods
    
    /// name of file to save custom key bindings in the plist file form (without extension)
    var settingFileName: String {
        
        preconditionFailure()
    }
    
    
    /// default key binding
    var defaultKeyBindingDict: [String: String] {
        
        preconditionFailure()
    }
    
    
    /// create a KVO-compatible dictionary for outlineView in preferences from the key binding setting
    /// @param usesFactoryDefaults   YES for default setting and NO for the current setting
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
        
        return self.keyBindingDict == self.defaultKeyBindingDict
    }
    
    
    /// save passed-in key binding settings
    func saveKeyBindings(outlineTree: [NSTreeNode]) throws {
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        let plistDict = self.keyBindingDictionary(from: outlineTree)
        let fileURL = self.keyBindingSettingFileURL
        
        // write to file
        if plistDict == self.defaultKeyBindingDict {
            // just remove setting file if the new setting is exactly the same as the default
            try FileManager.default.removeItem(at: fileURL)
        } else {
            let data = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
            try data.write(to: fileURL, options: .atomic)
        }
        
        // store new values
        self.keyBindingDict = plistDict
    }
    
    
    /// validate new key spec chars are settable
    func validate(keySpecChars: String, oldKeySpecChars: String?) throws {
        
        // blank key is always valid
        if keySpecChars.isEmpty { return }
        
        // single key is invalid
        guard keySpecChars.characters.count > 1 else {
            throw NSError(domain: CotEditorError.errorDomain, code: CotEditorError.Code.invalidKeySpecCharacters.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Single type is invalid for a shortcut.", comment: ""),
                                     NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please combinate with another keys.", comment: "")])
        }
        
        // duplication check
        let registeredKeySpecChars = self.keyBindingDict.keys
        guard keySpecChars == oldKeySpecChars || !registeredKeySpecChars.contains(keySpecChars) else {
            throw self.error(messageFormat: "“%@” is already taken.", keySpecChars: keySpecChars)
        }
    }
    
    
    /// create error for keySpecChars validation
    func error(messageFormat: String, keySpecChars: String) -> NSError {
        
        let printableKey = KeyBindingUtils.printableKeyString(keySpecChars: keySpecChars)
        
        return NSError(domain: CotEditorError.errorDomain, code: CotEditorError.Code.invalidKeySpecCharacters.rawValue,
                       userInfo: [NSLocalizedDescriptionKey: String(format: NSLocalizedString(messageFormat, comment: ""), printableKey),
                                  NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please choose another key.", comment: "")])
    }
    
    
    
    // MARK: Private Methods
    
    /// create a plist-compatible dictionary to save from outlineView data
    private func keyBindingDictionary(from outlineTree: [NSTreeNode]) -> [String: String] {
    
        var dictionary = [String: String]()
        
        for node in outlineTree {
            if let children = node.children, !children.isEmpty {
                for (key, value) in self.keyBindingDictionary(from: children) {
                    dictionary[key] = value
                }
                
            } else {
                guard
                    let keyItem = node.representedObject as? KeyBindingItem,
                    let keySpecChars = keyItem.keySpecChars,
                    !keySpecChars.isEmpty else { continue }
                
                dictionary[keySpecChars] = keyItem.selector
            }
        }
        
        return dictionary
    }
    
}
