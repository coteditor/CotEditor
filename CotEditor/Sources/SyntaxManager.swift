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

extension Notification.Name {
    
    /// Posted when the recently used style list is updated.  This will be used for syntax style menu in toolbar.
    static let SyntaxHistoryDidUpdate = Notification.Name("SyntaxHistoryDidUpdate")
}


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
    
    
    // MARK: Public Properties
    
    static let shared = SyntaxManager()
    
    /// conflict error dicts
    private(set) var extensionConflicts: [String: [SettingName]] = [:]
    private(set) var filenameConflicts: [String: [SettingName]] = [:]
    
    
    // MARK: Private Properties
    
    private var styleNames: [SettingName] = []
    private var recentStyleNameSet: OrderedSet<SettingName>
    private let maximumRecentStyleNameCount: Int
    
    private var cachedSettingDictionaries: [SettingName: StyleDictionary] = [:]
    private var map: [SettingName: [String: [String]]] = [:]
    
    private let bundledStyleNames: [SettingName]
    private let bundledMap: [SettingName: [String: [String]]]
    
    private var extensionToStyle: [String: SettingName] = [:]
    private var filenameToStyle: [String: SettingName] = [:]
    private var interpreterToStyle: [String: SettingName] = [:]
    
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
    
    
    /// path extension for user setting file
    override var filePathExtension: String {
        
        return "yaml"
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
        
        if let styleName = self.propertyAccessQueue.sync(execute: { self.filenameToStyle })[fileName] {
            return styleName
        }
        
        if let pathExtension = fileName.components(separatedBy: ".").last,
            let styleName = self.propertyAccessQueue.sync(execute: { self.extensionToStyle })[pathExtension] {
            return styleName
        }
        
        return nil
    }
    
    
    /// return style name scanning shebang in document content
    func settingName(documentContent content: String) -> SettingName? {
        
        if let interpreter = content.scanInterpreterInShebang(),
            let styleName = self.propertyAccessQueue.sync(execute: { self.interpreterToStyle })[interpreter] {
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
        UserDefaults.standard[.recentStyleNames] = self.recentSettingNames
        
        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(name: .SyntaxHistoryDidUpdate, object: self)
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
        if let style = self.cachedSettingDictionaries[name] {
            return style
        }
        
        // load from file
        guard
            let url = self.urlForUsedSetting(name: name),
            let style = try? self.settingDictionary(fileURL: url)
            else { return nil }
        
        // store newly loaded style
        self.cachedSettingDictionaries[name] = style
        
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
        self.cachedSettingDictionaries[name] = nil
        
        self.updateCache { [weak self] in
            self?.notifySettingUpdate(oldName: name, newName: BundledStyleName.none)
        }
    }
    
    
    /// restore the setting with name
    override func restoreSetting(name: SettingName) throws {
        
        try super.restoreSetting(name: name)
        
        // update internal cache
        self.cachedSettingDictionaries[name] = self.bundledSettingDictionary(name: name)
        
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
        let mappingKeys: [SyntaxKey] = [.extensions, .filenames, .interpreters]
        for key in mappingKeys {
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
                self.cachedSettingDictionaries[name] = nil
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
    
    
    /// return if mapping conflict exists
    var existsMappingConflict: Bool {
        
        return !self.extensionConflicts.isEmpty || !self.filenameConflicts.isEmpty
    }
    
    
    /// empty style dictionary
    lazy var blankSettingDictionary: StyleDictionary = {
        
        // workaround for for Xcode's SourceKitService performance
        var dictionary = StyleDictionary()
        dictionary[SyntaxKey.metadata.rawValue] = NSMutableDictionary()
        dictionary[SyntaxKey.extensions.rawValue] = NSMutableArray()
        dictionary[SyntaxKey.filenames.rawValue] = NSMutableArray()
        dictionary[SyntaxKey.interpreters.rawValue] = NSMutableArray()
        dictionary[SyntaxType.keywords.rawValue] = NSMutableArray()
        dictionary[SyntaxType.commands.rawValue] = NSMutableArray()
        dictionary[SyntaxType.types.rawValue] = NSMutableArray()
        dictionary[SyntaxType.attributes.rawValue] = NSMutableArray()
        dictionary[SyntaxType.variables.rawValue] = NSMutableArray()
        dictionary[SyntaxType.values.rawValue] = NSMutableArray()
        dictionary[SyntaxType.numbers.rawValue] = NSMutableArray()
        dictionary[SyntaxType.strings.rawValue] = NSMutableArray()
        dictionary[SyntaxType.characters.rawValue] = NSMutableArray()
        dictionary[SyntaxType.comments.rawValue] = NSMutableArray()
        dictionary[SyntaxKey.outlineMenu.rawValue] = NSMutableArray()
        dictionary[SyntaxKey.completions.rawValue] = NSMutableArray()
        dictionary[SyntaxKey.commentDelimiters.rawValue] = NSMutableDictionary()
        
        return dictionary
    }()
    
    
    
    // MARK: Private Methods
    
    /// Return StyleDictionary at file URL.
    ///
    /// - parameter fileURL: URL to a setting file.
    /// - throws: CocoaError
    private func settingDictionary(fileURL: URL) throws -> StyleDictionary {
        
        let data = try Data(contentsOf: fileURL)
        let yaml = try YAMLSerialization.object(withYAMLData: data, options: kYAMLReadOptionMutableContainersAndLeaves)
        
        guard let styleDictionary = yaml as? StyleDictionary else {
            throw CocoaError(.fileReadCorruptFile)
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
        
        var map = self.bundledMap
        
        // load user styles if exists
        if let enumerator = FileManager.default.enumerator(at: self.userSettingDirectoryURL,
                                                           includingPropertiesForKeys: nil,
                                                           options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) {
            for case let url as URL in enumerator {
                guard [self.filePathExtension, "yml"].contains(url.pathExtension) else { continue }
                guard let style = try? self.settingDictionary(fileURL: url) else { continue }
                
                let styleName = self.settingName(from: url)
                let keys: [SyntaxKey] = [.extensions, .filenames, .interpreters]
                
                map[styleName] = keys.flatDictionary { [style = style] (key) in
                    // collect values which has "keyString" key in key section in style dictionary
                    let dictionaries = (style[key.rawValue] as? [[String: String]]) ?? []
                    let keyStrings = dictionaries.flatMap { $0[SyntaxDefinitionKey.keyString.rawValue] }
                    
                    return (key.rawValue, keyStrings)
                }
                
                // cache style since it's already loaded
                self.cachedSettingDictionaries[styleName] = style
            }
        }
        self.map = map
        
        // sort styles alphabetically
        self.styleNames = map.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        
        // remove deleted styles
        // -> don't care about style name change just for laziness
        self.propertyAccessQueue.sync {
            self.recentStyleNameSet.formIntersection(self.styleNames)
        }
        
        UserDefaults.standard[.recentStyleNames] = self.recentSettingNames
    }
    
    
    /// update file mapping tables and mapping conflicts
    private func updateMappingTables() {
        
        var styleNames = self.styleNames
        
        // postpone bundled styles
        for name in self.bundledStyleNames {
            styleNames.remove(name)
            styleNames.append(name)
        }
        
        func parseMappingSettings(key: SyntaxKey) -> (table: [String: SettingName], conflicts: [String: [SettingName]]) {
            
            var table = [String: SettingName]()
            var conflicts = [String: [SettingName]]()
            
            for styleName in styleNames {
                guard let items = self.map[styleName]?[key.rawValue] else { continue }
                
                for item in items {
                    guard let addedStyleName = table[item] else {
                        // add to table if not yet registered
                        table[item] = styleName
                        continue
                    }
                    
                    // register to conflict list
                    var duplicatedStyles = conflicts[item] ?? []
                    if !duplicatedStyles.contains(addedStyleName) {
                        duplicatedStyles.append(addedStyleName)
                    }
                    duplicatedStyles.append(styleName)
                    conflicts[item] = duplicatedStyles
                }
            }
            
            return (table: table, conflicts: conflicts)
        }
        
        let extensionResult = parseMappingSettings(key: .extensions)
        let filenameResult = parseMappingSettings(key: .filenames)
        let interpreterResult = parseMappingSettings(key: .interpreters)
        
        self.propertyAccessQueue.sync {
            self.extensionToStyle = extensionResult.table
            self.filenameToStyle = filenameResult.table
            self.interpreterToStyle = interpreterResult.table
        }
        
        self.extensionConflicts = extensionResult.conflicts
        self.filenameConflicts = filenameResult.conflicts
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
            return components[1]
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
