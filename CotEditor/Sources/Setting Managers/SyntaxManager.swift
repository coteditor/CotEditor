//
//  SyntaxManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-24.
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

import Foundation
import Combine
import Synchronization
import UniformTypeIdentifiers
import Defaults
import Syntax
import URLUtils

enum SyntaxName {
    
    static let none: SyntaxManager.SettingName = "None"
    static let xml: SyntaxManager.SettingName = "XML"
    static let markdown: SyntaxManager.SettingName = "Markdown"
}


@MainActor final class SyntaxManager: SettingFileManaging {
    
    typealias Setting = Syntax
    
    typealias SettingName = String
    typealias MappingTable = [KeyPath<Syntax.FileMap, [String]?>: [String: [SettingName]]]
    
    
    // MARK: Public Properties
    
    static let shared = SyntaxManager()
    
    
    // MARK: Setting File Managing Properties
    
    static let directoryName: String = "Syntaxes"
    static let userDirectoryName: String? = "Syntaxes (Upcoming)"
    static let constantSettings: [String: Setting] = [SyntaxName.none: .none]
    let reservedNames: [SettingName] = [SyntaxName.none, "General", "Code"] + TreeSitterSyntax.aliasedSyntaxes.map(\.rawValue)
    
    let bundledSettingNames: [SettingName]
    @Published var settingNames: [SettingName] = []
    
    var cachedSettings: [SettingName: Setting] {
        
        // protect with Mutex since SyntaxManager's cached settings can be accessed from a background thread
        get { self._cachedSettings.withLock(\.self) }
        set { self._cachedSettings.withLock { $0 = newValue } }
    }
    private let _cachedSettings: Mutex<[SettingName: Setting]> = .init([:])
    
    
    // MARK: Public Properties
    
    private(set) var migratedSyntaxCount = 0
    
    
    // MARK: Private Properties
    
    private let bundledMaps: [SettingName: Syntax.FileMap]
    private var mappingTable: MappingTable = [\.extensions: [:],
                                              \.filenames: [:],
                                              \.interpreters: [:]]
    
    
    // MARK: Lifecycle
    
    private init() {
        
        // load bundled syntax list
        let url = Bundle.main.url(forResource: "SyntaxMap", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        self.bundledMaps = try! JSONDecoder().decode([SettingName: Syntax.FileMap].self, from: data)
        self.bundledSettingNames = self.bundledMaps.keys.sorted(using: .localizedStandard)
        
        // cache user syntaxes
        self.settingNames = self.listAvailableSettings()
        self.updateMappingTable()
    }
    
    
    // MARK: Public Methods
    
    /// A map of items that are associated with more than one syntax setting.
    var mappingConflicts: MappingTable {
        
        self.mappingTable
            .mapValues { $0.filter { $0.value.count > 1 } }
            .filter { !$0.value.isEmpty }
    }
    
    
    /// Returns the syntax name that corresponds to the given document.
    ///
    /// - Parameters:
    ///   - filename: The filename of the document used to detect the corresponding syntax.
    ///   - content: The content of the document.
    /// - Returns: A setting name, or `nil` if no match is found.
    func settingName(documentName filename: String, content: String) -> SettingName? {
        
        self.settingName(documentName: filename) ?? self.settingName(documentContent: content)
    }
    
    
    /// Returns the syntax name that corresponds to the given filename.
    ///
    /// - Note: Despite being @MainActor, this method can be invoked from a background thread
    ///         in `DocumentController.checkOpeningSafetyOfDocument(at:type:)`.
    ///
    /// - Parameters:
    ///   - filename: The filename used to detect the corresponding syntax.
    /// - Returns: A setting name, or `nil` if no match is found.
    func settingName(documentName filename: String) -> SettingName? {
        
        let mappingTable = self.mappingTable
        
        if let settingName = mappingTable[\.filenames]?[filename]?.first {
            return settingName
        }
        
        if let pathExtension = filename.split(separator: ".").last,
           let extensionTable = mappingTable[\.extensions]
        {
            if let settingName = extensionTable[String(pathExtension)]?.first {
                return settingName
            }
            
            // check case-insensitively
            let lowerPathExtension = pathExtension.lowercased()
            if let settingName = extensionTable
                .first(where: { $0.key.lowercased() == lowerPathExtension })?
                .value.first
            {
                return settingName
            }
        }
        
        return nil
    }
    
    
    /// Returns the syntax name by scanning the shebang in the content.
    ///
    /// - Parameters:
    ///   - content: The content of the document.
    /// - Returns: A setting name, or `nil` if no match is found.
    func settingName(documentContent content: String) -> SettingName? {
        
        if let interpreter = Syntax.FileMap.scanInterpreterInShebang(content),
           let settingName = self.mappingTable[\.interpreters]?[interpreter]?.first
        {
            return settingName
        }
        
        // check XML declaration
        if content.hasPrefix("<?xml ") {
            return SyntaxName.xml
        }
        
        return nil
    }
    
    
    /// Returns syntax features that are user-customizable for the given setting.
    ///
    /// - Parameters:
    ///   - name: The setting name to check.
    /// - Returns: A set of customizable features.
    func customizableFeatures(name: SettingName) -> ParserFeatures {
        
        .all.subtracting(TreeSitterSyntax(name: name)?.features ?? [])
    }
    
    
    /// Saves the given setting to the user domain.
    ///
    /// - Parameters:
    ///   - setting: The setting to save.
    ///   - name: The name under which to save the setting.
    ///   - oldName: The previous setting name, if any.
    func save(setting: Setting, name: SettingName, oldName: SettingName?) throws {
        
        // move old file to new place to overwrite when syntax name is also changed
        if let oldName, name != oldName {
            try self.renameSetting(name: oldName, to: name)
        }
        
        try self.write(setting: setting, name: name)
        
        // invalidate current cache
        if let oldName {
            self.cachedSettings[oldName] = nil
        }
        self.cachedSettings[name] = setting
        
        // update internal cache
        let change: SettingChange = oldName.map { .updated(from: $0, to: name) } ?? .added(name)
        self.updateSettingList(change: change)
    }
    
    
    /// Adds the given setting to the list of recent syntaxes.
    ///
    /// - Parameter name: The setting name to record.
    func noteRecentSetting(name: String) {
        
        guard name != SyntaxName.none else { return }
        
        let maximum = max(0, UserDefaults.standard[.maximumRecentSyntaxCount])
        UserDefaults.standard[.recentSyntaxNames].appendUnique(name, maximum: maximum)
    }
    
    
    /// Migrates user syntax setting files from legacy format (YAML) to the current CotEditor Syntax format (CotEditor 7.0.0, 2026).
    func migrateUserSettings() throws {
        
        // before releasing the stable CotEditor 7.0.0:
        // - Remove `userDirectoryName` in SettingFileMapping and SyntaxManager.
        // - Prepend `private` to SettingFileMapping.userSettingDirectoryURL.
        
        let legacyURL = self.userSettingDirectoryURL.deletingLastPathComponent().appending(path: Self.directoryName)
        
        guard legacyURL.isReachable else { return }
        
        self.migratedSyntaxCount = try Syntax.migrateFormat(in: legacyURL, to: self.userSettingDirectoryURL, deletingOriginal: false)
    }
    
    
    // MARK: Setting File Managing
    
    /// Builds the list of available settings by considering both user and bundled settings.
    nonisolated func listAvailableSettings() -> [SettingName] {
        
        let userSettingNames = self.userSettingFileURLs
            .map(Self.settingName(from:))
        
        let settingNames = Set(self.bundledSettingNames + userSettingNames)
            .sorted(using: .localizedStandard)
        
        // reset user defaults if not found
        if !(settingNames + [SyntaxName.none]).contains(UserDefaults.standard[.syntax]) {
            UserDefaults.standard.restore(key: .syntax)
        }
        UserDefaults.standard[.recentSyntaxNames].removeAll { !settingNames.contains($0) }
        
        return settingNames
    }
    
    
    /// Notifies the manager that a setting was updated.
    ///
    /// - Parameters:
    ///   - change: The change to report.
    func didUpdateSetting(change: SettingChange) {
        
        self.updateMappingTable()
    }
    
    
    // MARK: Private Methods
    
    /// Updates the file mapping table used for syntax detection.
    private func updateMappingTable() {
        
        // defer bundled syntaxes so user syntaxes take precedence
        let sortedSettingNames = self.settingNames.filter { !self.bundledSettingNames.contains($0) } + self.bundledSettingNames
        
        // load mapping definitions from syntax files in the user domain
        let userMaps = try! Syntax.FileMap.load(at: self.userSettingFileURLs, ignoresInvalidData: true)
        let maps = self.bundledMaps.merging(userMaps) { _, new in new }
        
        // update the file mapping table
        self.mappingTable = self.mappingTable.keys.reduce(into: [:]) { tables, keyPath in
            tables[keyPath] = sortedSettingNames.reduce(into: [String: [SettingName]]()) { table, settingName in
                for item in maps[settingName]?[keyPath: keyPath] ?? [] {
                    table[item, default: []].append(settingName)
                }
            }
        }
    }
}
