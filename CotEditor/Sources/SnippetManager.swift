//
//  SnippetManager.swift
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
import AppKit

@objc protocol SnippetInsertable: AnyObject {
    
    @objc func insertSnippet(_ sender: NSMenuItem)
}


final class SnippetManager {
    
    // MARK: Public Properties
    
    static let shared = SnippetManager()
    
    private(set) var snippets: [Snippet]
    @MainActor weak var menu: NSMenu?  { didSet { self.updateMenu() } }
    
    
    // MARK: Lifecycle
    
    private init() {
        
        self.snippets = UserDefaults.standard[.snippets]
            .compactMap(Snippet.init(dictionary:))
        
        self.migrateIfNeeded()
    }
    
    
    // MARK: Public Methods
    
    /// Create a new snippet.
    ///
    /// - Returns: the snippet created.
    func createUntitledSetting() -> Snippet {
        
        let name = self.snippets.map(\.name).createAvailableName(for: "Untitled".localized)
        
        return Snippet(name: name)
    }
    
    
    /// Return a snippet corresponding to the given shortcut.
    ///
    /// - Parameters:
    ///   - shortcut: The shortcut.
    /// - Returns: The corresponded snippet or nil.
    func snippet(for shortcut: Shortcut) -> Snippet? {
        
        self.snippets.first { $0.shortcut == shortcut }
    }
    
    
    /// Save the given snippets and update UI.
    ///
    /// - Parameter snippets: The snippets to save.
    func save(_ snippets: [Snippet]) {
        
        self.snippets = snippets
        UserDefaults.standard[.snippets] = snippets.map(\.dictionary)
        
        Task {
            await self.updateMenu()
        }
    }
    
    
    // MARK: Private Methods
    
    /// Update the Snippet menu in the main menu.
    @MainActor private func updateMenu() {
        
        guard let menu else { return assertionFailure() }
        guard menu.items.count > 1 || !self.snippets.isEmpty else { return }
        
        let editItem = menu.items.last!
        let action = #selector(SnippetInsertable.insertSnippet)
        
        menu.items.removeAll()
        
        if !self.snippets.isEmpty {
            menu.items += self.snippets.map { snippet in
                let item = NSMenuItem(title: snippet.name, action: action, keyEquivalent: snippet.shortcut?.keyEquivalent ?? "")
                item.keyEquivalentModifierMask = snippet.shortcut?.modifierMask ?? []
                item.representedObject = snippet
                return item
            }
            menu.items.append(.separator())
        }
        
        menu.items.append(editItem)
    }
}



// MARK: - Migration

extension SnippetManager: SettingManaging {
    
    static var directoryName: String { "KeyBindings" }
}


private extension SnippetManager {
    
    private struct OldkeyBinding: Decodable {
        
        var action: String
        var shortcut: Shortcut
    }
    
    
    /// Migrate old format user snippet settings if exists (CotEditor 4.5.0, 2023-02).
    func migrateIfNeeded() {
        
        let defaultKey = "insertCustomTextArray"
        
        guard let texts = UserDefaults.standard.stringArray(forKey: defaultKey) else { return }
        
        let shortcuts: [Int: Shortcut]
        let fileURL = self.userSettingDirectoryURL.appendingPathComponent("SnippetKeyBindings", conformingTo: .propertyList)
        if
            let data = try? Data(contentsOf: fileURL),
            let keyBindings = try? PropertyListDecoder().decode([OldkeyBinding].self, from: data)
        {
            shortcuts = keyBindings.reduce(into: [:]) { (map, keyBinding) in
                guard
                    let range = keyBinding.action.range(of: "(?<=^insertCustomText_)[0-9]{2}(?=:$)", options: .regularExpression),
                    let index = Int(keyBinding.action[range])
                else { return }
                map[index] = keyBinding.shortcut
            }
            
        } else {
            shortcuts = [:]
        }
        
        let snippets = texts.enumerated()
            .filter { !$0.element.isEmpty }
            .compactMap { Snippet(name: String(localized: "Insert Text \($0.offset)"), shortcut: shortcuts[$0.offset], format: $0.element) }
        
        // save new format
        self.save(self.snippets + snippets)
        
        // remove old settings
        UserDefaults.standard.removeObject(forKey: defaultKey)
        if fileURL.isReachable {
            try? FileManager.default.removeItem(at: fileURL)
            let parent = fileURL.deletingLastPathComponent()
            if (try? FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: [], options: .skipsHiddenFiles).isEmpty) == true {
                try? FileManager.default.removeItem(at: parent)
            }
        }
    }
}
