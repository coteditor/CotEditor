//
//  SnippetKeyBindingManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-22.
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

final class SnippetKeyBindingManager: KeyBindingManager {
    
    // MARK: Public Properties
    
    static let shared = SnippetKeyBindingManager()
    
    
    // MARK: Private Properties
    
    private let defaultSnippets: [String]
    
    private let _defaultKeyBindings: Set<KeyBinding>
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        self._defaultKeyBindings = []
        self.defaultSnippets = UserDefaults.standard.registeredValue(for: .insertCustomTextArray)
        
        super.init()
    }
    
    
    
    // MARK: Key Binding Manager Methods
    
    /// Name of file to save custom key bindings in the plist file form (without extension).
    override var settingFileName: String {
        
        "SnippetKeyBindings"
    }
    
    
    /// Default key bindings.
    override var defaultKeyBindings: Set<KeyBinding> {
        
        self._defaultKeyBindings
    }
    
    
    /// Create a KVO-compatible collection for NSOutlineView in the settings from the key binding setting.
    ///
    /// - Parameter usesDefaults: `true` for default setting and `false` for the current setting.
    override func outlineTree(defaults usesDefaults: Bool) -> [Node<KeyBindingItem>] {
        
        let keyBindings = usesDefaults ? self.defaultKeyBindings : self.keyBindings
        let count = (usesDefaults ? self.defaultSnippets : self.snippets).count
        
        return (0..<count).map { index in
            let name = String(localized: "Insert Text \(index)")
            let action = self.action(index: index)
            let keyBinding = keyBindings.first { $0.action == action }
            
            let item = KeyBindingItem(name: name, action: action, tag: 0, shortcut: keyBinding?.shortcut, defaultShortcut: nil)
            
            return Node(name: name, item: .value(item))
        }
    }
    
    
    /// Whether key bindings are not customized.
    override var usesDefaultKeyBindings: Bool {
        
        (self.snippets == self.defaultSnippets) && super.usesDefaultKeyBindings
    }
    
    
    
    // MARK: Public Methods
    
    /// Return snippet string for key binding if exists.
    ///
    /// - Parameter shortcut: The shortcut for the snippet to obtain.
    /// - Returns: A Snippet struct.
    func snippet(shortcut: Shortcut) -> Snippet? {
        
        guard
            let keyBinding = self.keyBindings.first(where: { $0.shortcut == shortcut }),
            let index = self.snippetIndex(for: keyBinding.action),
            let snippetString = self.snippets[safe: index]
        else { return nil }
        
        return Snippet(snippetString)
    }
    
    
    /// Snippet texts to insert with key binding.
    var snippets: [String] {
        
        get { UserDefaults.standard[.insertCustomTextArray] }
        set { UserDefaults.standard[.insertCustomTextArray] = newValue }
    }
    
    
    func restoreSnippets() {
        
        self.snippets = self.defaultSnippets
    }
    
    
    
    // MARK: Private Methods
    
    /// build selector name for index
    private func action(index: Int) -> Selector {
        
        Selector(String(format: "insertCustomText_%02li:", index))
    }
    
    
    /// extract index number of snippet from selector name
    private func snippetIndex(for action: Selector) -> Int? {
        
        let selector = NSStringFromSelector(action)
        
        guard
            let range = selector.range(of: "(?<=^insertCustomText_)[0-9]{2}(?=:$)", options: .regularExpression)
        else { return nil }
        
        return Int(selector[range])
    }
}
