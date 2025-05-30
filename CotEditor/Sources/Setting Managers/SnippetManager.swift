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

import Foundation
import AppKit.NSMenuItem
import Defaults
import Shortcut
import URLUtils

@MainActor @objc protocol SnippetInsertable: AnyObject {
    
    @objc func insertSnippet(_ sender: NSMenuItem)
}


@MainActor final class SnippetManager {
    
    // MARK: Public Properties
    
    static let shared = SnippetManager(defaults: .standard)
    
    private(set) var snippets: [Snippet]
    weak var menu: NSMenu?  { didSet { self.updateMenu() } }
    
    
    // MARK: Private Properties
    
    private let defaults: UserDefaults
    
    private var scope: String?
    
    
    // MARK: Lifecycle
    
    private init(defaults: UserDefaults) {
        
        self.defaults = defaults
        self.snippets = defaults[.snippets].compactMap(Snippet.init(dictionary:))
        
        Task.detached {
            self.migrateIfNeeded()
        }
        
        Task {
            let scopes = (DocumentController.shared as! DocumentController).$currentSyntaxName.values
            for await scope in scopes where self.scope != scope {
                self.scope = scope
                self.updateMenu()
            }
        }
    }
    
    
    // MARK: Public Methods
    
    /// Creates a new snippet.
    ///
    /// - Returns: the snippet created.
    func createUntitledSetting() -> Snippet {
        
        let name = String(localized: "Untitled", comment: "initial setting filename")
            .appendingUniqueNumber(in: self.snippets.map(\.name))
        
        return Snippet(name: name)
    }
    
    
    /// Returns a snippet corresponding to the given conditions.
    ///
    /// - Parameters:
    ///   - shortcut: The shortcut.
    ///   - scope: The syntax scope.
    /// - Returns: The corresponded snippet or nil.
    func snippet(for shortcut: Shortcut, scope: String) -> Snippet? {
        
        let snippets = self.snippets.filter { $0.shortcut == shortcut }
        
        return snippets.first { $0.scope == scope } ?? snippets.first { $0.scope == nil }
    }
    
    
    /// Saves the given snippets and updates UI.
    ///
    /// - Parameter snippets: The snippets to save.
    func save(_ snippets: [Snippet]) {
        
        self.snippets = snippets
        self.defaults[.snippets] = snippets.map(\.dictionary)
        
        self.updateMenu()
    }
    
    
    // MARK: Private Methods
    
    /// Updates the Snippet menu in the main menu.
    private func updateMenu() {
        
        guard let menu else { return }
        guard menu.items.count > 1 || !self.snippets.isEmpty else { return }
        
        let generalSnippets = self.snippets.filter { $0.scope == nil }
        let scopeSnippets = self.scope.map { scope in self.snippets.filter { $0.scope == scope } } ?? []
        
        let editItem = menu.items.last!
        let action = #selector((any SnippetInsertable).insertSnippet)
        
        menu.items.removeAll()
        
        // add general snippets
        if !generalSnippets.isEmpty {
            menu.items += generalSnippets.map { snippet in
                let item = NSMenuItem(title: snippet.name, action: action, keyEquivalent: "")
                item.shortcut = scopeSnippets.contains { $0.shortcut == snippet.shortcut } ? nil : snippet.shortcut
                item.representedObject = snippet
                return item
            }
            menu.items.append(.separator())
        }
        
        // add snippets for the current scope
        if !scopeSnippets.isEmpty, let scope {
            menu.items.append(.sectionHeader(title: scope))
            menu.items += scopeSnippets.map { snippet in
                let item = NSMenuItem(title: snippet.name, action: action, keyEquivalent: "")
                item.shortcut = snippet.shortcut
                item.representedObject = snippet
                return item
            }
            menu.items.append(.separator())
        }
        
        menu.items.append(editItem)
    }
}


// MARK: - Migration

private extension SnippetManager {
    
    private struct OldKeyBinding: Decodable {
        
        var action: String
        var shortcut: Shortcut
    }
    
    
    /// Migrates old format user snippet settings if exists (CotEditor 4.5.0, 2023-02).
    nonisolated func migrateIfNeeded() {
        
        assert(!Thread.isMainThread)
        
        let defaultKey = "insertCustomTextArray"
        
        guard let texts = UserDefaults.standard.stringArray(forKey: defaultKey) else { return }
        
        let shortcuts: [Int: Shortcut]
        let fileURL = URL.applicationSupportDirectory(component: "KeyBindings")
            .appendingPathComponent("SnippetKeyBindings", conformingTo: .propertyList)
        
        if let data = try? Data(contentsOf: fileURL),
           let keyBindings = try? PropertyListDecoder().decode([OldKeyBinding].self, from: data)
        {
            shortcuts = keyBindings.reduce(into: [:]) { (map, keyBinding) in
                guard
                    let match = keyBinding.action.wholeMatch(of: /insertCustomText_([0-9]{2}):/)?.1,
                    let index = Int(match)
                else { return }
                
                map[index] = keyBinding.shortcut
            }
            
        } else {
            shortcuts = [:]
        }
        
        let snippets = texts.enumerated()
            .filter { !$0.element.isEmpty }
            .compactMap {
                Snippet(name: String(localized: "Insert Text \($0.offset)", comment: "label for legacy snippet command (deprecated)"),
                        shortcut: shortcuts[$0.offset], format: $0.element)
            }
        
        // save new format
        Task { @MainActor in
            self.save(self.snippets + snippets)
        }
        
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
