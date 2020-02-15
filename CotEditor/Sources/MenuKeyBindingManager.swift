//
//  MenuKeyBindingManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2020 1024jp
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

final class MenuKeyBindingManager: KeyBindingManager {
    
    // MARK: Public Properties
    
    static let shared = MenuKeyBindingManager()
    
    
    // MARK: Private Properties
    
    private let _defaultKeyBindings: Set<KeyBinding>
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        guard let mainMenu = NSApp.mainMenu else {
            fatalError("MenuKeyBindingManager should be initialized after Main.storyboard is loaded.")
        }
        
        _defaultKeyBindings = Self.scanMenuKeyBindingRecurrently(menu: mainMenu)
        
        super.init()
    }
    
    
    
    // MARK: Key Binding Manager Methods
    
    /// name of file to save custom key bindings in the plist file form (without extension)
    override var settingFileName: String {
        
        return "Shortcuts"
    }
    
    
    /// default key bindings
    override var defaultKeyBindings: Set<KeyBinding> {
        
        return _defaultKeyBindings
    }
    
    
    /// create a KVO-compatible collection for outlineView in preferences from the key binding setting
    ///
    /// - Parameter usesDefaults: `true` for default setting and `false` for the current setting.
    override func outlineTree(defaults usesDefaults: Bool) -> [NSTreeNode] {
        
        return self.outlineTree(menu: NSApp.mainMenu!, defaults: usesDefaults)
    }
    
    
    /// save passed-in key binding settings
    override func saveKeyBindings(outlineTree: [NSTreeNode]) throws {
        
        try super.saveKeyBindings(outlineTree: outlineTree)
        
        // apply new settings to the menu
        self.applyKeyBindingsToMainMenu()
    }
    
    
    /// validate new key spec chars are settable
    override func validate(shortcut: Shortcut, oldShortcut: Shortcut?) throws {
        
        try super.validate(shortcut: shortcut, oldShortcut: oldShortcut)
        
        // command key existance check
        if !shortcut.isEmpty, !shortcut.modifierMask.contains(.command) {
            throw InvalidKeySpecCharactersError(kind: .lackingCommandKey, shortcut: shortcut)
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// scan key bindings in main menu and store them as default values
    ///
    /// This method should be called before main menu is modified.
    func scanDefaultMenuKeyBindings() {
        
        // do nothing
        // -> Actually, `defaultMenuKeyBindings` is already scanned in `init`.
    }
    
    
    /// re-apply keyboard short cut to all menu items
    func applyKeyBindingsToMainMenu() {
        
        let mainMenu = NSApp.mainMenu!
        
        // at first, clear all current short cut sttings at first
        self.clearMenuKeyBindingRecurrently(menu: mainMenu)
        
        // then apply the latest settings
        self.applyMenuKeyBindingRecurrently(menu: mainMenu)
        mainMenu.update()
    }
    
    
    /// keyEquivalent and modifierMask for passed-in selector
    func shortcut(for action: Selector) -> Shortcut {
        
        let shortcut = self.shortcut(for: action, defaults: false)
        
        guard !shortcut.keyEquivalent.isEmpty, !shortcut.modifierMask.isEmpty else { return .none }
        
        return shortcut
    }
    
    
    
    // MARK: Private Methods
    
    /// return key bindings for selector
    private func shortcut(for action: Selector, defaults usesDefaults: Bool) -> Shortcut {
        
        let keyBindings = usesDefaults ? self.defaultKeyBindings : self.keyBindings
        let definition = keyBindings.first { $0.action == action }
        
        return definition?.shortcut ?? .none
    }
    
    
    /// whether shortcut of menu item is allowed to modify
    private static func allowsModifying(_ menuItem: NSMenuItem) -> Bool {
        
        // specific item types
        if menuItem.isSeparatorItem ||
            menuItem.isAlternate ||
            menuItem.isHidden ||
            menuItem.title.isEmpty {
            return false
        }
        
        // specific tags
        if let tag = MainMenu.MenuItemTag(rawValue: menuItem.tag) {
            switch tag {
            case .services,
                 .recentDocumentsDirectory,
                 .sharingService,
                 .scriptDirectory:
                return false
            }
        }
        
        // specific actions
        switch menuItem.action {
        case #selector(EncodingHolder.changeEncoding),
             #selector(SyntaxHolder.changeSyntaxStyle),
             #selector(ThemeHolder.changeTheme),
             #selector(Document.changeLineEnding(_:)),
             #selector(DocumentViewController.changeTabWidth),
             #selector(ScriptManager.launchScript),
             #selector(AppDelegate.openHelpAnchor),
             #selector(NSWindow.makeKeyAndOrderFront),
             #selector(NSApplication.orderFrontCharacterPalette):  // = "Emoji & Symbols"
            return false
            
        // window tabbing actions
        // -> Because they cannot be set correctly.
        case #selector(NSWindow.selectNextTab),
             #selector(NSWindow.selectPreviousTab),
             #selector(NSWindow.moveTabToNewWindow),
             #selector(NSWindow.mergeAllWindows):
            return false
            
        default: break
        }
        
        return true
    }
    
    
    /// scan all key bindings as well as selector name in passed-in menu
    private class func scanMenuKeyBindingRecurrently(menu: NSMenu) -> Set<KeyBinding> {
        
        let keyBindings: [KeyBinding] = menu.items.lazy
            .filter(self.allowsModifying)
            .map { menuItem -> [KeyBinding] in
                if let submenu = menuItem.submenu {
                    return self.scanMenuKeyBindingRecurrently(menu: submenu).sorted()
                }
                
                guard let action = menuItem.action else { return [] }
                
                let shortcut = Shortcut(modifierMask: menuItem.keyEquivalentModifierMask,
                                        keyEquivalent: menuItem.keyEquivalent)
                
                guard shortcut.isValid else { return [] }
                
                return [KeyBinding(action: action, shortcut: shortcut)]
            }
            .flatMap { $0 }
        
        return Set(keyBindings)
    }
    
    
    /// clear keyboard shortcuts in the passed-in menu
    private func clearMenuKeyBindingRecurrently(menu: NSMenu) {
        
        menu.items.lazy
            .filter(Self.allowsModifying)
            .forEach { menuItem in
                if let submenu = menuItem.submenu {
                    self.clearMenuKeyBindingRecurrently(menu: submenu)
                    return
                }
                
                menuItem.keyEquivalent = ""
                menuItem.keyEquivalentModifierMask = []
            }
    }
    
    
    /// apply current keyboard short cut settings to the passed-in menu
    private func applyMenuKeyBindingRecurrently(menu: NSMenu) {
        
        menu.items.lazy
            .filter(Self.allowsModifying)
            .forEach { menuItem in
                if let submenu = menuItem.submenu {
                    self.applyMenuKeyBindingRecurrently(menu: submenu)
                    return
                }
                
                guard let action = menuItem.action else { return }
                
                let shortcut = self.shortcut(for: action)
                
                // apply only if both keyEquivalent and modifierMask exist
                guard !shortcut.keyEquivalent.isEmpty, !shortcut.modifierMask.isEmpty else { return }
                
                menuItem.keyEquivalent = shortcut.keyEquivalent
                menuItem.keyEquivalentModifierMask = shortcut.modifierMask
            }
    }
    
    
    /// read key bindings from the menu and create an array data for outlineView in preferences
    private func outlineTree(menu: NSMenu, defaults usesDefaults: Bool) -> [NSTreeNode] {
        
        return menu.items.lazy
            .filter(Self.allowsModifying)
            .compactMap { menuItem in
                if let submenu = menuItem.submenu {
                    let node = NamedTreeNode(name: menuItem.title)
                    let subtree = self.outlineTree(menu: submenu, defaults: usesDefaults)
                    
                    guard !subtree.isEmpty else { return nil }  // ignore empty submenu
                    
                    node.mutableChildren.addObjects(from: subtree)
                    return node
                }
                
                guard let action = menuItem.action else { return nil }
                
                let defaultShortcut = self.shortcut(for: action, defaults: true)
                let shortcut = usesDefaults
                    ? defaultShortcut
                    : Shortcut(modifierMask: menuItem.keyEquivalentModifierMask, keyEquivalent: menuItem.keyEquivalent)
                
                let item = KeyBindingItem(action: action, shortcut: shortcut, defaultShortcut: defaultShortcut)
                
                return NamedTreeNode(name: menuItem.title, representedObject: item)
            }
    }
    
}
