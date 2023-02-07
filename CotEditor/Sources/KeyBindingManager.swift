//
//  KeyBindingManager.swift
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

final class KeyBindingManager: SettingManaging {
    
    // MARK: Public Properties
    
    static let shared = KeyBindingManager()
    
    
    // MARK: Setting Managing Properties
    
    static let directoryName: String = "KeyBindings"
    
    
    // MARK: Private Properties
    
    private let defaultKeyBindings: Set<KeyBinding>
    private var keyBindings: Set<KeyBinding> = []
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private init() {
        
        guard let mainMenu = NSApp.mainMenu else {
            fatalError("KeyBindingManager must be initialized after Main.storyboard is loaded.")
        }
        
        self.defaultKeyBindings = Set(Self.scanKeyBindings(in: mainMenu))
        
        let customKeyBindings = (try? self.loadSettings()) ?? []
        let keyBindings = self.defaultKeyBindings
            .filter { kb in
                !customKeyBindings.contains {
                    ($0.action == kb.action && $0.tag == kb.tag) || $0.shortcut == kb.shortcut
                }
            } + customKeyBindings
        
        self.keyBindings = Set(keyBindings).filter { $0.shortcut != nil }
    }
    
    
    
    // MARK: Public Methods
    
    /// Whether shortcuts are customized.
    var isCustomized: Bool {
        
        self.keyBindings != self.defaultKeyBindings.filter { $0.shortcut != nil }
    }
    
    
    /// A collection of the menu tree to display in the settings view.
    var menuTree: [Node<KeyBindingItem>] {
        
        self.menuTree(of: NSApp.mainMenu!)
    }
    
    
    /// Apply all keyboard shortcuts to the main menu.
    func applyShortcutsToMainMenu() {
        
        let mainMenu = NSApp.mainMenu!
        
        self.clearShortcuts(in: mainMenu)
        self.applyShortcuts(to: mainMenu)
        mainMenu.update()
    }
    
    
    /// Remove all user costomization.
    func restoreDefaults() throws {
        
        try self.saveKeyBindings(self.defaultKeyBindings.unique)
    }
    
    
    /// Find the action that has the given shortcut.
    ///
    /// - Parameter shortcut: The shortcut to find.
    /// - Returns: The command name for the user.
    func commandName(for shortcut: Shortcut) -> String? {
        
        self.commandName(for: shortcut, in: NSApp.mainMenu!)
    }
    
    
    /// Save passed-in key binding settings.
    ///
    /// - Parameter keyBindings: The key bindings to save.
    func saveKeyBindings(_ keyBindings: [KeyBinding]) throws {
        
        let fileURL = self.settingFileURL
        
        let keyBindingsSet = Set(keyBindings)
        let defaultExistsActions = self.defaultKeyBindings.map(\.action)
        let diff = keyBindingsSet.subtracting(self.defaultKeyBindings)
            .filter { $0.shortcut != nil || defaultExistsActions.contains($0.action) }
        
        // write to file
        if diff.isEmpty {
            // just remove setting file if the new setting is exactly the same as the default
            if fileURL.isReachable {
                try FileManager.default.removeItem(at: fileURL)
                let parent = fileURL.deletingLastPathComponent()
                if try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: [], options: .skipsHiddenFiles).isEmpty {
                    try FileManager.default.removeItem(at: parent)
                }
            }
        } else {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(diff.sorted(\.action.description))
            
            try self.prepareUserSettingDirectory()
            try data.write(to: fileURL, options: .atomic)
        }
        
        // store new values
        self.keyBindings = keyBindingsSet.filter { $0.shortcut != nil }
        
        // apply new settings to the menu
        self.applyShortcutsToMainMenu()
    }
    
    
    
    // MARK: Private Methods
    
    /// File URL to save custom key bindings file.
    private var settingFileURL: URL {
        
        self.userSettingDirectoryURL.appendingPathComponent("Shortcuts", conformingTo: .propertyList)
    }
    
    
    /// Load user settings.
    private func loadSettings() throws -> [KeyBinding] {
        
        let fileURL = self.settingFileURL
        
        guard fileURL.isReachable else { return [] }
        
        let data = try Data(contentsOf: fileURL)
        let keyBindings = try PropertyListDecoder().decode([KeyBinding].self, from: data)
        
        return keyBindings.filter { $0.shortcut?.isValid ?? true }
    }
    
    
    /// Return the shortcut for the passed-in selector and menu item tag.
    ///
    /// - Parameters:
    ///   - action: The action selector.
    ///   - tag: The menu item tag.
    ///   - usesDefaults: Whether find the shortcut from the application defaults or user defaults.
    /// - Returns: A Shortcut struct.
    private func shortcut(for action: Selector, tag: Int, defaults usesDefaults: Bool = false) -> Shortcut? {
        
        (usesDefaults ? self.defaultKeyBindings : self.keyBindings)
            .first { $0.action == action && $0.tag == tag }?
            .shortcut
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
                 #selector(SnippetInsertable.insertSnippet),
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
    
    
    /// Scan all keyboard shortcuts as well as selector names in passed-in menu.
    ///
    /// - Parameter menu: The menu where to collect key bindings.
    /// - Returns: An array of KeyBindings.
    private class func scanKeyBindings(in menu: NSMenu) -> [KeyBinding] {
        
        menu.items
            .filter(Self.allowsModifying)
            .flatMap { menuItem -> [KeyBinding] in
                if let submenu = menuItem.submenu {
                    return self.scanKeyBindings(in: submenu)
                }
                
                guard let action = menuItem.action else { return [] }
                
                let shortcut = Shortcut(modifierMask: menuItem.keyEquivalentModifierMask,
                                        keyEquivalent: menuItem.keyEquivalent)
                
                return [KeyBinding(action: action, tag: menuItem.tag, shortcut: shortcut)]
            }
    }
    
    
    /// Clear all keyboard shortcuts in the passed-in menu.
    ///
    /// - Parameter menu: The menu where to remove shortcuts.
    private func clearShortcuts(in menu: NSMenu) {
        
        menu.items
            .filter(self.allowsModifying)
            .forEach { menuItem in
                if let submenu = menuItem.submenu {
                    return self.clearShortcuts(in: submenu)
                }
                
                menuItem.keyEquivalent = ""
                menuItem.keyEquivalentModifierMask = []
            }
    }
    
    
    /// Apply current keyboard shortcut settings to the passed-in menu.
    ///
    /// - Parameter menu: The menu where to apply shortcuts.
    private func applyShortcuts(to menu: NSMenu) {
        
        menu.items
            .filter(self.allowsModifying)
            .forEach { menuItem in
                if let submenu = menuItem.submenu {
                    return self.applyShortcuts(to: submenu)
                }
                
                guard
                    let action = menuItem.action,
                    let shortcut = self.shortcut(for: action, tag: menuItem.tag)
                else { return }
                
                menuItem.keyEquivalent = shortcut.keyEquivalent
                menuItem.keyEquivalentModifierMask = shortcut.modifierMask
            }
    }
    
    
    /// A collection of the menu tree.
    ///
    /// - Parameters:
    ///   - menu: The menu where to collect key binding items.
    /// - Returns: A tree of KeyBindingItem nodes.
    private func menuTree(of menu: NSMenu) -> [Node<KeyBindingItem>] {
        
        menu.items
            .filter(self.allowsModifying)
            .compactMap { menuItem in
                if let submenu = menuItem.submenu {
                    let subtree = self.menuTree(of: submenu)
                    
                    guard !subtree.isEmpty else { return nil }  // ignore empty submenu
                    
                    return Node(name: menuItem.title, item: .children(subtree))
                }
                
                guard let action = menuItem.action else { return nil }
                
                let shortcut = Shortcut(modifierMask: menuItem.keyEquivalentModifierMask, keyEquivalent: menuItem.keyEquivalent)
                let defaultShortcut = self.shortcut(for: action, tag: menuItem.tag, defaults: true)
                let item = KeyBindingItem(action: action, tag: menuItem.tag, shortcut: shortcut, defaultShortcut: defaultShortcut)
                
                return Node(name: menuItem.title, item: .value(item))
            }
    }
    
    
    /// Find the action that has the given shortcut in the menu.
    private func commandName(for shortcut: Shortcut, in menu: NSMenu) -> String? {
        
        menu.items.lazy
            .filter { $0.action != #selector(ScriptManager.launchScript) }
            .compactMap { menuItem in
                if let submenu = menuItem.submenu {
                    return self.commandName(for: shortcut, in: submenu)
                }
                
                guard shortcut == Shortcut(modifierMask: menuItem.keyEquivalentModifierMask,
                                           keyEquivalent: menuItem.keyEquivalent)
                else { return nil }
                
                return menuItem.title
            }
            .first?
            .trimmingCharacters(in: .whitespaces.union(.punctuationCharacters))  // remove ellipsis
    }
}
