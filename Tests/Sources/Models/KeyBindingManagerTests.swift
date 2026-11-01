//
//  KeyBindingManagerTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-10-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import Testing
import Shortcut
@testable import CotEditor

@MainActor struct KeyBindingManagerTests {
    
    /// Tests saving and loading text customizations alongside the unchanged menu settings format.
    ///
    /// - Throws: If preparing, saving, or loading settings fails.
    @Test func persistsMenuAndTextBindings() throws {
        
        try self.withManager { manager, directoryURL in
            let menuData = try PropertyListEncoder().encode([KeyBinding(action: #selector(NSText.copy), shortcut: Shortcut("c", modifiers: [.command, .option]))])
            try manager.importSetting(data: menuData)
            var bindings = TextKeyBindingMap()
            try bindings.setShortcuts([Shortcut(.home, modifiers: [])], for: .moveToLeftEndOfLine)
            try bindings.setShortcuts([], for: .pageDown)
            var updates = 0
            let observer = NotificationCenter.default.addObserver(of: manager, for: KeyBindingManager.DidUpdateSettingsMessage.self) { _ in
                updates += 1
            }
            defer { withExtendedLifetime(observer) { } }
            try manager.save(textKeyBindings: bindings)
            
            let reloaded = KeyBindingManager(mainMenu: self.makeMenu(), settingDirectoryURL: directoryURL)
            #expect(reloaded.textKeyBindings == bindings)
            #expect(reloaded.isCustomized)
            #expect(updates == 1)
            let storedMenu = try Data(contentsOf: directoryURL.appending(path: "Shortcuts.plist"))
            #expect(try PropertyListDecoder().decode([KeyBinding].self, from: storedMenu).count == 1)
            reloaded.applyShortcutsToMainMenu()
            #expect(reloaded.menuTree.first?.flatValues.first?.shortcut == Shortcut("c", modifiers: [.command, .option]))
            
            try reloaded.save(tree: reloaded.menuTree)
            #expect(try PropertyListDecoder().decode(TextKeyBindingMap.self, from: Data(contentsOf: directoryURL.appending(path: "TextKeyBindings.plist"))) == bindings)
        }
    }
    
    
    /// Tests loading a legacy menu settings file without text customizations.
    ///
    /// - Throws: If preparing or importing the legacy data fails.
    @Test func loadsLegacyMenuSettings() throws {
        
        try self.withManager { manager, directoryURL in
            let binding = KeyBinding(action: #selector(NSText.copy), shortcut: Shortcut("c", modifiers: [.command, .option]))
            try manager.importSetting(data: PropertyListEncoder().encode([binding]))
            
            let reloaded = KeyBindingManager(mainMenu: self.makeMenu(), settingDirectoryURL: directoryURL)
            #expect(!reloaded.textKeyBindings.isCustomized)
            #expect(try reloaded.userTextSettingsData() == nil)
            #expect(try reloaded.userSettingsData() != nil)
        }
    }
    
    
    /// Tests that an unreadable text settings file does not prevent loading menu settings.
    ///
    /// - Throws: If preparing or reading the settings fails.
    @Test func corruptTextSettingsKeepMenuSettings() throws {
        
        try self.withManager { manager, directoryURL in
            let binding = KeyBinding(action: #selector(NSText.copy), shortcut: Shortcut("c", modifiers: [.command, .option]))
            try manager.importSetting(data: PropertyListEncoder().encode([binding]))
            try Data("invalid".utf8).write(to: directoryURL.appending(path: "TextKeyBindings.plist"))
            
            let reloaded = KeyBindingManager(mainMenu: self.makeMenu(), settingDirectoryURL: directoryURL)
            #expect(!reloaded.textKeyBindings.isCustomized)
            #expect(try reloaded.userSettingsData() != nil)
        }
    }
    
    
    /// Tests removing the text settings file when its last customization is restored.
    ///
    /// - Throws: If saving or restoring settings fails.
    @Test func restoresTextDefaults() throws {
        
        try self.withManager { manager, directoryURL in
            var bindings = TextKeyBindingMap()
            try bindings.setShortcuts([], for: .pageDown)
            try manager.save(textKeyBindings: bindings)
            #expect(manager.isCustomized)
            try manager.save(textKeyBindings: TextKeyBindingMap())
            
            #expect(!manager.isCustomized)
            #expect(!FileManager.default.fileExists(atPath: directoryURL.appending(path: "TextKeyBindings.plist").path))
            #expect(try manager.userTextSettingsData() == nil)
        }
    }
    
    
    /// Tests restoring both kinds of shortcuts and the main menu together.
    ///
    /// - Throws: If importing, saving, or restoring settings fails.
    @Test func restoresAllDefaults() throws {
        
        try self.withManager { manager, directoryURL in
            let binding = KeyBinding(action: #selector(NSText.copy), shortcut: Shortcut("c", modifiers: [.command, .option]))
            try manager.importSetting(data: PropertyListEncoder().encode([binding]))
            var bindings = TextKeyBindingMap()
            try bindings.setShortcuts([], for: .pageDown)
            try manager.save(textKeyBindings: bindings)
            try manager.restoreDefaults()
            
            #expect(!manager.isCustomized)
            #expect(manager.menuTree.first?.flatValues.first?.shortcut == Shortcut("c", modifiers: .command))
            #expect(!FileManager.default.fileExists(atPath: directoryURL.path))
        }
    }
    
    
    /// Tests that an invalid import does not alter the current settings or their file.
    ///
    /// - Throws: If preparing or reading the original settings fails.
    @Test func failedImportKeepsSettings() throws {
        
        try self.withManager { manager, directoryURL in
            var bindings = TextKeyBindingMap()
            try bindings.setShortcuts([], for: .pageDown)
            try manager.save(textKeyBindings: bindings)
            let fileURL = directoryURL.appending(path: "TextKeyBindings.plist")
            let original = try Data(contentsOf: fileURL)
            let conflicting = [
                TextKeyBinding(action: TextKeyBindingCommand.moveToLeftEndOfLine.action, shortcuts: [Shortcut("q", modifiers: .control)]),
                TextKeyBinding(action: TextKeyBindingCommand.moveToRightEndOfLine.action, shortcuts: [Shortcut("q", modifiers: .control)]),
            ]
            let data = try PropertyListEncoder().encode(conflicting)
            
            #expect(throws: (any Error).self) { try manager.importTextSetting(data: data) }
            #expect(manager.textKeyBindings == bindings)
            #expect(try Data(contentsOf: fileURL) == original)
        }
    }
    
    
    /// Tests that a write failure does not publish unsaved text customizations.
    ///
    /// - Throws: If preparing the unavailable settings directory fails.
    @Test func failedWriteKeepsSettings() throws {
        
        try self.withManager { manager, directoryURL in
            try Data().write(to: directoryURL)
            var bindings = TextKeyBindingMap()
            try bindings.setShortcuts([], for: .pageDown)
            
            #expect(throws: (any Error).self) { try manager.save(textKeyBindings: bindings) }
            #expect(!manager.isCustomized)
        }
    }
    
    
    /// Tests an archive round trip with text-only settings and with both shortcut files.
    ///
    /// - Parameter includesMenu: Whether the archive also contains menu customizations.
    /// - Throws: If preparing, exporting, reading, or importing the archived payloads fails.
    @Test(arguments: [false, true])
    func settingsArchiveRoundTrip(includesMenu: Bool) throws {
        
        try self.withManager { manager, directoryURL in
            if includesMenu {
                let binding = KeyBinding(action: #selector(NSText.copy), shortcut: Shortcut("c", modifiers: [.command, .option]))
                try manager.importSetting(data: PropertyListEncoder().encode([binding]))
            }
            var bindings = TextKeyBindingMap()
            try bindings.setShortcuts([Shortcut(.home, modifiers: [])], for: .moveToLeftEndOfLine)
            try bindings.setShortcuts([], for: .pageDown)
            try manager.save(textKeyBindings: bindings)
            var document = try PortableSettingsDocument(including: [])
            document.keyBindings = try manager.userSettingsData()
            document.textKeyBindings = try manager.userTextSettingsData()
            #expect((document.keyBindings != nil) == includesMenu)
            #expect(document.textKeyBindings != nil)
            let archiveURL = directoryURL.deletingLastPathComponent().appending(path: "Settings.cotsettings")
            try document.fileWrapper().write(to: archiveURL, options: .atomic, originalContentsURL: nil)
            let imported = try PortableSettingsDocument(contentsOf: archiveURL)
            try manager.restoreDefaults()
            if let data = imported.keyBindings {
                try manager.importSetting(data: data)
            }
            try manager.importTextSetting(data: #require(imported.textKeyBindings))
            #expect(manager.textKeyBindings == bindings)
            #expect((try manager.userSettingsData() != nil) == includesMenu)
        }
    }
    
    
    /// Tests assigning navigation keys and Forward Delete without modifiers in the text editing scope.
    ///
    /// - Parameter key: The special key to assign.
    /// - Throws: If validation or saving fails.
    @Test(arguments: [NSEvent.SpecialKey.home, .end, .leftArrow, .rightArrow, .upArrow, .downArrow, .deleteForward])
    func assignsTextEditingKeys(key: NSEvent.SpecialKey) throws {
        
        try self.withManager { manager, _ in
            let shortcut = Shortcut(key, modifiers: [])
            try manager.save(shortcuts: [shortcut], for: .transpose)
            #expect(manager.textKeyBindings.action(for: shortcut) == .perform(.transpose))
        }
    }
    
    
    /// Tests rejecting ordinary typing, unsupported modifiers, and reserved editing keys.
    ///
    /// - Parameter shortcut: The unsupported shortcut.
    /// - Throws: If preparing the manager fails.
    @Test(arguments: [
        Shortcut("a", modifiers: []),
        Shortcut("a", modifiers: .shift),
        Shortcut("a", modifiers: .function),
        Shortcut(.leftArrow, modifiers: .function),
        Shortcut(.tab, modifiers: .control),
        Shortcut(.backTab, modifiers: .shift),
        Shortcut(.carriageReturn, modifiers: []),
        Shortcut(.carriageReturn, modifiers: .shift),
        Shortcut(.delete, modifiers: []),
    ] as [Shortcut])
    func rejectsUnsupportedTextShortcuts(shortcut: Shortcut) throws {
        
        try self.withManager { manager, _ in
            #expect(throws: Shortcut.CustomizationError.self) {
                try manager.save(shortcuts: [shortcut], for: .transpose)
            }
            #expect(!manager.isCustomized)
        }
    }
    
    
    /// Tests that menu assignments can take default text shortcuts but not customized ones.
    ///
    /// - Throws: If validating or updating the text command fails.
    @Test func checksTextShortcutForMenu() throws {
        
        try self.withManager { manager, _ in
            let controlK: Shortcut = Shortcut("k", modifiers: .control)
            try manager.checkCustomizationAvailability(for: controlK)
            let shortcut: Shortcut = Shortcut("j", modifiers: [.command, .option])
            try manager.save(shortcuts: [shortcut, controlK], for: .deleteToEndOfParagraph)
            try manager.checkCustomizationAvailability(for: controlK)
            #expect(throws: Shortcut.CustomizationError.self) {
                try manager.checkCustomizationAvailability(for: shortcut)
            }
        }
    }
    
    
    /// Tests that default text shortcuts give way to snippets and customized menu commands.
    ///
    /// - Throws: If importing or updating the settings fails.
    @Test func textDefaultsGiveWayToMenu() throws {
        
        let controlT: Shortcut = Shortcut("t", modifiers: .control)
        let controlJ: Shortcut = Shortcut("j", modifiers: .control)
        
        try self.withManager(adding: [self.makeSnippetItem(shortcut: controlT)]) { manager, _ in
            let binding = KeyBinding(action: #selector(NSText.copy), shortcut: Shortcut("a", modifiers: .control))
            try manager.importSetting(data: PropertyListEncoder().encode([binding]))
            
            #expect(manager.shortcuts(for: .transpose, in: manager.textKeyBindings).isEmpty)
            #expect(manager.shortcuts(for: .moveToBeginningOfParagraph, in: manager.textKeyBindings).isEmpty)
            #expect(manager.shortcuts(for: .deleteToBeginningOfLine, in: manager.textKeyBindings) == [Shortcut(.delete, modifiers: .command)])
            #expect(throws: Shortcut.CustomizationError.self) {
                try manager.checkCustomizationAvailability(for: controlT, command: .transpose)
            }
            
            // keep the default shortcut taken by the menu
            try manager.save(shortcuts: [controlJ] + manager.shortcuts(for: .transpose, in: manager.textKeyBindings), for: .transpose)
            #expect(manager.textKeyBindings.customizations[.transpose] == [controlJ, controlT])
            #expect(manager.shortcuts(for: .transpose, in: manager.textKeyBindings) == [controlJ])
            
            // show explicit assignments even if the menu overrides them
            let data = try PropertyListEncoder().encode([TextKeyBinding(action: TextKeyBindingCommand.yank.action, shortcuts: [controlT])])
            try manager.importTextSetting(data: data)
            #expect(manager.shortcuts(for: .yank, in: manager.textKeyBindings) == [controlT])
        }
    }
    
    
    /// Tests customizing and restoring a text command whose default shortcut is also the default of a menu command.
    ///
    /// - Throws: If validating or updating the text command fails.
    @Test func sharesDefaultShortcutWithMenu() throws {
        
        try self.withManager { manager, _ in
            let commandDelete = Shortcut(.delete, modifiers: .command)
            let controlU: Shortcut = Shortcut("u", modifiers: .control)
            try manager.checkCustomizationAvailability(for: controlU, command: .deleteToBeginningOfLine)
            try manager.save(shortcuts: [controlU, commandDelete], for: .deleteToBeginningOfLine)
            #expect(manager.shortcuts(for: .deleteToBeginningOfLine, in: manager.textKeyBindings) == [controlU, commandDelete])
            
            try manager.save(shortcuts: [controlU], for: .deleteToBeginningOfLine)
            try manager.checkCustomizationAvailability(for: commandDelete, command: .deleteToBeginningOfLine)
            #expect(throws: Shortcut.CustomizationError.self) {
                try manager.checkCustomizationAvailability(for: commandDelete, command: .deleteToBeginningOfParagraph)
            }
            
            try manager.save(shortcuts: nil, for: .deleteToBeginningOfLine)
            #expect(!manager.isCustomized)
            #expect(manager.shortcuts(for: .deleteToBeginningOfLine, in: manager.textKeyBindings) == [commandDelete])
        }
    }
    
    
    /// Tests restoring the default shortcut of a menu command that is also the default of a text command.
    ///
    /// - Throws: If validating or saving the menu settings fails.
    @Test func restoresMenuDefaultSharedWithText() throws {
        
        try self.withManager { manager, _ in
            let commandDelete = Shortcut(.delete, modifiers: .command)
            let tree = manager.menuTree
            let item = try #require(tree.flatMap(\.flatValues).first { $0.action == #selector(NSText.delete) })
            item.shortcut = Shortcut(.delete, modifiers: [.command, .option])
            try manager.save(tree: tree)
            
            try manager.checkCustomizationAvailability(for: commandDelete)
            item.shortcut = commandDelete
            try manager.save(tree: tree)
            #expect(!manager.isCustomized)
            #expect(manager.shortcuts(for: .deleteToBeginningOfLine, in: manager.textKeyBindings) == [commandDelete])
        }
    }
    
    
    /// Tests moving a default shortcut kept in a customized text command to another command and back.
    ///
    /// - Throws: If validating or updating the text commands fails.
    @Test func movesKeptDefaultShortcut() throws {
        
        try self.withManager { manager, _ in
            let controlT: Shortcut = Shortcut("t", modifiers: .control)
            let controlJ: Shortcut = Shortcut("j", modifiers: .control)
            try manager.save(shortcuts: [controlJ, controlT], for: .transpose)
            try manager.checkCustomizationAvailability(for: controlT, command: .yank)
            try manager.save(shortcuts: [controlT], for: .yank)
            #expect(manager.shortcuts(for: .transpose, in: manager.textKeyBindings) == [controlJ])
            #expect(manager.textKeyBindings.action(for: controlT) == .perform(.yank))
            
            try manager.save(shortcuts: nil, for: .yank)
            #expect(manager.shortcuts(for: .transpose, in: manager.textKeyBindings) == [controlJ, controlT])
            #expect(manager.textKeyBindings.action(for: controlT) == .perform(.transpose))
        }
    }
    
    
    /// Tests that a default shortcut given way to another text command comes back when released.
    ///
    /// - Throws: If updating the text commands fails.
    @Test func takesBackYieldedDefaultShortcut() throws {
        
        try self.withManager { manager, _ in
            let home = Shortcut(.home, modifiers: [])
            let f6 = Shortcut(.f6, modifiers: [])
            try manager.save(shortcuts: [home], for: .moveToLeftEndOfLine)
            #expect(manager.shortcuts(for: .scrollToBeginningOfDocument, in: manager.textKeyBindings).isEmpty)
            try manager.save(shortcuts: [f6] + manager.shortcuts(for: .scrollToBeginningOfDocument, in: manager.textKeyBindings), for: .scrollToBeginningOfDocument)
            try manager.save(shortcuts: nil, for: .moveToLeftEndOfLine)
            
            #expect(manager.shortcuts(for: .scrollToBeginningOfDocument, in: manager.textKeyBindings) == [f6, home])
            #expect(manager.textKeyBindings.action(for: home) == .perform(.scrollToBeginningOfDocument))
        }
    }
    
    
    /// Tests validating a shortcut to add to a text editing command.
    ///
    /// - Throws: If updating the text command fails.
    @Test func checksTextShortcutAvailability() throws {
        
        try self.withManager { manager, _ in
            let controlK: Shortcut = Shortcut("k", modifiers: .control)
            #expect(throws: Shortcut.CustomizationError.self) {
                try manager.checkCustomizationAvailability(for: controlK, command: .deleteToEndOfParagraph)
            }
            try manager.checkCustomizationAvailability(for: controlK, command: .transpose)
            
            let shortcut: Shortcut = Shortcut("j", modifiers: [.command, .option])
            try manager.save(shortcuts: [shortcut], for: .deleteToEndOfParagraph)
            #expect(throws: Shortcut.CustomizationError.self) {
                try manager.checkCustomizationAvailability(for: shortcut, command: .transpose)
            }
            #expect(throws: Shortcut.CustomizationError.self) {
                try manager.checkCustomizationAvailability(for: Shortcut("c", modifiers: .command), command: .transpose)
            }
        }
    }
    
    
    /// Tests reassigning inherited keys while rejecting keys customized for another command.
    ///
    /// - Throws: If creating or restoring assignments fails.
    @Test func reassignsInheritedTextShortcut() throws {
        
        try self.withManager { manager, _ in
            let home = Shortcut(.home, modifiers: [])
            try manager.save(shortcuts: [home], for: .moveToLeftEndOfLine)
            #expect(manager.textKeyBindings.shortcuts(for: .scrollToBeginningOfDocument).isEmpty)
            #expect(throws: Shortcut.CustomizationError.self) {
                try manager.save(shortcuts: [home], for: .moveToRightEndOfLine)
            }
            try manager.save(shortcuts: [Shortcut(.leftArrow, modifiers: .command)], for: .moveToRightEndOfLine)
            try manager.save(shortcuts: nil, for: .moveToLeftEndOfLine)
            #expect(manager.textKeyBindings.action(for: Shortcut(.leftArrow, modifiers: .command)) == .perform(.moveToRightEndOfLine))
            #expect(manager.textKeyBindings.action(for: home) == nil)
        }
    }
    
    
    /// Tests that restoring a command succeeds while its default shortcut now assigned to the menu stays there.
    ///
    /// - Throws: If preparing or restoring the customizations fails.
    @Test func restoreYieldsToMenuShortcut() throws {
        
        try self.withManager { manager, _ in
            try manager.save(shortcuts: [], for: .deleteToEndOfParagraph)
            let binding = KeyBinding(action: #selector(NSText.copy), shortcut: Shortcut("k", modifiers: .control))
            try manager.importSetting(data: PropertyListEncoder().encode([binding]))
            try manager.save(shortcuts: nil, for: .deleteToEndOfParagraph)
            
            #expect(!manager.textKeyBindings.isCustomized)
            #expect(manager.shortcuts(for: .deleteToEndOfParagraph, in: manager.textKeyBindings).isEmpty)
        }
    }
    
    
    /// Runs a synchronous persistence test with an isolated menu and settings directory.
    ///
    /// - Parameters:
    ///   - menuItems: The additional menu items, such as snippets, to append to the test menu.
    ///   - operation: The test using the manager and its settings directory.
    /// - Throws: If creating the temporary directory or running the test fails.
    private func withManager(adding menuItems: [NSMenuItem] = [], operation: (KeyBindingManager, URL) throws -> Void) throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let settingsURL = directoryURL.appending(path: "KeyBindings")
        let menu = self.makeMenu()
        for menuItem in menuItems {
            menu.addItem(menuItem)
        }
        let manager = KeyBindingManager(mainMenu: menu, settingDirectoryURL: settingsURL)
        
        try operation(manager, settingsURL)
    }
    
    
    /// Creates a menu whose Copy and Delete shortcuts can be customized independently of the application menu.
    ///
    /// - Returns: The test menu.
    private func makeMenu() -> NSMenu {
        
        let menu = NSMenu()
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy), keyEquivalent: "c")
        menu.addItem(withTitle: "Delete", action: #selector(NSText.delete), keyEquivalent: "\u{8}")  // ⌘⌫ as in Main.storyboard
        
        return menu
    }
    
    
    /// Creates a snippet menu item, whose shortcut is not managed by the key binding manager.
    ///
    /// - Parameter shortcut: The shortcut of the snippet.
    /// - Returns: The menu item.
    private func makeSnippetItem(shortcut: Shortcut) -> NSMenuItem {
        
        let menuItem = NSMenuItem(title: "Snippet", action: #selector((any SnippetInsertable).insertSnippet), keyEquivalent: "")
        menuItem.shortcut = shortcut
        
        return menuItem
    }
}
