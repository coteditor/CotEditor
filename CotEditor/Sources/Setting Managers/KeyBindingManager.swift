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
//  © 2014-2026 1024jp
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
import UniformTypeIdentifiers
import Shortcut
import URLUtils

@MainActor final class KeyBindingManager {
    
    /// A message posted after custom key bindings are saved or restored.
    struct DidUpdateSettingsMessage: NotificationCenter.MainActorMessage {
        
        typealias Subject = KeyBindingManager
    }
    
    
    // MARK: Public Properties
    
    static let shared = KeyBindingManager()
    
    let defaultMenuKeyBindings: [MenuKeyBinding]
    var textKeyBindings = TextKeyBindingMap()
    
    
    // MARK: Private Properties
    
    private let mainMenu: NSMenu
    private let settingDirectoryURL: URL
    
    private var userMenuKeyBindings: [MenuKeyBinding] = []
    private var modifiedMenuKeyBindings: Set<MenuKeyBinding> = []
    
    
    // MARK: Lifecycle
    
    /// Loads the current user's shortcut settings for the application menu.
    private convenience init() {
        
        guard let mainMenu = NSApp.mainMenu else {
            fatalError("KeyBindingManager must be initialized after Main.storyboard is loaded.")
        }
        
        self.init(mainMenu: mainMenu, settingDirectoryURL: URL.applicationSupportDirectory(component: "KeyBindings"))
    }
    
    
    /// Loads shortcut settings for a menu from the given directory.
    ///
    /// - Parameters:
    ///   - mainMenu: The main menu whose shortcuts are managed.
    ///   - settingDirectoryURL: The directory containing the shortcut settings.
    init(mainMenu: NSMenu, settingDirectoryURL: URL) {
        
        self.mainMenu = mainMenu
        self.settingDirectoryURL = settingDirectoryURL
        self.defaultMenuKeyBindings = Self.scanKeyBindings(in: mainMenu)
        
        let keyBindings: [MenuKeyBinding] = (try? self.loadSettings(from: self.menuSettingFileURL)) ?? []
        self.userMenuKeyBindings = self.customizations(in: keyBindings)
        self.textKeyBindings = (try? self.loadSettings(from: self.textSettingFileURL)) ?? TextKeyBindingMap()
        self.modifiedMenuKeyBindings = Set(self.userMenuKeyBindings)
    }
    
    
    // MARK: Public Methods
    
    /// Whether the key bindings are customized.
    var isCustomized: Bool {
        
        !self.userMenuKeyBindings.isEmpty || self.textKeyBindings.isCustomized
    }
    
    
    /// A collection of the menu tree to display in the settings view.
    var menuTree: [Node<MenuKeyBindingItem>] {
        
        self.menuTree(of: self.mainMenu)
    }
    
    
    /// Applies all keyboard shortcuts to the main menu.
    func applyShortcutsToMainMenu() {
        
        guard !self.modifiedMenuKeyBindings.isEmpty else { return }
        
        let menuItems = Self.menuItems(in: self.mainMenu, where: self.allowsModifying)
        
        for menuItem in menuItems where self.needsShortcutUpdate(menuItem) {
            menuItem.shortcut = nil
        }
        
        for menuItem in menuItems {
            guard
                self.needsShortcutUpdate(menuItem),
                let action = menuItem.action
            else { continue }
            
            menuItem.allowsAutomaticKeyEquivalentLocalization = false
            menuItem.shortcut = self.shortcut(for: action, tag: menuItem.tag)
        }
        
        self.mainMenu.update()
    }
    
    
    /// Removes all user customization.
    ///
    /// - Throws: If removing the settings files fails.
    func restoreDefaults() throws {
        
        try self.save(menuKeyBindings: [])
        try self.save(textKeyBindings: TextKeyBindingMap())
    }
    
    
    /// Saves menu key bindings in the passed-in tree.
    ///
    /// - Parameter menuTree: The collection of the menu tree to display in the settings view.
    /// - Throws: If encoding or writing the settings fails.
    func save(menuTree: [Node<MenuKeyBindingItem>]) throws {
        
        let keyBindings = menuTree
            .flatMap(\.flatValues)
            .map { MenuKeyBinding(action: $0.action, tag: $0.tag, shortcut: $0.shortcut) }
        
        try self.save(menuKeyBindings: keyBindings)
    }
    
    
    /// Saves text editing customizations and makes them available to document editors.
    ///
    /// - Parameter textKeyBindings: The text editing shortcuts to save.
    /// - Throws: If encoding or writing the settings fails.
    func save(textKeyBindings: TextKeyBindingMap) throws {
        
        try self.writeSettings(self.userSettingsData(for: textKeyBindings), to: self.textSettingFileURL)
        
        self.textKeyBindings = textKeyBindings
        NotificationCenter.default.post(DidUpdateSettingsMessage(), subject: self)
    }
    
    
    /// Validates and saves a command's shortcuts, or restores its system bindings with `nil`.
    ///
    /// - Parameters:
    ///   - shortcuts: The shortcuts to assign, an empty array to disable the command, or `nil` to restore it.
    ///   - command: The text editing command to update.
    /// - Throws: If validation or saving fails.
    func save(shortcuts: [Shortcut]?, for command: TextKeyBindingCommand) throws {
        
        var bindings = self.textKeyBindings
        let current = self.shortcuts(for: command, in: bindings)
        
        if let shortcuts {
            for shortcut in shortcuts where !current.contains(shortcut) {
                try self.checkCustomizationAvailability(for: shortcut, command: command)
            }
        }
        
        // keep the default shortcuts taken by other commands to take them back when released
        let yielded = (bindings.customizations[command] ?? command.shortcuts).filter { !current.contains($0) }
        try bindings.setShortcuts(shortcuts.map { $0 + yielded }, for: command)
        
        try self.save(textKeyBindings: bindings)
    }
    
    
    /// Returns the shortcuts of a text editing command that are not taken by other commands.
    ///
    /// - Parameters:
    ///   - command: The text editing command.
    ///   - textKeyBindings: The text editing key bindings to look up.
    /// - Returns: The shortcuts of the command, excluding the default ones taken by other text editing commands or the menu.
    func shortcuts(for command: TextKeyBindingCommand, in textKeyBindings: TextKeyBindingMap) -> [Shortcut] {
        
        textKeyBindings.shortcuts(for: command).filter { shortcut in
            guard
                command.shortcuts.contains(shortcut),
                let menuItem = self.mainMenu.item(for: shortcut)
            else { return true }
            
            // -> Default shortcuts give way to the ones assigned to menu commands, snippets, or scripts,
            //    but share the key with the default ones of menu commands.
            return self.hasDefaultShortcut(menuItem)
        }
    }
    
    
    /// Checks whether a shortcut can be assigned to a menu command or a text editing command.
    ///
    /// - Parameters:
    ///   - shortcut: The shortcut to validate.
    ///   - command: The text editing command to add the shortcut to, or `nil` for a menu command.
    /// - Throws: If the shortcut is unsupported or already used by a menu item or a text editing command.
    func checkCustomizationAvailability(for shortcut: Shortcut, command: TextKeyBindingCommand? = nil) throws(Shortcut.CustomizationError) {
        
        try shortcut.checkCustomizationAvailability(allowsTextEditingKeys: command != nil)
        
        // -> A menu command takes the key only while it is enabled,
        //    such as Delete with Command-Delete only when a text is selected.
        if let menuItem = self.mainMenu.item(for: shortcut),
           !(command?.shortcuts.contains(shortcut) == true && self.hasDefaultShortcut(menuItem))
        {
            throw .alreadyTaken(shortcut, name: menuItem.commandName)
        }
        
        if let command, self.shortcuts(for: command, in: self.textKeyBindings).contains(shortcut) {
            throw .alreadyTaken(shortcut, name: String(localized: command.label))
        }
        
        if let owner = self.textKeyBindings.explicitOwner(of: shortcut), owner != command {
            throw .alreadyTaken(shortcut, name: String(localized: owner.label))
        }
    }
    
    
    /// Returns the encoded user menu key binding settings as an XML property list, or `nil` if there are no user-defined menu key bindings.
    ///
    /// - Throws: An error if encoding the menu key bindings fails.
    /// - Returns: The encoded user menu key binding data in XML property list format, or `nil` if there are no user menu key bindings.
    func userMenuSettingsData() throws -> Data? {
        
        try self.userSettingsData(for: self.userMenuKeyBindings)
    }
    
    
    /// Returns the text editing customizations as an XML property list.
    ///
    /// - Returns: The encoded customizations, or `nil` if there are none.
    /// - Throws: If encoding the customizations fails.
    func userTextSettingsData() throws -> Data? {
        
        try self.userSettingsData(for: self.textKeyBindings)
    }
    
    
    /// Imports the given menu key binding settings data and applies them.
    ///
    /// - Parameters:
    ///   - data: The property-list-encoded user menu key binding data to import.
    /// - Throws: If decoding or saving the settings fails.
    func importMenuSetting(data: Data) throws {
        
        let keyBindings = try PropertyListDecoder().decode([MenuKeyBinding].self, from: data)
        
        try self.save(menuKeyBindings: keyBindings)
    }
    
    
    /// Imports text editing customizations and applies them to document editors.
    ///
    /// - Parameter data: The property-list-encoded text editing customizations.
    /// - Throws: If decoding or saving the settings fails.
    func importTextSetting(data: Data) throws {
        
        let bindings = try PropertyListDecoder().decode(TextKeyBindingMap.self, from: data)
        
        try self.save(textKeyBindings: bindings)
    }
    
    
    // MARK: Private Methods
    
    /// The file containing menu key binding customizations.
    private var menuSettingFileURL: URL {
        
        self.settingDirectoryURL
            .appendingPathComponent("Shortcuts", conformingTo: .propertyList)
    }
    
    
    /// The file containing text editing customizations.
    private var textSettingFileURL: URL {
        
        self.settingDirectoryURL
            .appendingPathComponent("TextKeyBindings", conformingTo: .propertyList)
    }
    
    
    /// The menu key bindings in effect, with user customizations applied to the defaults.
    private var effectiveMenuKeyBindings: [MenuKeyBinding] {
        
        self.defaultMenuKeyBindings
            .filter { kb in
                !self.userMenuKeyBindings.contains {
                    ($0.action == kb.action && $0.tag == kb.tag) || $0.shortcut == kb.shortcut
                }
            } + self.userMenuKeyBindings.filter { $0.shortcut != nil }
    }
    
    
    /// Loads user settings.
    ///
    /// - Parameter fileURL: The settings file to read.
    /// - Returns: The loaded settings, or `nil` if the file does not exist.
    /// - Throws: If reading or decoding the settings fails.
    private func loadSettings<T: Decodable>(from fileURL: URL) throws -> T? {
        
        guard fileURL.isReachable else { return nil }
        
        let data = try Data(contentsOf: fileURL)
        
        return try PropertyListDecoder().decode(T.self, from: data)
    }
    
    
    /// Writes the settings data to the file, or removes the file if there is nothing to save.
    ///
    /// - Parameters:
    ///   - data: The encoded settings, or `nil` to remove the file.
    ///   - fileURL: The settings file to write.
    /// - Throws: If writing or removing the settings file fails.
    private func writeSettings(_ data: Data?, to fileURL: URL) throws {
        
        if let data {
            try FileManager.default.createIntermediateDirectories(to: fileURL)
            try data.write(to: fileURL, options: .atomic)
        } else {
            try self.removeSettingFile(at: fileURL)
        }
    }
    
    
    /// Removes the setting file in the user domain, if exists.
    ///
    /// - Parameter fileURL: The settings file to remove.
    /// - Throws: If removing the settings file fails.
    private func removeSettingFile(at fileURL: URL) throws {
        
        guard fileURL.isReachable else { return }
        
        try FileManager.default.removeItem(at: fileURL)
        
        // remove also the parent directory
        let parent = fileURL.deletingLastPathComponent()
        if (try? FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: [], options: .skipsHiddenFiles).isEmpty) == true {
            try? FileManager.default.removeItem(at: parent)
        }
    }
    
    
    /// Returns the encoded menu key binding settings as an XML property list, or `nil` if there are no user-defined menu key bindings.
    ///
    /// - Parameter keyBindings: The user menu key bindings to encode.
    /// - Throws: An error if encoding the menu key bindings fails.
    /// - Returns: The encoded user menu key binding data in XML property list format, or `nil` if there are no user menu key bindings.
    private func userSettingsData(for keyBindings: [MenuKeyBinding]) throws -> Data? {
        
        guard !keyBindings.isEmpty else { return nil }
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let sortedKeyBindings = keyBindings.sorted(using: KeyPathComparator(\.action.description))
        
        return try encoder.encode(sortedKeyBindings)
    }
    
    
    /// Encodes text editing customizations when at least one command is customized.
    ///
    /// - Parameter keyBindings: The text editing customizations to encode.
    /// - Returns: The XML property list, or `nil` if no commands are customized.
    /// - Throws: If encoding fails.
    private func userSettingsData(for keyBindings: TextKeyBindingMap) throws -> Data? {
        
        guard keyBindings.isCustomized else { return nil }
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        return try encoder.encode(keyBindings)
    }
    
    
    /// Saves the passed-in menu key binding settings to a file and applies them to the main menu.
    ///
    /// - Parameter menuKeyBindings: The menu key bindings to save.
    /// - Throws: If encoding or writing the settings fails.
    private func save(menuKeyBindings: [MenuKeyBinding]) throws {
        
        let userMenuKeyBindings = self.customizations(in: menuKeyBindings)
        
        try self.writeSettings(self.userSettingsData(for: userMenuKeyBindings), to: self.menuSettingFileURL)
        
        // store new values
        self.userMenuKeyBindings = userMenuKeyBindings
        self.modifiedMenuKeyBindings.formUnion(userMenuKeyBindings)
        
        // apply new settings to the menu
        self.applyShortcutsToMainMenu()
        
        NotificationCenter.default.post(DidUpdateSettingsMessage(), subject: self)
    }
    
    
    /// Extracts the customizations from the passed-in menu key bindings.
    ///
    /// - Parameter keyBindings: The menu key bindings to extract from.
    /// - Returns: The menu key bindings that differ from the defaults, excluding the ones for commands not in the menu or with unassignable shortcuts.
    private func customizations(in keyBindings: [MenuKeyBinding]) -> [MenuKeyBinding] {
        
        // -> Bindings for commands not in the menu would otherwise remove the same shortcuts from the default ones of other commands.
        Set(keyBindings).subtracting(self.defaultMenuKeyBindings)
            .filter { $0.shortcut?.isAssignable ?? true }
            .filter { keyBinding in
                self.defaultMenuKeyBindings.contains { $0.action == keyBinding.action && $0.tag == keyBinding.tag }
            }
    }
    
    
    /// Returns the shortcut for the passed-in selector and menu item tag, taking user customizations into account.
    ///
    /// - Parameters:
    ///   - action: The action selector.
    ///   - tag: The menu item tag.
    /// - Returns: The shortcut, or `nil` if none is assigned.
    private func shortcut(for action: Selector, tag: Int) -> Shortcut? {
        
        self.effectiveMenuKeyBindings
            .first { $0.action == action && $0.tag == tag }?
            .shortcut
    }
    
    
    /// Returns whether the menu item has its default shortcut defined in the storyboard.
    ///
    /// - Parameter menuItem: The menu item to check.
    /// - Returns: `false` if the shortcut is customized or the menu item is a snippet or a script.
    private func hasDefaultShortcut(_ menuItem: NSMenuItem) -> Bool {
        
        guard let action = menuItem.action else { return false }
        
        return self.defaultMenuKeyBindings.contains(MenuKeyBinding(action: action, tag: menuItem.tag, shortcut: menuItem.shortcut))
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
           menuItem.title.isEmpty ||
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
                 #selector(TextDocument.changeLineEnding(_:)),
                 #selector((any SnippetInsertable).insertSnippet),
                 #selector(ScriptManager.launchScript),
                 #selector(AppDelegate.openHelpAnchor),
                 #selector(NSDocument.saveAs),
                 #selector(NSWindow.makeKeyAndOrderFront),  // documents in Window menu
                 #selector(NSApplication.showHelp):
                return false
                
            case #selector(NSTextView.performTextFinderAction):
                return menuItem.tag != TextFinder.Action.multipleReplace.rawValue
                
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
                return self.defaultMenuKeyBindings.contains { $0.action == action }
        }
    }
    
    
    /// Returns whether the shortcut for the given menuItem was customized in the session.
    ///
    /// - Parameter menuItem: The menu item to check.
    /// - Returns: Whether the given menu item was modified by the user.
    private func isModified(_ menuItem: NSMenuItem) -> Bool {
        
        self.modifiedMenuKeyBindings
            .contains { $0.action == menuItem.action && $0.tag == menuItem.tag }
    }
    
    
    /// Returns whether the shortcut for the given menu item should be rewritten.
    ///
    /// - Parameter menuItem: The menu item to check.
    /// - Returns: Whether the given menu item's shortcut should be rewritten while applying custom shortcuts.
    private func needsShortcutUpdate(_ menuItem: NSMenuItem) -> Bool {
        
        guard let action = menuItem.action else { return false }
        
        return self.isModified(menuItem) || menuItem.shortcut != self.shortcut(for: action, tag: menuItem.tag)
    }
    
    
    /// Scans all keyboard shortcuts as well as selector names in passed-in menu.
    ///
    /// - Parameter menu: The menu where to collect key bindings.
    /// - Returns: An array of menu key bindings.
    private static func scanKeyBindings(in menu: NSMenu) -> [MenuKeyBinding] {
        
        Self.menuItems(in: menu, where: Self.allowsModifying)
            .compactMap { menuItem in
                guard let action = menuItem.action else { return nil }
                
                return MenuKeyBinding(action: action, tag: menuItem.tag, shortcut: menuItem.shortcut)
            }
    }
    
    
    /// Collects the menu items without a submenu in the passed-in menu and its submenus.
    ///
    /// - Parameters:
    ///   - menu: The menu where to collect menu items.
    ///   - isIncluded: The predicate to filter menu items; a submenu is skipped if its parent item doesn't satisfy it.
    /// - Returns: The menu items in the menu order.
    private static func menuItems(in menu: NSMenu, where isIncluded: (NSMenuItem) -> Bool) -> [NSMenuItem] {
        
        menu.items
            .filter(isIncluded)
            .flatMap { menuItem in
                if let submenu = menuItem.submenu {
                    Self.menuItems(in: submenu, where: isIncluded)
                } else {
                    [menuItem]
                }
            }
    }
    
    
    /// Returns a collection of the menu tree.
    ///
    /// - Parameters:
    ///   - menu: The menu where to collect key binding items.
    /// - Returns: A tree of MenuKeyBindingItem nodes.
    private func menuTree(of menu: NSMenu) -> [Node<MenuKeyBindingItem>] {
        
        menu.items
            .filter(self.allowsModifying)
            .compactMap { menuItem in
                if let submenu = menuItem.submenu {
                    let subtree = self.menuTree(of: submenu)
                    
                    guard !subtree.isEmpty else { return nil }  // ignore empty submenu
                    
                    return Node(name: menuItem.title, item: .children(subtree))
                }
                
                guard let action = menuItem.action else { return nil }
                
                let defaultShortcut = self.defaultMenuKeyBindings
                    .first { $0.action == action && $0.tag == menuItem.tag }?
                    .shortcut
                let item = MenuKeyBindingItem(action: action, tag: menuItem.tag, shortcut: menuItem.shortcut, defaultShortcut: defaultShortcut)
                
                return Node(name: menuItem.title, item: .value(item))
            }
    }
}
