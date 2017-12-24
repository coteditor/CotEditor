/*
 
 SyntaxManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2004-12-24.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation
import YAML

@objc protocol SyntaxHolder: class {
    
    func changeSyntaxStyle(_ sender: Any?)
    func recolorAll(_ sender: Any?)
}


enum BundledStyleName {
    
    static let none: SyntaxManager.SettingName = NSLocalizedString("None", comment: "syntax style name")
    static let xml: SyntaxManager.SettingName = "XML"
}



// MARK: -

final class SyntaxManager: SettingFileManager {
    
    typealias SettingName = String
    typealias StyleDictionary = [String: Any]
    
    
    // MARK: Notification Names
    
    /// Posted when the recently used style list is updated.  This will be used for syntax style menu in toolbar.
    static let didUpdateSyntaxHistoryNotification = Notification.Name("SyntaxManagerDidUpdateSyntaxHistory")
    
    
    // MARK: Public Properties
    
    static let shared = SyntaxManager()
    
    
    // MARK: Private Properties
    
    private var styleNames: [SettingName] = []
    private var recentStyleNameSet: OrderedSet<SettingName>
    private let maximumRecentStyleNameCount: Int
    
    private var cachedSettingDictionaries: [SettingName: StyleDictionary] = [:]
    private var map: [SettingName: [String: [String]]] = [:]
    
    private let bundledStyleNames: [SettingName]
    private let bundledMap: [SettingName: [String: [String]]]
    
    private var mappingTables: [SyntaxKey: [String: [SettingName]]] = [.extensions: [:],
                                                                       .filenames: [:],
                                                                       .interpreters: [:]]
    
    private let propertyAccessQueue = DispatchQueue(label: "com.coteditor.CotEditor.SyntaxManager.property")  // like @synchronized(self)
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        self.recentStyleNameSet = OrderedSet(UserDefaults.standard[.recentStyleNames] ?? [])
        self.maximumRecentStyleNameCount = max(0, UserDefaults.standard[.maximumRecentStyleCount])
        
        // load bundled style list
        let url = Bundle.main.url(forResource: "SyntaxMap", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let map = try! JSONSerialization.jsonObject(with: data) as! [SettingName: [String: [String]]]
        
        self.bundledMap = map
        self.bundledStyleNames = map.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        
        super.init()
        
        // cache user styles
        self.loadUserSettings()
    }
    
    
    
    // MARK: Setting File Manager Methods
    
    /// directory name in both Application Support and bundled Resources
    override var directoryName: String {
        
        return "Syntaxes"
    }
    
    
    /// path extensions for user setting file
    override var filePathExtensions: [String] {
        
        return ["yaml", "yml"]
    }
    
    
    /// name of setting file type
    override var settingFileType: SettingFileType {
        
        return .syntaxStyle
    }
    
    
    /// list of names of setting file name (without extension)
    override var settingNames: [SettingName] {
        
        return self.styleNames
    }
    
    
    /// list of names of setting file name which are bundled (without extension)
    override var bundledSettingNames: [SettingName] {
        
        return self.bundledStyleNames
    }
    
    
    
    // MARK: Public Methods
    
    /// return recently used style history as an array
    var recentSettingNames: [SettingName] {
        
        let styleNames: [SettingName] = self.propertyAccessQueue.sync { self.recentStyleNameSet.array }
        
        return Array(styleNames.prefix(self.maximumRecentStyleNameCount))
    }
    
    
    /// return style name corresponding to file name
    func settingName(documentFileName fileName: String?) -> SettingName? {
        
        guard let fileName = fileName else { return nil }
        
        let mappingTables = self.propertyAccessQueue.sync { self.mappingTables }
        
        if let styleName = mappingTables[.filenames]?[fileName]?.first {
            return styleName
        }
        
        if let pathExtension = fileName.components(separatedBy: ".").last,
            let styleName = mappingTables[.extensions]?[pathExtension]?.first {
            return styleName
        }
        
        return nil
    }
    
    
    /// return style name scanning shebang in document content
    func settingName(documentContent content: String) -> SettingName? {
        
        if let interpreter = content.scanInterpreterInShebang(),
            let styleName = self.propertyAccessQueue.sync(execute: { self.mappingTables })[.interpreters]?[interpreter]?.first {
            return styleName
        }
        
        // check XML declaration
        if content.hasPrefix("<?xml ") {
            return BundledStyleName.xml
        }
        
        return nil
    }
    
    
    /// file extension list corresponding to style name
    func extensions(name: SettingName) -> [String] {
        
        return self.map[name]?[SyntaxKey.extensions.rawValue] ?? []
    }
    
    
    /// create SyntaxStyle instance from theme name
    func style(name: SettingName?) -> SyntaxStyle? {
        
        guard let name = name, name != BundledStyleName.none else {
            return SyntaxStyle(dictionary: nil, name: BundledStyleName.none)
        }
        
        guard self.styleNames.contains(name) else { return nil }
        
        let dictionary = self.settingDictionary(name: name)
        let style = SyntaxStyle(dictionary: dictionary, name: name)
        
        self.propertyAccessQueue.sync {
            self.recentStyleNameSet.remove(name)
            self.recentStyleNameSet.insert(name, at: 0)
        }
        
        DispatchQueue.main.async { [weak self] in
            if let recentSettingNames = self?.recentSettingNames {
                UserDefaults.standard[.recentStyleNames] = recentSettingNames  // set in the main thread in case
            }
            
            NotificationCenter.default.post(name: SyntaxManager.didUpdateSyntaxHistoryNotification, object: self)
        }
        
        return style
    }
    
    
    /// style dictionary list corresponding to style name
    func settingDictionary(name: SettingName) -> StyleDictionary? {
        
        // None style
        guard name != BundledStyleName.none else {
            return self.blankSettingDictionary
        }
        
        // load from cache
        if let style = self.propertyAccessQueue.sync(execute: { self.cachedSettingDictionaries[name] }) {
            return style
        }
        
        // load from file
        guard
            let url = self.urlForUsedSetting(name: name),
            let style = try? self.settingDictionary(fileURL: url)
            else { return nil }
        
        // store newly loaded style
        self.propertyAccessQueue.sync {
            self.cachedSettingDictionaries[name] = style
        }
        
        return style
    }
    
    
    /// return bundled version style dictionary or nil if not exists
    func bundledSettingDictionary(name: SettingName) -> StyleDictionary? {
        
        guard let url = self.urlForBundledSetting(name: name) else { return nil }
        
        return try? self.settingDictionary(fileURL: url)
    }
    
    
    /// import setting at passed-in URL
    override func importSetting(fileURL: URL) throws {
        
        if fileURL.pathExtension == "plist" {
            self.importLegacyStyle(fileURL: fileURL)  // ignore succession
        }
        
        try super.importSetting(fileURL: fileURL)
    }
    
    
    /// delete user’s file for the setting name
    override func removeSetting(name: SettingName) throws {
        
        try super.removeSetting(name: name)
        
        // update internal cache
        self.propertyAccessQueue.sync {
            self.cachedSettingDictionaries[name] = nil
        }
        
        self.updateCache { [weak self] in
            self?.notifySettingUpdate(oldName: name, newName: BundledStyleName.none)
        }
    }
    
    
    /// restore the setting with name
    override func restoreSetting(name: SettingName) throws {
        
        try super.restoreSetting(name: name)
        
        // update internal cache
        let dictionary = self.bundledSettingDictionary(name: name)
        self.propertyAccessQueue.sync {
            self.cachedSettingDictionaries[name] = dictionary
        }
        
        self.updateCache { [weak self] in
            self?.notifySettingUpdate(oldName: name, newName: name)
        }
    }
    
    
    /// save setting file
    func save(settingDictionary: StyleDictionary, name: SettingName, oldName: SettingName?) throws {
        
        guard !name.isEmpty else { return }
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        // sanitize -> remove empty mapping dicts
        for key in SyntaxKey.mappingKeys {
            (settingDictionary[key.rawValue] as? NSMutableArray)?.remove([:])
        }
        
        // sort
        let descriptors = [NSSortDescriptor(key: SyntaxDefinitionKey.beginString.rawValue, ascending: true,
                                            selector: #selector(NSString.caseInsensitiveCompare)),
                           NSSortDescriptor(key: SyntaxDefinitionKey.keyString.rawValue, ascending: true,
                                            selector: #selector(NSString.caseInsensitiveCompare))]
        let syntaxDictKeys = SyntaxType.all.map { $0.rawValue } + [SyntaxKey.outlineMenu.rawValue, SyntaxKey.completions.rawValue]
        for key in syntaxDictKeys {
            (settingDictionary[key] as? NSMutableArray)?.sort(using: descriptors)
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
                self.propertyAccessQueue.sync {
                    self.cachedSettingDictionaries[name] = nil
                }
            }
        } else {
            // save file to user domain
            let yamlData = try YAMLSerialization.yamlData(with: settingDictionary, options: kYAMLWriteOptionSingleDocument)
            try yamlData.write(to: saveURL, options: .atomic)
        }
        
        // update internal cache
        self.updateCache { [weak self] in
            if let oldName = oldName {
                self?.notifySettingUpdate(oldName: oldName, newName: name)
            }
        }
    }
    
    
    /// conflicted maps
    var mappingConflicts: [SyntaxKey: [String: [SyntaxManager.SettingName]]] {
        
        return self.mappingTables.mapValues { $0.filter { $0.value.count > 1 } }
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
    
    
    
    // MARK: Private Methods
    
    /// Return StyleDictionary at file URL.
    ///
    /// - parameter fileURL: URL to a setting file.
    /// - throws: CocoaError
    private func settingDictionary(fileURL: URL) throws -> StyleDictionary {
        
        let data = try Data(contentsOf: fileURL)
        let yaml = try YAMLSerialization.object(withYAMLData: data, options: kYAMLReadOptionMutableContainersAndLeaves)
        
        guard let styleDictionary = yaml as? StyleDictionary else {
            throw CocoaError.error(.fileReadCorruptFile, url: fileURL)
        }
        
        return styleDictionary
    }
    
    
    /// return whether contents of given highlight definition is the same as bundled one
    private func isEqualToBundledSetting(_ style: StyleDictionary, name: SettingName) -> Bool {
        
        guard self.isBundledSetting(name: name) else { return false }
        
        let bundledStyle = self.bundledSettingDictionary(name: name)
        
        return NSDictionary(dictionary: style).isEqual(to: bundledStyle)
    }
    
    
    /// update internal cache data
    override func loadUserSettings() {
        
        self.loadUserStyles()
        self.updateMappingTables()
    }
    
    
    /// load style files in user domain and re-build chache and mapping table
    private func loadUserStyles() {
        
        // load user styles if exists
        if let urls = self.userSettingFileURLs {
            let userStyles: [SyntaxManager.SettingName: StyleDictionary] = urls.flatDictionary { url in
                guard let style = try? self.settingDictionary(fileURL: url) else { return nil }
                let styleName = self.settingName(from: url)
                
                return (styleName, style)
            }
            
            // create file mapping data
            let mappingKeys = SyntaxKey.mappingKeys.map { $0.rawValue }
            let userMap = userStyles.mapValues { style -> [String: [String]] in
                style.filter { mappingKeys.contains($0.key) }
                    .mapValues { $0 as? [[String: String]] ?? [] }
                    .mapValues { $0.flatMap { $0[SyntaxDefinitionKey.keyString.rawValue] } }
            }
            self.map = self.bundledMap.merging(userMap) { (_, new) in new }
            
            // cache style since loaded
            self.propertyAccessQueue.sync {
                self.cachedSettingDictionaries.merge(userStyles) { (_, new) in new }
            }
        }
        
        // sort styles alphabetically
        self.styleNames = self.map.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        
        // remove deleted styles
        // -> don't care about style name change just for laziness
        self.propertyAccessQueue.sync {
            self.recentStyleNameSet.formIntersection(self.styleNames)
        }
        
        UserDefaults.standard[.recentStyleNames] = self.recentSettingNames
    }
    
    
    /// update file mapping tables
    private func updateMappingTables() {
        
        var styleNames = self.styleNames
        
        // postpone bundled styles
        for name in self.bundledStyleNames {
            styleNames.remove(name)
            styleNames.append(name)
        }
        
        let result = SyntaxKey.mappingKeys.map { key in
            styleNames.reduce(into: [String: [SettingName]]()) { (table, styleName) in
                guard let items = self.map[styleName]?[key.rawValue] else { return }
                
                for item in items {
                    table[item, default: []].append(styleName)
                }
            }
        }
        
        self.propertyAccessQueue.sync {
            self.mappingTables = Dictionary(uniqueKeysWithValues: zip(SyntaxKey.mappingKeys, result))
        }
    }
    
}



private extension String {
    
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
    @discardableResult
    func importLegacyStyle(fileURL: URL) -> Bool {
        
        guard fileURL.pathExtension == "plist" else { return false }
        
        let styleName = self.settingName(from: fileURL)
        let destURL = self.preparedURLForUserSetting(name: styleName)
        let coordinator = NSFileCoordinator()
        
        var data: Data?
        coordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: nil) { (newReadingURL) in
            data = try? Data(contentsOf: newReadingURL)
        }
        
        guard
            let plistData = data,
            let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil),
            let style = plist as? [String: Any] else { return false }
        
        var newStyle = [String: Any]()
        
        // format migration
        for (key, value) in style {
            // remove lagacy "styleName" key
            guard key != "styleName" else { continue }
            
            // remove all `Array` suffix from dict keys
            let newKey = key.replacingOccurrences(of: "Array", with: "")
            newStyle[newKey] = value
        }
        
        guard let yamlData = try? YAMLSerialization.yamlData(with: newStyle, options: kYAMLWriteOptionSingleDocument) else { return false }
        
        coordinator.coordinate(writingItemAt: destURL, error: nil) { (newWritingURL) in
            try? yamlData.write(to: newWritingURL, options: .atomic)
        }
        
        return true
    }
    
}
