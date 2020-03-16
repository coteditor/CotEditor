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
//  © 2014-2020 1024jp
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
import YAML

@objc protocol SyntaxHolder: AnyObject {
    
    func changeSyntaxStyle(_ sender: AnyObject?)
    func recolorAll(_ sender: Any?)
}


enum BundledStyleName {
    
    static let none: SyntaxManager.SettingName = "None".localized(comment: "syntax style name")
    static let xml: SyntaxManager.SettingName = "XML"
    static let markdown: SyntaxManager.SettingName = "Markdown"
}



// MARK: -

final class SyntaxManager: SettingFileManaging {
    
    typealias Setting = SyntaxStyle
    
    typealias SettingName = String
    typealias StyleDictionary = [String: Any]
    
    
    // MARK: Public Properties
    
    static let shared = SyntaxManager()
    
    
    // MARK: Setting File Managing Properties
    
    static let directoryName: String = "Syntaxes"
    let filePathExtensions: [String] = ["yaml", "yml"]
    let settingFileType: SettingFileType = .syntaxStyle
    
    private(set) var settingNames: [SettingName] = []
    let bundledSettingNames: [SettingName]
    
    
    // MARK: Private Properties
    
    private let bundledMap: [SettingName: [String: [String]]]
    private var mappingTables = Atomic<[SyntaxKey: [String: [SettingName]]]>([.extensions: [:],
                                                                              .filenames: [:],
                                                                              .interpreters: [:]])
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private init() {
        
        // load bundled style list
        let url = Bundle.main.url(forResource: "SyntaxMap", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let map = try! JSONDecoder().decode([SettingName: [String: [String]]].self, from: data)
        self.bundledMap = map
        self.bundledSettingNames = map.keys.sorted(options: [.localized, .caseInsensitive])
        
        // cache user styles
        self.checkUserSettings()
    }
    
    
    
    // MARK: Public Methods
    
    /// return style name corresponding to given variables
    func settingName(documentFileName fileName: String, content: String) -> SettingName {
        
        return self.settingName(documentFileName: fileName)
            ?? self.settingName(documentContent: content)
            ?? BundledStyleName.none
    }
    
    
    /// return style name corresponding to file name
    func settingName(documentFileName fileName: String) -> SettingName? {
        
        let mappingTables = self.mappingTables.value
        
        if let settingName = mappingTables[.filenames]?[fileName]?.first {
            return settingName
        }
        
        if let pathExtension = fileName.components(separatedBy: ".").last,
            let settingName = mappingTables[.extensions]?[pathExtension]?.first {
            return settingName
        }
        
        return nil
    }
    
    
    /// return style name scanning shebang in document content
    func settingName(documentContent content: String) -> SettingName? {
        
        if let interpreter = content.scanInterpreterInShebang(),
            let settingName = self.mappingTables.value[.interpreters]?[interpreter]?.first {
            return settingName
        }
        
        // check XML declaration
        if content.hasPrefix("<?xml ") {
            return BundledStyleName.xml
        }
        
        return nil
    }
    
    
    /// style dictionary list corresponding to style name
    func settingDictionary(name: SettingName) -> StyleDictionary? {
        
        if name == BundledStyleName.none {
            return self.blankSettingDictionary
        }
        
        guard let url = self.urlForUsedSetting(name: name) else { return nil }
        
        return try? self.loadSettingDictionary(at: url)
    }
    
    
    /// return bundled version style dictionary or nil if not exists
    func bundledSettingDictionary(name: SettingName) -> StyleDictionary? {
        
        guard let url = self.urlForBundledSetting(name: name) else { return nil }
        
        return try? self.loadSettingDictionary(at: url)
    }
    
    
    /// save setting file
    func save(settingDictionary: StyleDictionary, name: SettingName, oldName: SettingName?) throws {
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
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
        
        // save
        let saveURL = self.preparedURLForUserSetting(name: name)
        
        // move old file to new place to overwrite when style name is also changed
        if let oldName = oldName, name != oldName {
            try self.renameSetting(name: oldName, to: name)
        }
        
        // just remove the current custom setting file in the user domain if new style is just the same as bundled one
        // so that application uses bundled one
        if self.isEqualToBundledSetting(settingDictionary, name: name) {
            if saveURL.isReachable {
                try FileManager.default.removeItem(at: saveURL)
            }
        } else {
            // save file to user domain
            let yamlData = try YAMLSerialization.yamlData(with: settingDictionary, options: kYAMLWriteOptionSingleDocument)
            try yamlData.write(to: saveURL, options: .atomic)
        }
        
        // invalidate current cache
        self.cachedSettings[name] = nil
        if let oldName = oldName {
            self.cachedSettings[oldName] = nil
        }
        
        // update internal cache
        self.updateCache { [weak self] in
            if let oldName = oldName {
                self?.notifySettingUpdate(oldName: oldName, newName: name)
            }
        }
    }
    
    
    /// conflicted maps
    var mappingConflicts: [SyntaxKey: [String: [SettingName]]] {
        
        return self.mappingTables.value.mapValues { $0.filter { $0.value.count > 1 } }
    }
    
    
    /// empty style dictionary
    var blankSettingDictionary: StyleDictionary {
        
        return [
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
        
        if name == BundledStyleName.none {
            return SyntaxStyle()
        }
        
        guard let setting: Setting = {
            if let setting = self.cachedSettings[name] {
                return setting
            }
            
            guard let url = self.urlForUsedSetting(name: name) else { return nil }
            
            let setting = try? self.loadSetting(at: url)
            self.cachedSettings[name] = setting
            
            return setting
            }() else { return nil }
        
        // add to recent styles list
        let maximumRecentStyleCount = max(0, UserDefaults.standard[.maximumRecentStyleCount])
        var recentStyleNames = UserDefaults.standard[.recentStyleNames] ?? []
        recentStyleNames.removeFirst(name)
        recentStyleNames.insert(name, at: 0)
        UserDefaults.standard[.recentStyleNames] = Array(recentStyleNames.prefix(maximumRecentStyleCount))
        
        return setting
    }
    
    
    var cachedSettings: [SettingName: Setting] {
        
        get { self._cachedSettings.value }
        set { self._cachedSettings.mutate { $0 = newValue } }
    }
    private let _cachedSettings = Atomic<[SettingName: Setting]>([:])
    
    
    /// load setting from the file at given URL
    func loadSetting(at fileURL: URL) throws -> Setting {
        
        let dictionary = try self.loadSettingDictionary(at: fileURL)
        let name = self.settingName(from: fileURL)
        
        return SyntaxStyle(dictionary: dictionary, name: name)
    }
    
    
    /// load settings in the user domain
    func checkUserSettings() {
        
        // load mapping definitions from style files in user domain
        let mappingKeys = SyntaxKey.mappingKeys.map(\.rawValue)
        let userMap: [SettingName: [String: [String]]] = self.userSettingFileURLs.reduce(into: [:]) { (dict, url) in
            guard let style = try? self.loadSettingDictionary(at: url) else { return }
            let settingName = self.settingName(from: url)
            
            // create file mapping data
            dict[settingName] = style.filter { mappingKeys.contains($0.key) }
                .mapValues { $0 as? [[String: String]] ?? [] }
                .mapValues { $0.compactMap { $0[SyntaxDefinitionKey.keyString.rawValue] } }
        }
        let map = self.bundledMap.merging(userMap) { (_, new) in new }
        
        // sort styles alphabetically
        self.settingNames = map.keys.sorted(options: [.localized, .caseInsensitive])
        // remove styles not exist
        UserDefaults.standard[.recentStyleNames]?.removeAll { !self.settingNames.contains($0) }
        
        // update file mapping tables
        let settingNames = self.settingNames.filter { !self.bundledSettingNames.contains($0) } + self.bundledSettingNames  // postpone bundled styles
        let tables = SyntaxKey.mappingKeys.reduce(into: [:]) { (tables, key) in
            tables[key] = settingNames.reduce(into: [String: [SettingName]]()) { (table, settingName) in
                guard let items = map[settingName]?[key.rawValue] else { return }
                
                for item in items {
                    table[item, default: []].append(settingName)
                }
            }
        }
        self.mappingTables.mutate { $0 = tables }
    }
    
    
    
    // MARK: Private Methods
    
    /// Load StyleDictionary at file URL.
    ///
    /// - Parameter fileURL: URL to a setting file.
    /// - Throws: `CocoaError`
    private func loadSettingDictionary(at fileURL: URL) throws -> StyleDictionary {
        
        let data = try Data(contentsOf: fileURL)
        let yaml = try YAMLSerialization.object(withYAMLData: data, options: kYAMLReadOptionMutableContainersAndLeaves)
        
        guard let styleDictionary = yaml as? StyleDictionary else {
            throw CocoaError.error(.fileReadCorruptFile, url: fileURL)
        }
        
        return styleDictionary
    }
    
    
    /// return whether contents of given highlight definition is the same as bundled one
    private func isEqualToBundledSetting(_ style: StyleDictionary, name: SettingName) -> Bool {
        
        guard let bundledStyle = self.bundledSettingDictionary(name: name) else { return false }
        
        return NSDictionary(dictionary: style).isEqual(to: bundledStyle)
    }
    
}



private extension StringProtocol where Self.Index == String.Index {
    
    /// try extracting used language from the shebang line
    func scanInterpreterInShebang() -> String? {
        
        // get first line
        var firstLine: String?
        self.enumerateLines { (line, stop) in
            firstLine = line
            stop = true
        }
        
        guard var shebang = firstLine, shebang.hasPrefix("#!") else { return nil }
        
        // remove #! symbol
        shebang = shebang.replacingOccurrences(of: "^#! *", with: "", options: .regularExpression)
        
        // find interpreter
        let components = shebang.components(separatedBy: " ")
        let interpreter = components.first?.components(separatedBy: "/").last
        
        // use first arg if the path targets env
        if interpreter == "env" {
            return components[safe: 1]
        }
        
        return interpreter
    }
    
}



// MARK: - Migration

extension SyntaxManager {
    
    /// convert CotEditor 1.x format (plist) syntax style definition to CotEditor 2.0 format (yaml) and save to user domain
    func importLegacyStyle(fileURL: URL) throws {
        
        assert(fileURL.pathExtension == "plist")
        
        let coordinator = NSFileCoordinator()
        
        var data: Data?
        coordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: nil) { (newReadingURL) in
            data = try? Data(contentsOf: newReadingURL)
        }
        guard let plistData = data else { throw CocoaError.error(.fileReadUnknown, url: fileURL) }
        
        let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil)
        
        guard let style = plist as? [String: Any] else { throw CocoaError.error(.fileReadUnsupportedScheme, url: fileURL) }
        
        // update style format
        let newStyle: [String: Any] = style
            .filter { $0.0 != "styleName" }   // remove lagacy "styleName" key
            .mapKeys { $0.replacingOccurrences(of: "Array", with: "") }  // remove all `Array` suffix from dict keys
        
        let yamlData = try YAMLSerialization.yamlData(with: newStyle, options: kYAMLWriteOptionSingleDocument)
        
        let styleName = self.settingName(from: fileURL)
        let destURL = self.preparedURLForUserSetting(name: styleName)
        coordinator.coordinate(writingItemAt: destURL, error: nil) { (newWritingURL) in
            try? yamlData.write(to: newWritingURL, options: .atomic)
        }
    }
    
}
