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
import UniformTypeIdentifiers
import Yams
import Defaults
import StringUtils
import Syntax
import URLUtils

enum SyntaxName {
    
    static let none: SyntaxManager.SettingName = "None"
    static let xml: SyntaxManager.SettingName = "XML"
    static let markdown: SyntaxManager.SettingName = "Markdown"
}


@MainActor final class SyntaxManager: SettingFileManaging {
    
    typealias Setting = Syntax
    typealias PersistentSetting = Data
    
    typealias SettingName = String
    typealias MappingTable = [KeyPath<Syntax.FileMap, [String]?>: [String: [SettingName]]]
    
    
    // MARK: Public Properties
    
    static let shared = SyntaxManager()
    
    
    // MARK: Setting File Managing Properties
    
    static let directoryName: String = "Syntaxes"
    static let fileType: UTType = .yaml
    let reservedNames: [SettingName] = [SyntaxName.none, "General", "Code"]
    
    let bundledSettingNames: [SettingName]
    @Published var settingNames: [SettingName] = []
    @Atomic var cachedSettings: [SettingName: Setting] = [:]
    
    
    // MARK: Private Properties
    
    private let bundledMaps: [SettingName: Syntax.FileMap]
    @Atomic private var mappingTable: MappingTable = [\.extensions: [:],
                                                      \.filenames: [:],
                                                      \.interpreters: [:]]
    
    
    // MARK: Lifecycle
    
    private init() {
        
        // load bundled syntax list
        let url = Bundle.main.url(forResource: "SyntaxMap", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        self.bundledMaps = try! JSONDecoder().decode([SettingName: Syntax.FileMap].self, from: data)
        self.bundledSettingNames = self.bundledMaps.keys.sorted(using: .localizedStandard)
        
        // sanitize user setting file extensions
        try? self.sanitizeUserSettings()
        
        // cache user syntaxes
        self.settingNames = self.loadUserSettings()
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
        
        let setting = setting.sanitized
        
        try self.write(setting: setting, name: name)
        
        // invalidate current cache
        if let oldName {
            self.$cachedSettings.mutate { $0[oldName] = nil }
        }
        self.$cachedSettings.mutate { $0[name] = setting }
        
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
    
    
    // MARK: Setting File Managing
    
    /// Returns a built-in constant setting for the given name, if available.
    ///
    /// - Parameter name: The setting name.
    /// - Returns: A `Setting` if the name matches a constant setting; otherwise, `nil`.
    nonisolated static func constantSetting(name: String) -> Setting? {
        
        switch name {
            case SyntaxName.none:
                Setting.none
            default:
                nil
        }
    }
    
    
    /// Loads the persisted representation at the given URL.
    nonisolated static func persistence(at url: URL) throws -> PersistentSetting {
        
        try Data(contentsOf: url)
    }
    
    
    /// Encodes the provided setting into a persistable representation to store.
    nonisolated static func persistence(from setting: Setting) throws -> PersistentSetting {
        
        let encoder = YAMLEncoder()
        encoder.options.allowUnicode = true
        encoder.options.sortKeys = true
        
        let yamlString = try encoder.encode(setting)
        
        return Data(yamlString.utf8)
    }
    
    
    /// Loads a setting from a persisted representation.
    nonisolated static func loadSetting(from persistence: any Persistable, type: UTType) throws -> sending Setting {
        
        switch persistence {
            case let data as Data where type.conforms(to: Self.fileType):
                return try YAMLDecoder().decode(Setting.self, from: data)
                
            default:
                throw CocoaError(.fileReadUnsupportedScheme)
        }
    }
    
    
    /// Loads the list of settings in the user domain.
    nonisolated func loadUserSettings() -> [SettingName] {
        
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
        let userMaps = try! Syntax.FileMap.loadMaps(at: self.userSettingFileURLs, ignoresInvalidData: true)
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
    
    
    /// Standardizes the file extensions of user setting files.
    ///
    /// - Note: The file extension for syntax definition files changed from `.yaml` to `.yml` in CotEditor 4.2.0 (released in 2022-05).
    private func sanitizeUserSettings() throws {
        
        let urls = self.userSettingFileURLs.filter { $0.pathExtension == "yaml" }
        
        guard !urls.isEmpty else { return }
        
        for url in urls {
            let newURL = url.deletingPathExtension().appendingPathExtension(for: .yaml)
            
            try FileManager.default.moveItem(at: url, to: newURL)
        }
    }
}
