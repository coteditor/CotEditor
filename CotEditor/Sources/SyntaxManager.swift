/*
 
 SyntaxManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2004-12-24.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
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
    
    /// Posted when the line-up of syntax styles is updated.  This will be used for syntax style menus.
    static let SyntaxListDidUpdate = Notification.Name("SyntaxListDidUpdate")
    
    /// Posted when the recently used style list is updated.  This will be used for syntax style menu in toolbar.
    static let StyntaxDidUpdate = Notification.Name("StyntaxDidUpdate")
    
    /// Posted when a syntax style is updated.  Information about new/previous style names are in userInfo.
    static let SyntaxHistoryDidUpdate = Notification.Name("SyntaxHistoryDidUpdate")
}


@objc protocol SyntaxHolder: class {
    
    func changeSyntaxStyle(_ sender: Any?)
    func recolorAll(_ sender: Any?)
}


enum BundledStyleName {
    
    static let none: SyntaxManager.StyleName = NSLocalizedString("None", comment: "syntax style name")
    static let xml: SyntaxManager.StyleName = "XML"
}



// MARK:

final class SyntaxManager: SettingFileManager {
    
    typealias StyleName = String
    typealias StyleDictionary = [String: Any]
    
    
    // MARK: Public Properties
    
    static let shared = SyntaxManager()
    
    private(set) var styleNames: [StyleName] = []
    
    /// conflict error dicts
    private(set) var extensionConflicts: [String: [StyleName]] = [:]
    private(set) var filenameConflicts: [String: [StyleName]] = [:]
    
    
    // MARK: Private Properties
    
    private var recentStyleNameSet = NSMutableOrderedSet()
    private let maximumRecentStyleNameCount: Int
    
    private var styleCaches: [StyleName: StyleDictionary] = [:]
    private var map: [StyleName: [String: [String]]] = [:]
    
    private let bundledStyleNames: [StyleName]
    private let bundledMap: [StyleName: [String: [String]]]
    
    private var extensionToStyle: [String: StyleName] = [:]
    private var filenameToStyle: [String: StyleName] = [:]
    private var interpreterToStyle: [String: StyleName] = [:]
    
    private let propertyAccessQueue = DispatchQueue(label: "com.coteditor.CotEditor.SyntaxManager.property")  // like @synchronized(self)
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override private init() {
        
        self.recentStyleNameSet = NSMutableOrderedSet(array: Defaults[.recentStyleNames] ?? [])
        self.maximumRecentStyleNameCount = Defaults[.maximumRecentStyleCount]
        
        // load bundled style list
        let url = Bundle.main.url(forResource: "SyntaxMap", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let map = try! JSONSerialization.jsonObject(with: data) as! [StyleName: [String: [String]]]
        
        self.bundledMap = map
        self.bundledStyleNames = map.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        
        super.init()
        
        // cache user styles
        self.loadUserStyles()
        self.updateMappingTables()
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
    override var settingNames: [StyleName] {
        
        return self.styleNames
    }
    
    
    /// list of names of setting file name which are bundled (without extension)
    override var bundledSettingNames: [StyleName] {
        
        return self.bundledStyleNames
    }
    
    
    
    // MARK: Public Methods
    
    /// return recently used style history as an array
    var recentStyleNames: [StyleName] {
        
        let styleNames: [StyleName] = self.propertyAccessQueue.sync {
            return self.recentStyleNameSet.array as! [StyleName]
        }
        
        return Array(styleNames.prefix(self.maximumRecentStyleNameCount))
    }
    
    
    /// create new SyntaxStyle instance
    func style(name: StyleName?) -> SyntaxStyle? {
        
        guard let name = name, name != BundledStyleName.none else {
            return SyntaxStyle(dictionary: nil, name: BundledStyleName.none)
        }
        
        guard self.styleNames.contains(name) else { return nil }
        
        let dictionary = self.styleDictionary(name: name)
        let style = SyntaxStyle(dictionary: dictionary, name: name)
        
        self.propertyAccessQueue.sync {
            self.recentStyleNameSet.remove(name)
            self.recentStyleNameSet.insert(name, at: 0)
        }
        Defaults[.recentStyleNames] = self.recentStyleNames
        
        DispatchQueue.main.async { [weak self] in
            NotificationCenter.default.post(name: .SyntaxHistoryDidUpdate, object: self)
        }
        
        return style
    }
    
    
    /// return style name corresponding to file name
    func styleName(documentFileName fileName: String?) -> String? {
        
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
    func styleName(documentContent content: String) -> String? {
        
        if let interpreter = self.scanInterpreterFromShebang(in: content),
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
    func extensions(name: StyleName) -> [String] {
        
        return self.map[name]?[SyntaxKey.extensions.rawValue] ?? []
    }
    
    
    /// style dictionary list corresponding to style name
    func styleDictionary(name: StyleName) -> StyleDictionary {
        
        // None style
        guard !name.isEmpty && name != BundledStyleName.none else {
            return self.emptyStyleDictionary
        }
        
        // load from cache
        if let style = self.styleCaches[name] {
            return style
        }
        
        // load from file
        if let url = self.urlForUsedSetting(name: name),
            let style = self.styleDictionary(fileURL: url) {
            
            // store newly loaded style
            self.styleCaches[name] = style
            
            return style
        }
        
        return self.emptyStyleDictionary
    }
    
    
    /// return bundled version style dictionary or nil if not exists
    func bundledStyleDictionary(name: StyleName) -> StyleDictionary? {
        
        guard let url = self.urlForBundledSetting(name: name) else { return nil }
        
        return self.styleDictionary(fileURL: url)
    }
    
    
    /// import setting at passed-in URL
    override func importSetting(fileURL: URL) throws {
        
        if fileURL.pathExtension == "plist" {
            self.importLegacyStyle(fileURL: fileURL)  // ignore succession
        }
        
        try super.importSetting(fileURL: fileURL)
    }
    
    
    /// delete user’s file for the setting name
    override func removeSetting(name: StyleName) throws {
        
        try super.removeSetting(name: name)
        
        // update internal cache
        self.styleCaches[name] = nil
        
        self.updateCache { [weak self] in
            NotificationCenter.default.post(name: .StyntaxDidUpdate, object: self,
                                            userInfo: [SettingFileManager.NotificationKey.old: name,
                                                       SettingFileManager.NotificationKey.new: BundledStyleName.none])
        }
    }
    
    
    /// restore the setting with name
    override func restoreSetting(name: StyleName) throws {
        
        try super.restoreSetting(name: name)
        
        // update internal cache
        self.styleCaches[name] = self.bundledStyleDictionary(name: name)
        
        self.updateCache { [weak self] in
            NotificationCenter.default.post(name: .StyntaxDidUpdate, object: self,
                                            userInfo: [SettingFileManager.NotificationKey.old: name,
                                                       SettingFileManager.NotificationKey.new: name])
        }
    }
    
    
    /// save style
    func save(styleDictionary: StyleDictionary, name: StyleName, oldName: StyleName?) throws {
        
        guard !name.isEmpty else { return }
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        // sanitize -> remove empty mapping dicts
        for key in [SyntaxKey.extensions.rawValue, SyntaxKey.filenames.rawValue, SyntaxKey.filenames.rawValue] {
            (styleDictionary[key] as? NSMutableArray)?.remove([:])
        }
        
        // sort
        let descriptors = [NSSortDescriptor(key: SyntaxDefinitionKey.beginString.rawValue, ascending: true,
                                            selector: #selector(NSString.caseInsensitiveCompare(_:))),
                           NSSortDescriptor(key: SyntaxDefinitionKey.keyString.rawValue, ascending: true,
                                            selector: #selector(NSString.caseInsensitiveCompare(_:)))]
        let syntaxDictKeys = SyntaxType.all.map { $0.rawValue } + [SyntaxKey.outlineMenu.rawValue, SyntaxKey.completions.rawValue]
        for key in syntaxDictKeys {
            (styleDictionary[key] as? NSMutableArray)?.sort(using: descriptors)
        }
        
        // save
        let saveURL = self.preparedURLForUserSetting(name: name)
        
        // move old file to new place to overwrite when style name is also changed
        if let oldName = oldName, name != oldName {
            try self.renameSetting(name: oldName, to: name)
        }
        
        // just remove the current custom setting file in the user domain if new style is just the same as bundled one
        // so that application uses bundled one
        if self.isEqualToBundledStyle(styleDictionary, name: name) {
            if saveURL.isReachable {
                try FileManager.default.removeItem(at: saveURL)
                self.styleCaches[name] = nil
            }
        } else {
            // save file to user domain
            let yamlData = try YAMLSerialization.yamlData(with: styleDictionary, options: kYAMLWriteOptionSingleDocument)
            try yamlData.write(to: saveURL, options: .atomic)
        }
        
        // update internal cache
        self.updateCache { [weak self] in
            if let oldName = oldName {
                NotificationCenter.default.post(name: .StyntaxDidUpdate, object: self,
                                                userInfo: [SettingFileManager.NotificationKey.old: oldName,
                                                           SettingFileManager.NotificationKey.new: name])
            }
        }
    }
    
    
    /// return if mapping conflict exists
    var existsMappingConflict: Bool {
        
        return !self.extensionConflicts.isEmpty || !self.filenameConflicts.isEmpty
    }
    
    
    /// empty style dictionary
    var emptyStyleDictionary: StyleDictionary {
        
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
    }
    
    
    
    // MARK: Private Methods
    
    /// return style dictionary at file URL
    private func styleDictionary(fileURL: URL) -> StyleDictionary? {
        
        guard
            let yamlData = try? Data(contentsOf: fileURL),
            let yaml = try? YAMLSerialization.object(withYAMLData: yamlData,
                                                     options: kYAMLReadOptionMutableContainersAndLeaves) else { return nil }
        
        return yaml as? StyleDictionary
    }
    
    
    /// update internal cache data
    override func updateCache(completionHandler: (() -> Void)? = nil) {  // @escaping
        
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.loadUserStyles()
            strongSelf.updateMappingTables()
            
            DispatchQueue.main.sync {
                NotificationCenter.default.post(name: .SyntaxListDidUpdate, object: strongSelf)
                
                completionHandler?()
            }
        }
    }
    
    
    /// return whether contents of given highlight definition is the same as bundled one
    private func isEqualToBundledStyle(_ style: StyleDictionary, name: StyleName) -> Bool {
        
        guard self.isBundledSetting(name: name) else { return false }
        
        let bundledStyle = self.bundledStyleDictionary(name: name)
        
        return NSDictionary(dictionary: style).isEqual(to: bundledStyle)
    }
    
    
    /// load style files in user domain and re-build chache and mapping table
    private func loadUserStyles() {
        
        let directoryURL = self.userSettingDirectoryURL
        var map = self.bundledMap
        
        // load user styles
        if let enumerator = FileManager.default.enumerator(at: directoryURL, includingPropertiesForKeys: nil,
                                                           options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) {
            for case let url as URL in enumerator {
                guard [self.filePathExtension, "yml"].contains(url.pathExtension) else { continue }
                
                let styleName = self.settingName(from: url)
                guard let style = self.styleDictionary(fileURL: url) else { continue }
                
                map[styleName] = [SyntaxKey.extensions.rawValue: type(of: self).keyStrings(in: style, key: .extensions),
                                  SyntaxKey.filenames.rawValue: type(of: self).keyStrings(in: style, key: .filenames),
                                  SyntaxKey.interpreters.rawValue: type(of: self).keyStrings(in: style, key: .interpreters)]
                
                // cache style since it's already loaded
                self.styleCaches[styleName] = style
            }
        }
        self.map = map
        
        // sort styles alphabetically
        self.styleNames = map.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        
        // remove deleted styles
        // -> don't care about style name change just for laziness
        self.propertyAccessQueue.sync {
            self.recentStyleNameSet.intersectSet(Set(self.styleNames))
        }
        
        Defaults[.recentStyleNames] = self.recentStyleNames
    }
    
    
    /// collect values which has "keyString" key in key section in style dictionary
    private static func keyStrings(in style: StyleDictionary, key: SyntaxKey) -> [String] {
        
        guard let dictionaries = style[key.rawValue] as? [[String: String]] else { return [] }
        return dictionaries.flatMap { $0[SyntaxDefinitionKey.keyString.rawValue] }
    }
    
    
    /// update file mapping tables and mapping conflicts
    private func updateMappingTables() {
        
        var styleNames = self.styleNames
        
        // postpone bundled styles
        for name in self.bundledStyleNames {
            styleNames.remove(name)
            styleNames.append(name)
        }
        
        func parseMappingSettings(key: SyntaxKey) -> (table: [String: StyleName], conflicts: [String: [StyleName]]) {
            
            var table = [String: StyleName]()
            var conflicts = [String: [StyleName]]()
            
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
    
    
    /// try extracting used language from the shebang line
    private func scanInterpreterFromShebang(in string: String) -> String? {
        
        // get first line
        var firstLine: String?
        string.enumerateLines { (line, stop) in
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
        
        var newStyle = [String : Any]()
        
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
