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
//  © 2014-2025 1024jp
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
import Shortcut
import URLUtils

@MainActor final class KeyBindingManager {
    
    // MARK: Public Properties
    
    static let shared = KeyBindingManager()
    
    let defaultKeyBindings: [KeyBinding]
    
    
    // MARK: Private Properties
    
    private var userKeyBindings: [KeyBinding] = []
    private var modifiedKeyBindings: Set<KeyBinding> = []
    
    
    // MARK: Lifecycle
    
    private init() {
        
        guard let mainMenu = NSApp.mainMenu else {
            fatalError("KeyBindingManager must be initialized after Main.storyboard is loaded.")
        }
        
        self.defaultKeyBindings = Self.scanKeyBindings(in: mainMenu)
        self.userKeyBindings = (try? self.loadSettings()) ?? []
        
        self.modifiedKeyBindings.formUnion(self.userKeyBindings)
    }
    
    
    // MARK: Public Methods
    
    /// Whether shortcuts are customized.
    var isCustomized: Bool {
        
        !self.userKeyBindings.isEmpty
    }
    
    
    /// A collection of the menu tree to display in the settings view.
    var menuTree: [Node<KeyBindingItem>] {
        
        self.menuTree(of: NSApp.mainMenu!)
    }
    
    
    /// Applies all keyboard shortcuts to the main menu.
    func applyShortcutsToMainMenu() {
        
        guard !self.modifiedKeyBindings.isEmpty else { return }
        
        let mainMenu = NSApp.mainMenu!
        
        self.clearShortcuts(in: mainMenu)
        self.applyShortcuts(to: mainMenu)
        mainMenu.update()
    }
    
    
    /// Removes all user customization.
    func restoreDefaults() throws {
        
        try self.removeSettingFile()
        
        self.userKeyBindings.removeAll()
        self.applyShortcutsToMainMenu()
    }
    
    
    /// Saves the passed-in key binding settings.
    ///
    /// - Parameter keyBindings: The key bindings to save.
    func saveKeyBindings(_ keyBindings: [KeyBinding]) throws {
        
        let defaultExistsActions = self.defaultKeyBindings.map(\.action)
        
        // store new values
        self.userKeyBindings = Set(keyBindings).subtracting(self.defaultKeyBindings)
            .filter { $0.shortcut != nil || defaultExistsActions.contains($0.action) }
        self.modifiedKeyBindings.formUnion(self.userKeyBindings)
        
        // write to file
        if self.userKeyBindings.isEmpty {
            try self.removeSettingFile()
        } else {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let descriptions = self.userKeyBindings.sorted(using: SortDescriptor(\.action.description))
            let data = try encoder.encode(descriptions)
            let fileURL = self.settingFileURL
            
            try FileManager.default.createIntermediateDirectories(to: fileURL)
            try data.write(to: fileURL)
        }
        
        // apply new settings to the menu
        self.applyShortcutsToMainMenu()
    }
    
    
    // MARK: Private Methods
    
    /// File URL to save custom key bindings file.
    private var settingFileURL: URL {
        
        URL.applicationSupportDirectory(component: "KeyBindings")
            .appendingPathComponent("Shortcuts", conformingTo: .propertyList)
    }
    
    
    /// Actual key bindings.
    private var keyBindings: [KeyBinding] {
        
        self.defaultKeyBindings
            .filter { kb in
                !self.userKeyBindings.contains {
                    ($0.action == kb.action && $0.tag == kb.tag) || $0.shortcut == kb.shortcut
                }
            } + self.userKeyBindings.filter { $0.shortcut != nil }
    }
    
    
    /// Loads user settings.
    private func loadSettings() throws -> [KeyBinding] {
        
        let fileURL = self.settingFileURL
        
        guard fileURL.isReachable else { return [] }
        
        let data = try Data(contentsOf: fileURL)
        let keyBindings = try PropertyListDecoder().decode([KeyBinding].self, from: data)
        
        return keyBindings.filter { $0.shortcut?.isValid ?? true }
    }
    
    
    /// Removes the setting file in the user domain, if exists.
    private func removeSettingFile() throws {
        
        guard self.settingFileURL.isReachable else { return }
        
        try FileManager.default.removeItem(at: self.settingFileURL)
        
        // remove also the parent directory
        let parent = self.settingFileURL.deletingLastPathComponent()
        if try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: [], options: .skipsHiddenFiles).isEmpty {
            try FileManager.default.removeItem(at: parent)
        }
    }
    
    
    /// Returns the shortcut for the passed-in selector and menu item tag.
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
            menuItem.keyEquivalentModifierMask.contains(.function) {
            return false
        }
        
        // specific items
        if menuItem.submenu == NSApp.servicesMenu {
            return false
        }
        
        // specific actions
        switch menuItem.action {
            case #selector((any EncodingChanging).changeEncoding),
                 #selector((any SyntaxChanging).changeSyntax),
                 #selector((any ThemeChanging).changeTheme),
                 #selector(Document.changeLineEnding(_:)),
                 #selector((any SnippetInsertable).insertSnippet),
                 #selector(ScriptManager.launchScript),
                 #selector(AppDelegate.openHelpAnchor),
                 #selector(NSDocument.saveAs),
                 #selector(NSWindow.makeKeyAndOrderFront),  // documents in Window menu
                 #selector(NSApplication.showHelp):
                return false
                
            default: break
        }
        
        return true
    }
    
    
    /// Allows modifying only menu items existed at launch.
    ///
    /// - Parameter menuItem: The menu item to check.
    /// - Returns: Whether the given menu item can be modified by the user.
    private func allowsModifying(_ menuItem: NSMenuItem) -> Bool {
        
        guard Self.allowsModifying(menuItem) else { return false }
        
        switch menuItem.action {
            case #selector(NSMenu.submenuAction), .none:
                return true
            case .some(let action):
                return self.defaultKeyBindings.contains { $0.action == action }
        }
    }
    
    
    /// Returns whether the shortcut for the given menuItem was customized in the session.
    ///
    /// - Parameter menuItem: The menu item to check.
    /// - Returns: Whether the given menu item was modified by the user.
    private func isModified(_ menuItem: NSMenuItem) -> Bool {
        
        self.modifiedKeyBindings
            .contains { $0.action == menuItem.action && $0.tag == menuItem.tag }
    }
    
    
    /// Scans all keyboard shortcuts as well as selector names in passed-in menu.
    ///
    /// - Parameter menu: The menu where to collect key bindings.
    /// - Returns: An array of KeyBindings.
    private static func scanKeyBindings(in menu: NSMenu) -> [KeyBinding] {
        
        menu.items
            .filter { Self.allowsModifying($0) }
            .flatMap { menuItem -> [KeyBinding] in
                if let submenu = menuItem.submenu {
                    return self.scanKeyBindings(in: submenu)
                }
                
                guard let action = menuItem.action else { return [] }
                
                return [KeyBinding(action: action, tag: menuItem.tag, shortcut: menuItem.shortcut)]
            }
    }
    
    
    /// Clears keyboard shortcuts to be modified in the passed-in menu.
    ///
    /// - Parameter menu: The menu where to remove shortcuts.
    private func clearShortcuts(in menu: NSMenu) {
        
        menu.items
            .filter { self.allowsModifying($0) }
            .forEach { menuItem in
                if let submenu = menuItem.submenu {
                    return self.clearShortcuts(in: submenu)
                }
                
                guard self.isModified(menuItem) else { return }
                
                menuItem.shortcut = nil
            }
    }
    
    
    /// Applies keyboard shortcuts customized by the user to the passed-in menu.
    ///
    /// - Parameter menu: The menu where to apply shortcuts.
    private func applyShortcuts(to menu: NSMenu) {
        
        menu.items
            .filter { self.allowsModifying($0) }
            .forEach { menuItem in
                if let submenu = menuItem.submenu {
                    return self.applyShortcuts(to: submenu)
                }
                
                guard
                    self.isModified(menuItem),
                    let action = menuItem.action
                else { return }
                
                menuItem.allowsAutomaticKeyEquivalentLocalization = false
                menuItem.shortcut = self.shortcut(for: action, tag: menuItem.tag)
            }
    }
    
    
    /// Returns a collection of the menu tree.
    ///
    /// - Parameters:
    ///   - menu: The menu where to collect key binding items.
    /// - Returns: A tree of KeyBindingItem nodes.
    private func menuTree(of menu: NSMenu) -> [Node<KeyBindingItem>] {
        
        menu.items
            .filter { self.allowsModifying($0) }
            .compactMap { menuItem in
                if let submenu = menuItem.submenu {
                    let subtree = self.menuTree(of: submenu)
                    
                    guard !subtree.isEmpty else { return nil }  // ignore empty submenu
                    
                    return Node(name: menuItem.title, item: .children(subtree))
                }
                
                guard let action = menuItem.action else { return nil }
                
                let defaultShortcut = self.shortcut(for: action, tag: menuItem.tag, defaults: true)
                let item = KeyBindingItem(action: action, tag: menuItem.tag, shortcut: menuItem.shortcut, defaultShortcut: defaultShortcut)
                
                return Node(name: menuItem.title, item: .value(item))
            }
    }
}
