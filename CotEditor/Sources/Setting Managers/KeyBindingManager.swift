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
    
    let defaultKeyBindings: [KeyBinding]
    var textKeyBindings = TextKeyBindingMap()
    
    
    // MARK: Private Properties
    
    private let mainMenu: NSMenu
    private let settingDirectoryURL: URL
    
    private var userKeyBindings: [KeyBinding] = []
    private var modifiedKeyBindings: Set<KeyBinding> = []
    
    
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
        self.defaultKeyBindings = Self.scanKeyBindings(in: mainMenu)
        
        let keyBindings: [KeyBinding] = (try? self.loadSettings(from: self.settingFileURL)) ?? []
        self.userKeyBindings = keyBindings.filter { $0.shortcut?.isAssignable ?? true }
        self.textKeyBindings = (try? self.loadSettings(from: self.textSettingFileURL)) ?? TextKeyBindingMap()
        self.modifiedKeyBindings.formUnion(self.userKeyBindings)
    }
    
    
    // MARK: Public Methods
    
    /// Whether the key bindings are customized.
    var isCustomized: Bool {
        
        !self.userKeyBindings.isEmpty || self.textKeyBindings.isCustomized
    }
    
    
    /// A collection of the menu tree to display in the settings view.
    var menuTree: [Node<KeyBindingItem>] {
        
        self.menuTree(of: self.mainMenu)
    }
    
    
    /// Applies all keyboard shortcuts to the main menu.
    func applyShortcutsToMainMenu() {
        
        guard !self.modifiedKeyBindings.isEmpty else { return }
        
        let mainMenu = self.mainMenu
        
        self.clearShortcuts(in: mainMenu)
        self.applyShortcuts(to: mainMenu)
        mainMenu.update()
    }
    
    
    /// Removes all user customization.
    func restoreDefaults() throws {
        
        try self.removeSettingFile(at: self.settingFileURL)
        try self.removeSettingFile(at: self.textSettingFileURL)
        
        self.userKeyBindings.removeAll()
        self.textKeyBindings.restoreDefaults()
        self.applyShortcutsToMainMenu()
        NotificationCenter.default.post(DidUpdateSettingsMessage(), subject: self)
    }
    
    
    /// Saves key bindings in the passed-in tree.
    ///
    /// - Parameter tree: The collection of the menu tree to display in the settings view.
    func save(tree: [Node<KeyBindingItem>]) throws {
        
        let keyBindings = tree
            .flatMap(\.flatValues)
            .filter { $0.shortcut?.isAssignable ?? true }
            .compactMap { KeyBinding(action: $0.action, tag: $0.tag, shortcut: $0.shortcut) }
        
        try self.save(keyBindings: keyBindings)
        
        // apply new settings to the menu
        self.applyShortcutsToMainMenu()
    }
    
    
    /// Saves text editing customizations and makes them available to document editors.
    ///
    /// - Parameter textKeyBindings: The text editing shortcuts to save.
    /// - Throws: If encoding or writing the settings fails.
    func save(textKeyBindings: TextKeyBindingMap) throws {
        
        if let data = try self.userSettingsData(for: textKeyBindings) {
            let fileURL = self.textSettingFileURL
            try FileManager.default.createIntermediateDirectories(to: fileURL)
            try data.write(to: fileURL, options: .atomic)
        } else {
            try self.removeSettingFile(at: self.textSettingFileURL)
        }
        
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
        try bindings.setShortcuts(shortcuts, for: command)  // check conflicts with the other text editing commands
        for shortcut in bindings.shortcuts(for: command) {
            try shortcut.checkCustomizationAvailability(for: self.mainMenu, allowsTextEditingKeys: true)
        }
        
        try self.save(textKeyBindings: bindings)
    }
    
    
    /// Checks whether a shortcut can be assigned to a menu command or a text editing command.
    ///
    /// - Parameters:
    ///   - shortcut: The shortcut to validate.
    ///   - command: The text editing command to add the shortcut to, or `nil` for a menu command.
    /// - Throws: If the shortcut is unsupported or already used by a menu item or a text editing command.
    func checkCustomizationAvailability(for shortcut: Shortcut, command: TextKeyBindingCommand? = nil) throws(Shortcut.CustomizationError) {
        
        try shortcut.checkCustomizationAvailability(for: self.mainMenu, allowsTextEditingKeys: command != nil)
        
        guard let owner = TextKeyBindingCommand.allCases.first(where: { self.textKeyBindings.shortcuts(for: $0).contains(shortcut) }) else { return }
        
        // text editing commands can take over inherited shortcuts of the other commands
        guard let command, owner != command, self.textKeyBindings.customizations[owner] == nil else {
            throw .alreadyTaken(shortcut, name: String(localized: owner.label))
        }
    }
    
    
    /// Returns the encoded user key binding settings as an XML property list, or `nil` if there are no user-defined key bindings.
    ///
    /// - Throws: An error if encoding the key bindings fails.
    /// - Returns: The encoded user key binding data in XML property list format, or `nil` if there are no user key bindings.
    func userSettingsData() throws -> Data? {
        
        try self.userSettingsData(for: self.userKeyBindings)
    }
    
    
    /// Returns the text editing customizations as an XML property list.
    ///
    /// - Returns: The encoded customizations, or `nil` if there are none.
    /// - Throws: If encoding the customizations fails.
    func userTextSettingsData() throws -> Data? {
        
        try self.userSettingsData(for: self.textKeyBindings)
    }
    
    
    /// Imports the given key binding settings data and applies them.
    ///
    /// - Parameters:
    ///   - data: The property-list-encoded user key binding data to import.
    /// - Throws: An error if decoding the data fails.
    func importSetting(data: Data) throws {
        
        let keyBindings = try PropertyListDecoder().decode([KeyBinding].self, from: data)
            .filter { $0.shortcut?.isAssignable ?? true }
        
        try self.save(keyBindings: keyBindings)
        
        // apply new settings to the menu
        self.applyShortcutsToMainMenu()
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
    
    /// File URL to save custom key bindings file.
    private var settingFileURL: URL {
        
        self.settingDirectoryURL
            .appendingPathComponent("Shortcuts", conformingTo: .propertyList)
    }
    
    
    /// The file containing text editing customizations.
    private var textSettingFileURL: URL {
        
        self.settingDirectoryURL
            .appendingPathComponent("TextKeyBindings", conformingTo: .propertyList)
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
    ///
    /// - Parameter fileURL: The settings file to read.
    /// - Returns: The loaded settings, or `nil` if the file does not exist.
    /// - Throws: If reading or decoding the settings fails.
    private func loadSettings<T: Decodable>(from fileURL: URL) throws -> T? {
        
        guard fileURL.isReachable else { return nil }
        
        let data = try Data(contentsOf: fileURL)
        
        return try PropertyListDecoder().decode(T.self, from: data)
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
    
    
    /// Returns the encoded key binding settings as an XML property list, or `nil` if there are no user-defined key bindings.
    ///
    /// - Parameter keyBindings: The user key bindings to encode.
    /// - Throws: An error if encoding the key bindings fails.
    /// - Returns: The encoded user key binding data in XML property list format, or `nil` if there are no user key bindings.
    private func userSettingsData(for keyBindings: [KeyBinding]) throws -> Data? {
        
        guard !keyBindings.isEmpty else { return nil }
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let descriptions = keyBindings.sorted(using: KeyPathComparator(\.action.description))
        
        return try encoder.encode(descriptions)
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
    
    
    /// Saves the passed-in key binding settings to a file.
    ///
    /// - Parameter keyBindings: The key bindings to save.
    private func save(keyBindings: [KeyBinding]) throws {
        
        let defaultExistsActions = self.defaultKeyBindings.map(\.action)
        let userKeyBindings: [KeyBinding] = Set(keyBindings).subtracting(self.defaultKeyBindings)
            .filter { $0.shortcut != nil || defaultExistsActions.contains($0.action) }
        
        // write to file
        if let data = try self.userSettingsData(for: userKeyBindings) {
            let fileURL = self.settingFileURL
            try FileManager.default.createIntermediateDirectories(to: fileURL)
            try data.write(to: fileURL)
            
        } else {
            try self.removeSettingFile(at: self.settingFileURL)
        }
        
        // store new values
        self.userKeyBindings = userKeyBindings
        self.modifiedKeyBindings.formUnion(userKeyBindings)
        NotificationCenter.default.post(DidUpdateSettingsMessage(), subject: self)
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
                
                guard self.needsShortcutUpdate(menuItem) else { return }
                
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
                    self.needsShortcutUpdate(menuItem),
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
