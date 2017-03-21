/*
 
 ThemeManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-12.
 
 ------------------------------------------------------------------------------
 
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
import AppKit.NSColor
import ColorCode

@objc protocol ThemeHolder: class {
    
    func changeTheme(_ sender: AnyObject?)
}



// MARK: -

final class ThemeManager: SettingFileManager {
    
    // MARK: Public Properties
    
    static let shared = ThemeManager()
    
    private(set) var themeNames = [String]()
    
    
    // MARK: Private Properties
    
    private var cachedThemes = [String: Theme]()
    private var bundledThemeNames = [String]()
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        super.init()
        
        // cache bundled theme names
        let themeURLs = Bundle.main.urls(forResourcesWithExtension: self.filePathExtension, subdirectory: self.directoryName) ?? []
        self.bundledThemeNames = themeURLs.lazy
            .filter { !$0.lastPathComponent.hasPrefix("_") }
            .map { self.settingName(from: $0) }
        
        // cache user theme names
        self.loadThemeNames()
    }
    
    
    
    // MARK: Setting File Manager Methods
    
    /// directory name in both Application Support and bundled Resources
    override var directoryName: String {
        
        return "Themes"
    }
    
    
    /// path extension for user setting file
    override var filePathExtension: String {
        
        return DocumentType.theme.extensions[0]
    }
    
    
    /// name of setting file type
    override var settingFileType: SettingFileType {
        
        return .theme
    }
    
    
    /// list of names of setting file name (without extension)
    override var settingNames: [String] {
        
        return self.themeNames
    }
    
    
    /// list of names of setting file name which are bundled (without extension)
    override var bundledSettingNames: [String] {
        
        return self.bundledThemeNames
    }
    
    
    
    // MARK: Public Methods
    
    /// create Theme instance from theme name
    func theme(name: String) -> Theme? {
        
        // use cache if exists
        if let theme = self.cachedThemes[name] {
            return theme
        }
        
        guard let themeDictionary = self.themeDictionary(name: name) else { return nil }
        
        let theme = Theme(dictionary: themeDictionary, name: name)
        
        self.cachedThemes[name] = theme
        
        return theme
    }
    
    
    /// load theme dict in which objects are property list ready.
    func themeDictionary(name: String) -> ThemeDictionary? {
        
        guard
            let themeURL = self.urlForUsedSetting(name: name),
            let themeDictionary = try? self.themeDictionary(fileURL: themeURL)
            else { return nil }
        
        return themeDictionary
    }
    
    
    /// save theme
    @discardableResult
    func save(themeDictionary: ThemeDictionary, name settingName: String, completionHandler: ((Error?) -> Void)? = nil) -> Bool {  // @escaping
        
        // create directory to save in user domain if not yet exist
        do {
            try self.prepareUserSettingDirectory()
        } catch {
            completionHandler?(error)
            return false
        }
        
        let fileURL = self.preparedURLForUserSetting(name: settingName)
        
        do {
            let data = try JSONSerialization.data(withJSONObject: themeDictionary, options: .prettyPrinted)
            
            try data.write(to: fileURL, options: .atomic)
            
        } catch {
            completionHandler?(error)
            return false
        }
        
        self.updateCache { [weak self] in
            self?.notifySettingUpdate(oldName: settingName, newName: settingName)
            
            completionHandler?(nil)
        }
        
        return true
    }
    
    
    /// rename theme
    override func renameSetting(name settingName: String, to newName: String) throws {
        
        try super.renameSetting(name: settingName, to: newName)
        
        if UserDefaults.standard[.theme] == settingName {
            UserDefaults.standard[.theme] = newName
        }
        
        self.updateCache { [weak self] in
            self?.notifySettingUpdate(oldName: settingName, newName: newName)
        }
    }
    
    
    /// delete theme file corresponding to the theme name
    override func removeSetting(name settingName: String) throws {
        
        try super.removeSetting(name: settingName)
        
        self.updateCache { [weak self] in
            // restore theme of opened documents to default
            let defaultThemeName = UserDefaults.standard[.theme]!
            
            self?.notifySettingUpdate(oldName: settingName, newName: defaultThemeName)
        }
    }
    
    
    /// restore customized bundled theme to original one
    override func restoreSetting(name settingName: String) throws {
        
        try super.restoreSetting(name: settingName)
        
        self.updateCache { [weak self] in
            self?.notifySettingUpdate(oldName: settingName, newName: settingName)
        }
    }
    
    
    /// create a new untitled theme
    func createUntitledTheme(completionHandler: ((String, Error?) -> Void)? = nil) {  // @escaping
        
        // append number suffix if "Untitled" already exists
        let name = self.savableSettingName(for: NSLocalizedString("Untitled", comment: ""))
        
        self.save(themeDictionary: self.plainThemeDictionary, name: name) { (error: Error?) in
            completionHandler?(name, error)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Create ThemeDictionary from a file at the URL.
    ///
    /// - parameter fileURL: URL to a theme file.
    /// - throws: CocoaError
    private func themeDictionary(fileURL: URL) throws -> ThemeDictionary {
        
        let data = try Data(contentsOf: fileURL)
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        
        guard let themeDictionry = json as? ThemeDictionary else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        return themeDictionry
    }
    
    
    /// update internal cache data
    override func updateCache(completionHandler: (() -> Void)? = nil) {  // @escaping
        
        self.cachedThemes = [:]
        
        DispatchQueue.global().async { [weak self] in
            self?.loadThemeNames()
            
            DispatchQueue.main.sync {
                self?.notifySettingListUpdate()
                
                completionHandler?()
            }
        }
    }
    
    
    /// load theme names in user domain
    private func loadThemeNames() {
        
        let themeNameSet = NSMutableOrderedSet(array: self.bundledThemeNames)
        
        // load user themes if exists
        if let fileURLs = try? FileManager.default.contentsOfDirectory(at: self.userSettingDirectoryURL,
                                                                       includingPropertiesForKeys: nil,
                                                                       options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) {
            let userThemeNames = fileURLs
                .filter { $0.pathExtension == self.filePathExtension }
                .map { self.settingName(from: $0) }
            
            themeNameSet.addObjects(from: userThemeNames)
        }
        
        self.themeNames = themeNameSet.array as! [String]
        
        // reset user default if not found
        let defaultThemeName = UserDefaults.standard[.theme]!
        if !themeNameSet.contains(defaultThemeName) {
            UserDefaults.standard.removeObject(forKey: DefaultKeys.theme.rawValue)
        }
    }
    
    
    /// plain theme to be based on when creating a new theme
    private var plainThemeDictionary: ThemeDictionary {
        
        let url = self.urlForBundledSetting(name: "_Plain")!
        
        return try! self.themeDictionary(fileURL: url)
    }
    
}
