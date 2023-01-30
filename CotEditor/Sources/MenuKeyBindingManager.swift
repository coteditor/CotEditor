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

import AppKit

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
        
        self._defaultKeyBindings = Set(Self.scanMenuKeyBindingRecurrently(menu: mainMenu))
        
        super.init()
    }
    
    
    
    // MARK: Key Binding Manager Methods
    
    /// Name of file to save custom key bindings in the plist file form (without extension).
    override var settingFileName: String {
        
        "Shortcuts"
    }
    
    
    /// Default key bindings.
    override var defaultKeyBindings: Set<KeyBinding> {
        
        self._defaultKeyBindings
    }
    
    
    /// Create a KVO-compatible collection for NSOutlineView in the settings from the key binding setting.
    ///
    /// - Parameter usesDefaults: `true` for default setting and `false` for the current setting.
    override func outlineTree(defaults usesDefaults: Bool) -> [Node<KeyBindingItem>] {
        
        self.outlineTree(menu: NSApp.mainMenu!, defaults: usesDefaults)
    }
    
    
    /// Save passed-in key binding settings.
    ///
    /// - Parameter keyBindings: The key bindings to save.
    override func saveKeyBindings(_ keyBindings: [KeyBinding]) throws {
        
        try super.saveKeyBindings(keyBindings)
        
        // apply new settings to the menu
        self.applyKeyBindingsToMainMenu()
    }
    
    
    
    // MARK: Public Methods
    
    /// Re-apply keyboard shortcut to all menu items.
    func applyKeyBindingsToMainMenu() {
        
        let mainMenu = NSApp.mainMenu!
        
        // first, clear all current shortcut settings
        self.clearMenuKeyBindingRecurrently(menu: mainMenu)
        
        // then apply the latest settings
        self.applyMenuKeyBindingRecurrently(menu: mainMenu)
        mainMenu.update()
    }
    
    
    
    // MARK: Private Methods
    
    /// Return the shortcut for the passed-in selector and menu item tag.
    ///
    /// - Parameters:
    ///   - action: The action selector.
    ///   - tag: The menu item tag.
    ///   - usesDefaults: Whether find the shortcut from the application defaults or user defaults.
    /// - Returns: A Shortcut struct.
    private func shortcut(for action: Selector, tag: Int, defaults usesDefaults: Bool = false) -> Shortcut? {
        
        let keyBindings = usesDefaults ? self.defaultKeyBindings : self.keyBindings
        let keyBinding = keyBindings.first { $0.action == action && $0.tag == tag }
        
        return keyBinding?.shortcut
    }
    
    
    /// Whether shortcut of menu item is allowed to modify.
    ///
    /// - Parameter menuItem: The menu item to check.
    /// - Returns: Whether the given menu item can be modified by users.
    private static func allowsModifying(_ menuItem: NSMenuItem) -> Bool {
        
        // specific item types
        if menuItem.isSeparatorItem ||
            menuItem.isAlternate ||
            menuItem.isHidden ||
            menuItem.keyEquivalentModifierMask.contains(.function) ||
            menuItem.title.isEmpty {
            return false
        }
        
        // specific items
        switch MainMenu.MenuItemTag(rawValue: menuItem.tag) {
            case .recentDocuments:
                return false
            case nil:
                break
        }
        if menuItem.submenu == NSApp.servicesMenu {
            return false
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
                 #selector(NSDocument.saveAs),
                 #selector(NSApplication.showHelp),
                 #selector(NSApplication.orderFrontCharacterPalette):  // = "Emoji & Symbols"
                return false
            
            default: break
        }
        
        return true
    }
    
    
    /// Allow modifying only menu items existed at launch.
    ///
    /// - Parameter menuItem: The menu item to check.
    /// - Returns: Whether the given menu item can be modified by users.
    private func allowsModifying(_ menuItem: NSMenuItem) -> Bool {
        
        guard Self.allowsModifying(menuItem) else { return false }
        
        switch menuItem.action {
            case #selector(NSMenu.submenuAction), .none:
                return true
            case let .some(action):
                return self.defaultKeyBindings.map(\.action).contains(action)
        }
    }
    
    
    /// scan all key bindings as well as selector name in passed-in menu
    private class func scanMenuKeyBindingRecurrently(menu: NSMenu) -> [KeyBinding] {
        
        menu.items
            .filter(Self.allowsModifying)
            .flatMap { menuItem -> [KeyBinding] in
                if let submenu = menuItem.submenu {
                    return self.scanMenuKeyBindingRecurrently(menu: submenu)
                }
                
                guard let action = menuItem.action else { return [] }
                
                let shortcut = Shortcut(modifierMask: menuItem.keyEquivalentModifierMask,
                                        keyEquivalent: menuItem.keyEquivalent)
                
                return [KeyBinding(action: action, tag: menuItem.tag, shortcut: shortcut)]
            }
    }
    
    
    /// clear keyboard shortcuts in the passed-in menu
    private func clearMenuKeyBindingRecurrently(menu: NSMenu) {
        
        menu.items
            .filter(self.allowsModifying)
            .forEach { menuItem in
                if let submenu = menuItem.submenu {
                    return self.clearMenuKeyBindingRecurrently(menu: submenu)
                }
                
                menuItem.keyEquivalent = ""
                menuItem.keyEquivalentModifierMask = []
            }
    }
    
    
    /// apply current keyboard short cutsettings to the passed-in menu
    private func applyMenuKeyBindingRecurrently(menu: NSMenu) {
        
        menu.items
            .filter(self.allowsModifying)
            .forEach { menuItem in
                if let submenu = menuItem.submenu {
                    return self.applyMenuKeyBindingRecurrently(menu: submenu)
                }
                
                guard
                    let action = menuItem.action,
                    let shortcut = self.shortcut(for: action, tag: menuItem.tag)
                else { return }
                
                menuItem.keyEquivalent = shortcut.keyEquivalent
                menuItem.keyEquivalentModifierMask = shortcut.modifierMask
            }
    }
    
    
    /// read key bindings from the menu and create an array data for outlineView in the settings
    private func outlineTree(menu: NSMenu, defaults usesDefaults: Bool) -> [Node<KeyBindingItem>] {
        
        menu.items
            .filter(self.allowsModifying)
            .compactMap { menuItem in
                if let submenu = menuItem.submenu {
                    let subtree = self.outlineTree(menu: submenu, defaults: usesDefaults)
                    
                    guard !subtree.isEmpty else { return nil }  // ignore empty submenu
                    
                    return Node(name: menuItem.title, item: .children(subtree))
                }
                
                guard let action = menuItem.action else { return nil }
                
                let defaultShortcut = self.shortcut(for: action, tag: menuItem.tag, defaults: true)
                let shortcut = usesDefaults
                    ? defaultShortcut
                    : Shortcut(modifierMask: menuItem.keyEquivalentModifierMask, keyEquivalent: menuItem.keyEquivalent)
                
                let item = KeyBindingItem(name: menuItem.title, action: action, tag: menuItem.tag, shortcut: shortcut, defaultShortcut: defaultShortcut)
                
                return Node(name: menuItem.title, item: .value(item))
            }
    }
}
