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

import Combine
import Foundation
import AppKit.NSMenuItem
import UniformTypeIdentifiers
import Yams

@objc protocol SyntaxHolder: AnyObject {
    
    func changeSyntax(_ sender: NSMenuItem)
    func recolorAll(_ sender: Any?)
}


enum BundledSyntaxName {
    
    static let none: SyntaxManager.SettingName = String(localized: "None", comment: "syntax name")
    static let xml: SyntaxManager.SettingName = "XML"
    static let markdown: SyntaxManager.SettingName = "Markdown"
}



// MARK: -

final class SyntaxManager: SettingFileManaging {
    
    typealias Setting = Syntax
    
    typealias SettingName = String
    typealias SyntaxDictionary = [String: Any]
    
    
    // MARK: Public Properties
    
    static let shared = SyntaxManager()
    
    
    // MARK: Setting File Managing Properties
    
    let didUpdateSetting: PassthroughSubject<SettingChange, Never> = .init()
    
    static let directoryName: String = "Syntaxes"
    let fileType: UTType = .yaml
    
    @Published var settingNames: [SettingName] = []
    let bundledSettingNames: [SettingName]
    @Atomic var cachedSettings: [SettingName: Setting] = [:]
    
    
    // MARK: Private Properties
    
    private let bundledMap: [SettingName: [String: [String]]]
    @Atomic private var mappingTables: [SyntaxKey: [String: [SettingName]]] = [.extensions: [:],
                                                                               .filenames: [:],
                                                                               .interpreters: [:]]
    
    private var settingUpdateObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private init() {
        
        // load bundled syntax list
        let url = Bundle.main.url(forResource: "SyntaxMap", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let map = try! JSONDecoder().decode([SettingName: [String: [String]]].self, from: data)
        self.bundledMap = map
        self.bundledSettingNames = map.keys.sorted(options: [.localized, .caseInsensitive])
        
        // sanitize user setting file extensions
        try? self.sanitizeUserSettings()
        
        // cache user syntaxes
        self.loadUserSettings()
        
        // update also .mappingTables
        self.settingUpdateObserver = self.didUpdateSetting
            .sink { [weak self] _ in self?.loadUserSettings() }
    }
    
    
    
    // MARK: Public Methods
    
    /// return syntax name corresponding to given variables
    func settingName(documentFileName fileName: String, content: String) -> SettingName {
        
        self.settingName(documentFileName: fileName)
            ?? self.settingName(documentContent: content)
            ?? BundledSyntaxName.none
    }
    
    
    /// return syntax name corresponding to file name
    func settingName(documentFileName fileName: String) -> SettingName? {
        
        let mappingTables = self.mappingTables
        
        if let settingName = mappingTables[.filenames]?[fileName]?.first {
            return settingName
        }
        
        if let pathExtension = fileName.split(separator: ".").last,
           let extensionTable = mappingTables[.extensions]
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
    
    
    /// return syntax name scanning shebang in document content
    func settingName(documentContent content: String) -> SettingName? {
        
        if let interpreter = content.scanInterpreterInShebang(),
           let settingName = self.mappingTables[.interpreters]?[interpreter]?.first {
            return settingName
        }
        
        // check XML declaration
        if content.hasPrefix("<?xml ") {
            return BundledSyntaxName.xml
        }
        
        return nil
    }
    
    
    /// syntax dictionary list corresponding to syntax name
    func settingDictionary(name: SettingName) -> SyntaxDictionary? {
        
        if name == BundledSyntaxName.none {
            return self.blankSettingDictionary
        }
        
        guard
            let url = self.urlForUsedSetting(name: name),
            let dictionary = try? self.loadSettingDictionary(at: url)
        else { return nil }
        
        return dictionary.cocoaBindable
    }
    
    
    /// return bundled version syntax dictionary or nil if not exists
    func bundledSettingDictionary(name: SettingName) -> SyntaxDictionary? {
        
        guard
            let url = self.urlForBundledSetting(name: name),
            let dictionary = try? self.loadSettingDictionary(at: url)
        else { return nil }
        
        return dictionary.cocoaBindable
    }
    
    
    /// save setting file
    func save(settingDictionary: SyntaxDictionary, name: SettingName, oldName: SettingName?) throws {
        
        // sort items
        let beginStringSort = NSSortDescriptor(key: SyntaxDefinitionKey.beginString.rawValue, ascending: true,
                                               selector: #selector(NSString.caseInsensitiveCompare))
        for key in SyntaxType.allCases {
            (settingDictionary[key.rawValue] as? NSMutableArray)?.sort(using: [beginStringSort])
        }
        
        let keyStringSort = NSSortDescriptor(key: SyntaxDefinitionKey.keyString.rawValue, ascending: true,
                                             selector: #selector(NSString.caseInsensitiveCompare))
        for key in [SyntaxKey.outlineMenu, .completions] {
            (settingDictionary[key.rawValue] as? NSMutableArray)?.sort(using: [keyStringSort])
        }
        
        let fileURL = self.preparedURLForUserSetting(name: name)
        
        // move old file to new place to overwrite when syntax name is also changed
        if let oldName, name != oldName {
            try self.renameSetting(name: oldName, to: name)
        }
        
        // just remove the current custom setting file in the user domain if new syntax is just the same as bundled one
        // so that application uses bundled one
        if self.isEqualToBundledSetting(settingDictionary, name: name) {
            if fileURL.isReachable {
                try FileManager.default.removeItem(at: fileURL)
            }
        } else {
            // save file to user domain
            let yamlString = try Yams.dump(object: settingDictionary.yamlEncodable, allowUnicode: true)
            let data = Data(yamlString.utf8)
            
            try self.prepareUserSettingDirectory()
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
    
    
    /// conflicted maps
    var mappingConflicts: [SyntaxKey: [String: [SettingName]]] {
        
        self.mappingTables
            .mapValues { $0.filter { $0.value.count > 1 } }
            .filter { !$0.value.isEmpty }
    }
    
    
    /// empty syntax dictionary
    var blankSettingDictionary: SyntaxDictionary {
        
        [
            SyntaxKey.metadata.rawValue: NSMutableDictionary(),
            SyntaxKey.extensions.rawValue: NSMutableArray(),
            SyntaxKey.filenames.rawValue: NSMutableArray(),
            SyntaxKey.interpreters.rawValue: NSMutableArray(),
            SyntaxType.keywords.rawValue: NSMutableArray(),
            SyntaxType.commands.rawValue: NSMutableArray(),
            SyntaxType.types.rawValue: NSMutableArray(),
            SyntaxType.attributes.rawValue: NSMutableArray(),
            SyntaxType.variables.rawValue: NSMutableArray(),
            SyntaxType.values.rawValue: NSMutableArray(),
            SyntaxType.numbers.rawValue: NSMutableArray(),
            SyntaxType.strings.rawValue: NSMutableArray(),
            SyntaxType.characters.rawValue: NSMutableArray(),
            SyntaxType.comments.rawValue: NSMutableArray(),
            SyntaxKey.outlineMenu.rawValue: NSMutableArray(),
            SyntaxKey.completions.rawValue: NSMutableArray(),
            SyntaxKey.commentDelimiters.rawValue: NSMutableDictionary(),
        ]
    }
    
    
    
    // MARK: Setting File Managing
    
    /// return setting instance corresponding to the given setting name
    func setting(name: SettingName) -> Setting? {
        
        if name == BundledSyntaxName.none {
            return Syntax()
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
    
    
    /// Load setting from the file at the given URL.
    func loadSetting(at fileURL: URL) throws -> Setting {
        
        let dictionary = try self.loadSettingDictionary(at: fileURL)
        let name = self.settingName(from: fileURL)
        
        return Syntax(dictionary: dictionary, name: name)
    }
    
    
    /// Load settings in the user domain.
    func loadUserSettings() {
        
        // load mapping definitions from syntax files in user domain
        let mappingKeys = SyntaxKey.mappingKeys.map(\.rawValue)
        let userMap: [SettingName: [String: [String]]] = self.userSettingFileURLs.reduce(into: [:]) { (dict, url) in
            guard let syntax = try? self.loadSettingDictionary(at: url) else { return }
            let settingName = self.settingName(from: url)
            
            // create file mapping data
            dict[settingName] = syntax.filter { mappingKeys.contains($0.key) }
                .mapValues { $0 as? [[String: String]] ?? [] }
                .mapValues { $0.compactMap { $0[SyntaxDefinitionKey.keyString] } }
        }
        let map = self.bundledMap.merging(userMap) { (_, new) in new }
        
        // sort syntaxes alphabetically
        self.settingNames = map.keys.sorted(options: [.localized, .caseInsensitive])
        // remove syntaxes not exist
        UserDefaults.standard[.recentSyntaxNames].removeAll { !self.settingNames.contains($0) }
        
        // update file mapping tables
        let settingNames = self.settingNames.filter { !self.bundledSettingNames.contains($0) } + self.bundledSettingNames  // postpone bundled syntaxes
        self.mappingTables = SyntaxKey.mappingKeys.reduce(into: [:]) { (tables, key) in
            tables[key] = settingNames.reduce(into: [String: [SettingName]]()) { (table, settingName) in
                guard let items = map[settingName]?[key.rawValue] else { return }
                
                for item in items {
                    table[item, default: []].append(settingName)
                }
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Standardize the file extensions of user setting files.
    ///
    /// - Note: The file extension for syntax definition files are changed from `.yaml` to `.yml` in CotEditor 4.2.0 released in 2022.
    private func sanitizeUserSettings() throws {
        
        let urls = self.userSettingFileURLs.filter { $0.pathExtension == "yaml" }
        
        guard !urls.isEmpty else { return }
        
        for url in urls {
            let newURL = url.deletingPathExtension().appendingPathExtension(for: .yaml)
            
            try FileManager.default.moveItem(at: url, to: newURL)
        }
    }
    
    
    /// Load SyntaxDictionary at file URL.
    ///
    /// - Parameter fileURL: URL to a setting file.
    /// - Throws: `CocoaError`
    private func loadSettingDictionary(at fileURL: URL) throws -> SyntaxDictionary {
        
        let string = try String(contentsOf: fileURL)
        let yaml = try Yams.load(yaml: string)
        
        guard let syntaxDictionary = yaml as? SyntaxDictionary else {
            throw CocoaError.error(.fileReadCorruptFile, url: fileURL)
        }
        
        return syntaxDictionary
    }
    
    
    /// return whether contents of given highlight definition is the same as bundled one
    private func isEqualToBundledSetting(_ syntax: SyntaxDictionary, name: SettingName) -> Bool {
        
        guard let bundledSyntax = self.bundledSettingDictionary(name: name) else { return false }
        
        return syntax == bundledSyntax
    }
}



private extension StringProtocol {
    
    /// Extract interpreter from the shebang line.
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



// MARK: - Cocoa Bindings Support

private extension SyntaxManager.SyntaxDictionary {
    
    /// Convert to NSObject-based collection for Cocoa-Bindings recursively.
    var cocoaBindable: Self {
        
        self.mapValues(Self.convertToCocoaBindable)
    }
    
    
    /// Convert to YAML serialization compatible collection recursively.
    var yamlEncodable: Self {
        
        self.mapValues(Self.convertToYAMLEncodable)
    }
    
    
    // MARK: Private Methods
    
    private static func convertToYAMLEncodable(_ item: Any) -> Any {
        
        switch item {
            case let dictionary as [String: Any]:
                return dictionary.mapValues(Self.convertToYAMLEncodable)
            case let array as [Any]:
                return array.map(Self.convertToYAMLEncodable)
            case let bool as Bool:
                return bool
            case let string as String:
                return string
            default:
                assertionFailure("\(type(of: item))")
                return item
        }
    }
    
    
    private static func convertToCocoaBindable(_ item: Any) -> Any {
        
        switch item {
            case let dictionary as [String: Any]:
                NSMutableDictionary(dictionary: dictionary.mapValues(Self.convertToCocoaBindable))
            case let array as [Any]:
                NSMutableArray(array: array.map(Self.convertToCocoaBindable))
            case let date as Date:
                date.formatted(.iso8601.year().month().day())
            default:
                item
        }
    }
}



// MARK: - Equitability Support

private extension SyntaxManager.SyntaxDictionary {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        
        areEqual(lhs, rhs)
    }
    
    
    // MARK: Private Methods
    
    /// Check the equitability recursively.
    ///
    /// This comparison is designed and valid only for SyntaxDictionary.
    private static func areEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        
        switch (lhs, rhs) {
            case let (lhs, rhs) as (Dictionary, Dictionary):
                guard lhs.count == rhs.count else { return false }
                
                return lhs.allSatisfy { (key, lhsValue) -> Bool in
                    guard let rhsValue = rhs[key] else { return false }
                    
                    return areEqual(lhsValue, rhsValue)
                }
                
            case let (lhs, rhs) as ([Any], [Any]):
                guard lhs.count == rhs.count else { return false }
                
                // check elements equitability by ignoring the order
                var rhs = rhs
                for lhsValue in lhs {
                    guard let rhsIndex = rhs.firstIndex(where: { areEqual(lhsValue, $0) }) else { return false }
                    rhs.remove(at: rhsIndex)
                }
                return true
                
            default:
                return type(of: lhs) == type(of: rhs) && String(describing: lhs) == String(describing: rhs)
        }
    }
}
