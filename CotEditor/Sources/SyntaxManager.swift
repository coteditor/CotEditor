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
//  © 2014-2024 1024jp
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
import AppKit.NSMenuItem
import UniformTypeIdentifiers
import Yams
import SyntaxMap

@MainActor @objc protocol SyntaxChanging: AnyObject {
    
    func changeSyntax(_ sender: NSMenuItem)
    func recolorAll(_ sender: Any?)
}


enum SyntaxName {
    
    static let none: SyntaxManager.SettingName = "None"
    static let xml: SyntaxManager.SettingName = "XML"
    static let markdown: SyntaxManager.SettingName = "Markdown"
}



// MARK: -

final class SyntaxManager: SettingFileManaging {
    
    typealias Setting = Syntax
    
    typealias SettingName = String
    typealias MappingTable = [KeyPath<SyntaxMap, [String]>: [String: [SettingName]]]
    
    
    // MARK: Public Properties
    
    static let shared = SyntaxManager()
    
    
    // MARK: Setting File Managing Properties
    
    let didUpdateSetting: PassthroughSubject<SettingChange, Never> = .init()
    
    static let directoryName: String = "Syntaxes"
    let fileType: UTType = .yaml
    let reservedNames: [SettingName] = [SyntaxName.none, "General", "Code"]
    
    @Published var settingNames: [SettingName] = []
    let bundledSettingNames: [SettingName]
    @Atomic var cachedSettings: [SettingName: Setting] = [:]
    
    
    // MARK: Private Properties
    
    private let bundledMaps: [SettingName: SyntaxMap]
    @Atomic private var mappingTable: MappingTable = [\.extensions: [:],
                                                      \.filenames: [:],
                                                      \.interpreters: [:]]
    
    private var settingUpdateObserver: AnyCancellable?
    
    
    
    // MARK: Lifecycle
    
    private init() {
        
        // load bundled syntax list
        let url = Bundle.main.url(forResource: "SyntaxMap", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        self.bundledMaps = try! JSONDecoder().decode([SettingName: SyntaxMap].self, from: data)
        self.bundledSettingNames = self.bundledMaps.keys.sorted(options: [.localized, .caseInsensitive])
        
        // sanitize user setting file extensions
        try? self.sanitizeUserSettings()
        
        // cache user syntaxes
        self.loadUserSettings()
        
        // update also .mappingTable
        self.settingUpdateObserver = self.didUpdateSetting
            .sink { [weak self] _ in self?.loadUserSettings() }
    }
    
    
    
    // MARK: Public Methods
    
    /// Returns the syntax name corresponding to the given document.
    ///
    /// - Parameters:
    ///   - fileName: The  file name of the document to detect the corresponding syntax name.
    ///   - content: The content of the document.
    /// - Returns: A setting name.
    func settingName(documentName fileName: String, content: String) -> SettingName? {
        
        self.settingName(documentName: fileName) ?? self.settingName(documentContent: content)
    }
    
    
    /// Returns the bundled version of the setting, or `nil` if not exists.
    ///
    /// - Parameter name: The setting name.
    /// - Returns: A setting, or `nil` if not exists.
    func bundledSetting(name: SettingName) -> Setting? {
        
        guard let url = self.urlForBundledSetting(name: name) else { return nil }
        
        return try? self.loadSetting(at: url)
    }
    
    
    /// Saves the given setting file to the user domain.
    ///
    /// - Parameters:
    ///   - setting: The setting to save.
    ///   - name: The setting name to save.
    ///   - oldName: The old setting name if any exists.
    func save(setting: Setting, name: SettingName, oldName: SettingName?) throws {
        
        let fileURL = self.preparedURLForUserSetting(name: name)
        
        // move old file to new place to overwrite when syntax name is also changed
        if let oldName, name != oldName {
            try self.renameSetting(name: oldName, to: name)
        }
        
        let setting = setting.sanitized
        
        // just remove the current custom setting file in the user domain if new syntax is just the same as bundled one
        // so that application uses bundled one
        if setting == self.bundledSetting(name: name) {
            if fileURL.isReachable {
                try FileManager.default.removeItem(at: fileURL)
            }
        } else {
            // save file to user domain
            let encoder = YAMLEncoder()
            encoder.options.allowUnicode = true
            encoder.options.sortKeys = true
            let yamlString = try encoder.encode(setting)
            let data = Data(yamlString.utf8)
            
            try FileManager.default.createIntermediateDirectories(to: fileURL)
            try data.write(to: fileURL)
        }
        
        // invalidate current cache
        self.$cachedSettings.mutate { $0[name] = nil }
        if let oldName {
            self.$cachedSettings.mutate { $0[oldName] = nil }
        }
        
        // update internal cache
        let change: SettingChange = oldName.flatMap { .updated(from: $0, to: name) } ?? .added(name)
        self.updateSettingList(change: change)
    }
    
    
    /// The map for the conflicted settings.
    var mappingConflicts: MappingTable {
        
        self.mappingTable
            .mapValues { $0.filter { $0.value.count > 1 } }
            .filter { !$0.value.isEmpty }
    }
    
    
    
    // MARK: Setting File Managing
    
    /// Returns the setting instance corresponding to the given setting name.
    func setting(name: SettingName) -> Setting? {
        
        if name == SyntaxName.none {
            return Syntax.none
        }
        
        guard let setting: Setting = {
            if let setting = self.cachedSettings[name] {
                return setting
            }
            
            guard let url = self.urlForUsedSetting(name: name) else { return nil }
            
            let setting = try? self.loadSetting(at: url)
            self.$cachedSettings.mutate { $0[name] = setting }
            
            return setting
        }() else { return nil }
        
        // add to recent syntaxes list
        let maximumRecentSyntaxCount = max(0, UserDefaults.standard[.maximumRecentSyntaxCount])
        var recentSyntaxNames = UserDefaults.standard[.recentSyntaxNames]
        recentSyntaxNames.removeFirst(name)
        recentSyntaxNames.insert(name, at: 0)
        UserDefaults.standard[.recentSyntaxNames] = Array(recentSyntaxNames.prefix(maximumRecentSyntaxCount))
        
        return setting
    }
    
    
    /// Loads setting from the file at the given URL.
    func loadSetting(at fileURL: URL) throws -> Setting {
        
        let decoder = YAMLDecoder()
        let data = try Data(contentsOf: fileURL)
        
        return try decoder.decode(Setting.self, from: data)
    }
    
    
    /// Loads settings in the user domain.
    func loadUserSettings() {
        
        // load mapping definitions from syntax files in user domain
        let userMaps = try! SyntaxMap.loadMaps(at: self.userSettingFileURLs, ignoresInvalidData: true)
        let maps = self.bundledMaps.merging(userMaps) { (_, new) in new }
        
        // sort syntaxes alphabetically
        self.settingNames = maps.keys.sorted(options: [.localized, .caseInsensitive])
        // remove syntaxes not exist
        UserDefaults.standard[.recentSyntaxNames].removeAll { !self.settingNames.contains($0) }
        
        // update file mapping tables
        let settingNames = self.settingNames.filter { !self.bundledSettingNames.contains($0) } + self.bundledSettingNames  // postpone bundled syntaxes
        self.mappingTable = self.mappingTable.keys.reduce(into: [:]) { (tables, keyPath) in
            tables[keyPath] = settingNames.reduce(into: [String: [SettingName]]()) { (table, settingName) in
                for item in maps[settingName]?[keyPath: keyPath] ?? [] {
                    table[item, default: []].append(settingName)
                }
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Standardizes the file extensions of user setting files.
    ///
    /// - Note: The file extension for syntax definition files are changed from `.yaml` to `.yml` in CotEditor 4.2.0 released in 2022-05.
    private func sanitizeUserSettings() throws {
        
        let urls = self.userSettingFileURLs.filter { $0.pathExtension == "yaml" }
        
        guard !urls.isEmpty else { return }
        
        for url in urls {
            let newURL = url.deletingPathExtension().appendingPathExtension(for: .yaml)
            
            try FileManager.default.moveItem(at: url, to: newURL)
        }
    }
    
    
    /// Returns the syntax name corresponding to the given filename.
    ///
    /// - Parameters:
    ///   - fileName: The  file name of the document to detect the corresponding syntax name.
    /// - Returns: A setting name, or `nil` if not exists.
    private func settingName(documentName fileName: String) -> SettingName? {
        
        let mappingTable = self.mappingTable
        
        if let settingName = mappingTable[\.filenames]?[fileName]?.first {
            return settingName
        }
        
        if let pathExtension = fileName.split(separator: ".").last,
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
    
    
    /// Returns the syntax name scanning the shebang in content.
    ///
    /// - Parameters:
    ///   - content: The content of the document.
    /// - Returns: A setting name, or `nil` if not exists.
    private func settingName(documentContent content: String) -> SettingName? {
        
        if let interpreter = content.scanInterpreterInShebang(),
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
}



private extension StringProtocol {
    
    /// Extracts interpreter from the shebang line.
    func scanInterpreterInShebang() -> String? {
        
        guard self.hasPrefix("#!") else { return nil }
        
        // get first line
        let firstLineRange = self.lineContentsRange(at: self.startIndex)
        let shebang = self[firstLineRange]
            .dropFirst("#!".count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // find interpreter
        let components = shebang.split(separator: " ", maxSplits: 2)
        
        guard let interpreter = components.first?.split(separator: "/").last else { return nil }
        
        // use first arg if the path targets env
        if interpreter == "env", let interpreter = components[safe: 1] {
            return String(interpreter)
        }
        
        return String(interpreter)
    }
}
