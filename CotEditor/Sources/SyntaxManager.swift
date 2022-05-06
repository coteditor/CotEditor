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
//  © 2014-2022 1024jp
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
import UniformTypeIdentifiers
import Yams

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
        
        // load bundled style list
        let url = Bundle.main.url(forResource: "SyntaxMap", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let map = try! JSONDecoder().decode([SettingName: [String: [String]]].self, from: data)
        self.bundledMap = map
        self.bundledSettingNames = map.keys.sorted(options: [.localized, .caseInsensitive])
        
        // sanitize user setting file extensions
        try? self.sanitizeUserSettings()
        
        // cache user styles
        self.checkUserSettings()
        
        // update also .mappingTables
        self.settingUpdateObserver = self.didUpdateSetting
            .sink { [weak self] _ in self?.checkUserSettings() }
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
        
        let mappingTables = self.mappingTables
        
        if let settingName = mappingTables[.filenames]?[fileName]?.first {
            return settingName
        }
        
        if let pathExtension = fileName.components(separatedBy: ".").last,
           let extentionTable = mappingTables[.extensions]
        {
            if let settingName = extentionTable[pathExtension]?.first {
                return settingName
            }
            
            // check case-insensitively
            let lowerPathExtension = pathExtension.lowercased()
            if let sttingName = extentionTable
                .first(where: { $0.key.lowercased() == lowerPathExtension })?
                .value.first
            {
                return sttingName
            }
        }
        
        return nil
    }
    
    
    /// return style name scanning shebang in document content
    func settingName(documentContent content: String) -> SettingName? {
        
        if let interpreter = content.scanInterpreterInShebang(),
            let settingName = self.mappingTables[.interpreters]?[interpreter]?.first {
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
        
        guard
            let url = self.urlForUsedSetting(name: name),
            let dictionary = try? self.loadSettingDictionary(at: url)
            else { return nil }
        
        return dictionary.cocoaBindable
    }
    
    
    /// return bundled version style dictionary or nil if not exists
    func bundledSettingDictionary(name: SettingName) -> StyleDictionary? {
        
        guard
            let url = self.urlForBundledSetting(name: name),
            let dictionary = try? self.loadSettingDictionary(at: url)
            else { return nil }
        
        return dictionary.cocoaBindable
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
            let yamlString = try Yams.dump(object: settingDictionary.yamlEncodable, allowUnicode: true)
            try yamlString.write(to: saveURL, atomically: true, encoding: .utf8)
        }
        
        // invalidate current cache
        self.$cachedSettings.mutate { $0[name] = nil }
        if let oldName = oldName {
            self.$cachedSettings.mutate { $0[oldName] = nil }
        }
        
        // update internal cache
        let change: SettingChange = oldName.flatMap { .updated(from: $0, to: name) } ?? .added(name)
        self.updateSettingList(change: change)
        self.didUpdateSetting.send(change)
    }
    
    
    /// conflicted maps
    var mappingConflicts: [SyntaxKey: [String: [SettingName]]] {
        
        self.mappingTables
            .mapValues { $0.filter { $0.value.count > 1 } }
            .filter { !$0.value.isEmpty }
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
    
    
    /// Check if any of user settings that use `\n` in regular expression patterns exists.
    ///
    /// Don't forget to revert SyntaxStyle's .outlineDefinitions and .highlightDefinitions to private
    /// when removing this method.
    func needsLineEndingMigration() -> Bool {
        
        self.userSettingFileURLs.lazy
            .compactMap { try? self.loadSetting(at: $0) }
            .flatMap { setting in
                setting.outlineDefinitions
                    .map(\.pattern)
                + setting.highlightDefinitions
                    .flatMap(\.value)
                    .filter(\.isRegularExpression)
                    .flatMap { [$0.beginString, $0.endString].compactMap { $0 } }
            }
            .contains { $0.contains("\\n") }
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
            self.$cachedSettings.mutate { $0[name] = setting }
            
            return setting
            }() else { return nil }
        
        // add to recent styles list
        let maximumRecentStyleCount = max(0, UserDefaults.standard[.maximumRecentStyleCount])
        var recentStyleNames = UserDefaults.standard[.recentStyleNames]
        recentStyleNames.removeFirst(name)
        recentStyleNames.insert(name, at: 0)
        UserDefaults.standard[.recentStyleNames] = Array(recentStyleNames.prefix(maximumRecentStyleCount))
        
        return setting
    }
    
    
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
                .mapValues { $0.compactMap { $0[SyntaxDefinitionKey.keyString] } }
        }
        let map = self.bundledMap.merging(userMap) { (_, new) in new }
        
        // sort styles alphabetically
        self.settingNames = map.keys.sorted(options: [.localized, .caseInsensitive])
        // remove styles not exist
        UserDefaults.standard[.recentStyleNames].removeAll { !self.settingNames.contains($0) }
        
        // update file mapping tables
        let settingNames = self.settingNames.filter { !self.bundledSettingNames.contains($0) } + self.bundledSettingNames  // postpone bundled styles
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
    
    /// Load StyleDictionary at file URL.
    ///
    /// - Parameter fileURL: URL to a setting file.
    /// - Throws: `CocoaError`
    private func loadSettingDictionary(at fileURL: URL) throws -> StyleDictionary {
        
        let string = try String(contentsOf: fileURL)
        let yaml = try Yams.load(yaml: string)
        
        guard let styleDictionary = yaml as? StyleDictionary else {
            throw CocoaError.error(.fileReadCorruptFile, url: fileURL)
        }
        
        return styleDictionary
    }
    
    
    /// return whether contents of given highlight definition is the same as bundled one
    private func isEqualToBundledSetting(_ style: StyleDictionary, name: SettingName) -> Bool {
        
        guard let bundledStyle = self.bundledSettingDictionary(name: name) else { return false }
        
        return style == bundledStyle
    }
    
}



private extension StringProtocol where Self.Index == String.Index {
    
    /// Extract interepreter from the shebang line.
    func scanInterpreterInShebang() -> String? {
        
        guard self.hasPrefix("#!") else { return nil }
        
        // get first line
        let firstLineRange = self.lineContentsRange(at: self.startIndex)
        let shebang = self[firstLineRange]
            .dropFirst("#!".count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
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



// MARK: - Cocoa Bindings Support

private extension SyntaxManager.StyleDictionary {
    
    /// Convert to NSObject-based collection for Cocoa-Bindings recursively.
    var cocoaBindable: Self {
        
        return self.mapValues(Self.convertToCocoaBindable)
    }
    
    
    /// Convert to YAML serialization comaptible colletion recursively.
    var yamlEncodable: Self {
        
        return self.mapValues(Self.convertToYAMLEncodable)
    }
    
    
    // MARK: Private Methods
    
    private static func convertToYAMLEncodable(_ item: Any) -> Any {
        
        switch item {
            case let dictionary as NSDictionary:
                return (dictionary as! Dictionary).mapValues(Self.convertToYAMLEncodable)
            case let array as NSArray:
                return (array as Array).map(Self.convertToYAMLEncodable)
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
            case let dictionary as Dictionary:
                return NSMutableDictionary(dictionary: dictionary.mapValues(convertToCocoaBindable))
            case let array as [Any]:
                return NSMutableArray(array: array.map(convertToCocoaBindable))
            case let date as Date:
                return ISO8601DateFormatter.string(from: date, timeZone: .current,
                                                   formatOptions: [.withFullDate, .withDashSeparatorInDate])
            default:
                return item
        }
    }
    
}



// MARK: - Equitability Support

private extension SyntaxManager.StyleDictionary {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        
        return areEqual(lhs, rhs)
    }
    
    
    // MARK: Private Methods
    
    /// Check the equitability recursively.
    ///
    /// This comparison is designed and valid only for StyleDictionary.
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
