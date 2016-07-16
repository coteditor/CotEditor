/*
 
 ThemeManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-12.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation
import AppKit.NSColor

let ThemeExtension = "cottheme"


@objc protocol ThemeHolder {
    
    func changeTheme(_ sender: AnyObject?)
}


class ThemeManager: CESettingFileManager {
    
    // MARK: Public Properties
    
    static let ListDidUpdateNotification = Notification.Name("ThemeListDidUpdate")
    static let ThemeDidUpdateNotification = Notification.Name("ThemeDidUpdate")
    
    static let shared = ThemeManager()
    
    private(set) var themeNames = [String]()
    
    
    // MARK: Private Properties
    
    var archivedThemes = [String: ThemeDictionary]()
    var bundledThemeNames = [String]()
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        // cache bundled theme names
        let themeURLs = Bundle.main.urlsForResources(withExtension: self.filePathExtension(), subdirectory: self.directoryName()) ?? []
        for themeURL in themeURLs {
            if themeURL.lastPathComponent?.hasPrefix("_") ?? false { continue }
            
            self.bundledThemeNames.append(self.settingName(from: themeURL))
        }
        
        // cache user themes asynchronously but wait until the process will be done
        let semaphore = DispatchSemaphore(value: 0)
        self.updateCache { 
            semaphore.signal()
        }
        while semaphore.wait(timeout: .now()) == .Success {
            RunLoop.current.run()
        }
    }
    
    
    
    // MARK: Setting File Manager Methods
    
    /// directory name in both Application Support and bundled Resources
    override func directoryName() -> String {
        
        return "Themes"
    }
    
    
    /// path extension for user setting file
    override func filePathExtension() -> String {
        
        return ThemeExtension
    }
    
    
    /// list of names of setting file name (without extension)
    override func settingNames() -> [String] {
        
        return self.themeNames
    }
    
    
    /// list of names of setting file name which are bundled (without extension)
    override func bundledSettingNames() -> [String] {
        
        return self.bundledThemeNames
    }
    
    
    
    // MARK: Public Methods
    
    /// create Theme instance from theme name
    func theme(name themeName: String) -> Theme? {
        
        guard let themeDictionary = self.themeDictionary(name: themeName) else { return nil }
        
        return Theme(dictionary: themeDictionary, name: themeName)
    }
    
    
    /// Theme dict in which objects are property list ready.
    func themeDictionary(name themeName: String) -> ThemeDictionary? {
    
        return self.archivedThemes[themeName]
    }
    
    
    /// save theme
    func save(themeDictionary: ThemeDictionary, name themeName: String, completionHandler: ((NSError?) -> Void)? = nil) -> Bool {
        
        // create directory to save in user domain if not yet exist
        guard self.prepareUserSettingDirectory() else { return false }
        
        let fileURL = self.urlForUserSetting(withName: themeName, available: false)!
        
        do {
            let data = try JSONSerialization.data(withJSONObject: themeDictionary, options: .prettyPrinted)
            
            try data.write(to: fileURL, options: .atomic)
            
        } catch let error as NSError {
            completionHandler?(error)
            return false
        }
        
        self.updateCache { [weak self] in
            NotificationCenter.default.post(name: ThemeManager.ThemeDidUpdateNotification, object: self,
                                            userInfo: [CEOldNameKey: themeName,
                                                       CENewNameKey: themeName])
            
            completionHandler?(nil)
        }
        
        return true
    }
    
    
    /// rename theme
    override func renameSetting(withName settingName: String, toName newSettingName: String) throws {
        
        try super.renameSetting(withName: settingName, toName: newSettingName)
        
        if UserDefaults.standard.string(forKey: DefaultKey.theme.rawValue) == settingName {
            UserDefaults.standard.set(newSettingName, forKey: DefaultKey.theme.rawValue)
        }
        
        self.updateCache { [weak self] in
            NotificationCenter.default.post(name: ThemeManager.ThemeDidUpdateNotification,
                                            object: self,
                                            userInfo: [CEOldNameKey: settingName,
                                                       CENewNameKey: newSettingName])
        }
    }
    
    
    /// delete theme file corresponding to the theme name
    override func removeSetting(withName settingName: String) throws {
        
        try super.removeSetting(withName: settingName)
        
        self.updateCache { [weak self] in
            // restore theme of opened documents to default
            let defaultThemeName = UserDefaults.standard.string(forKey: DefaultKey.theme.rawValue)!
            
            NotificationCenter.default.post(name: ThemeManager.ThemeDidUpdateNotification,
                                            object: self,
                                            userInfo: [CEOldNameKey: settingName,
                                                       CENewNameKey: defaultThemeName])
        }
    }
    
    
    /// restore customized bundled theme to original one
    override func restoreSetting(withName settingName: String) throws {
        
        try super.restoreSetting(withName: settingName)
        
        self.updateCache { [weak self] in
            NotificationCenter.default.post(name: ThemeManager.ThemeDidUpdateNotification,
                                            object: self,
                                            userInfo: [CEOldNameKey: settingName,
                                                       CENewNameKey: settingName])
        }
    }
    
    
    /// copy external theme file to user domain
    override func importSetting(withFileURL fileURL: URL) throws {
        
        do {
            try super.importSetting(withFileURL: fileURL)
            
        } catch let error as NSError where error.domain == CEErrorDomain && error.code == CEErrorCode.CESettingImportFileDuplicatedError.rawValue {
            // replace error message
            let themeName = self.settingName(from: fileURL)
            var userInfo = error.userInfo
            userInfo[NSLocalizedDescriptionKey] = String(format: NSLocalizedString("A new theme named “%@” will be installed, but a custom theme with the same name already exists.", comment: ""), themeName)
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = NSLocalizedString("Do you want to replace it?\nReplaced theme can’t be restored.", comment: "")
            
            throw NSError(domain: CEErrorDomain, code: CEErrorCode.CESettingImportFileDuplicatedError.rawValue, userInfo: userInfo)
        }
    }
    
    
    /// create a new untitled theme
    func createUntitledTheme(completionHandler: ((String, NSError?) -> Void)? = nil) {
        
        var newThemeName = NSLocalizedString("Untitled", comment: "")
        
        // append "Copy n" if "Untitled" already exists
        if self.urlForUserSetting(withName: newThemeName, available: true) != nil {
            newThemeName = self.copiedSettingName(newThemeName)
        }
        
        let _ = self.save(themeDictionary: self.plainThemeDictionary, name: newThemeName) { (error: NSError?) in
            completionHandler?(newThemeName, error)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// create ThemeDictionary from a file at the URL
    func themeDictionary(fileURL: URL) -> ThemeDictionary? {
        
        guard let data = try? Data(contentsOf: fileURL, options: []) else { return nil }
        
        return (try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)) as? ThemeDictionary
    }
    
    
    /// update internal cache data
    override func updateCache(completionHandler: (() -> Void)? = nil) {
        
        DispatchQueue.global().async { [weak self] in
            
            guard let strongSelf = self else { return }
            
            let userDirURL = strongSelf.userSettingDirectoryURL()
            let themeNameSet = NSMutableOrderedSet(array: strongSelf.bundledThemeNames)
            
            // load user themes if exists
            if userDirURL.isReachable {
                let fileURLs = (try? FileManager.default.contentsOfDirectory(at: userDirURL, includingPropertiesForKeys: nil,
                                                                            options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])) ?? []
                for fileURL in fileURLs {
                    guard fileURL.pathExtension == self?.filePathExtension() else { continue }
                    
                    let name = strongSelf.settingName(from: fileURL)
                    themeNameSet.add(name)
                }
                
                let isListUpdated = (themeNameSet.array as! [String] == strongSelf.themeNames)
                strongSelf.themeNames = themeNameSet.array as! [String]
                
                // cache definitions
                var themes = [String: ThemeDictionary]()
                for name in (themeNameSet.array as! [String]) {
                    if let themeURL = strongSelf.urlForUsedSetting(withName: name) {
                        themes[name] = strongSelf.themeDictionary(fileURL: themeURL)
                    }
                }
                strongSelf.archivedThemes = themes
                
                // reset user default if not found
                let defaultThemeName = UserDefaults.standard.string(forKey: DefaultKey.theme.rawValue)!
                if !themeNameSet.contains(defaultThemeName) {
                    UserDefaults.standard.removeObject(forKey: DefaultKey.theme.rawValue)
                }
                
                DispatchQueue.main.sync {
                    // post notification
                    if isListUpdated {
                        NotificationCenter.default.post(name: ThemeManager.ListDidUpdateNotification, object: strongSelf)
                    }
                    
                    completionHandler?()
                }
            }
        }
    }
    
    
    /// plain theme to be based on when creating a new theme
    var plainThemeDictionary: ThemeDictionary {
        
        let url = self.urlForBundledSetting(withName: "_Plain", available: false)!
        
        return self.themeDictionary(fileURL: url)!
    }
    
}



// MARK:

// Extension for the migration from CotEditor 1.x to 2.0. (2014-10)
// It can be removed when the most of users have been already migrated in the future.
extension ThemeManager {
    
    func migrateTheme() -> Bool {
        
        let themeName = NSLocalizedString("Customized Theme", comment: "")
        
        // don't need to migrate if custom theme file already exists (to avoid overwrite)
        guard self.urlForUserSetting(withName: themeName, available: true) == nil else { return false }
        
        // find customized theme colors from UserDefault
        var theme = self.classicTheme
        for (classicKey, modernKey) in self.classicThemeKeyTable {
            guard let oldData = UserDefaults.standard.data(forKey: classicKey),
                let rawColor = NSUnarchiver.unarchiveObject(with: oldData),
                let color = rawColor.usingColorSpaceName(NSCalibratedRGBColorSpace) else { continue }
            
            theme[modernKey.rawValue]?[ThemeKey.Sub.color.rawValue] = color.colorCode(with: .hex)
            if modernKey == .selection {
                theme[modernKey.rawValue]?[ThemeKey.Sub.usesSystemSetting.rawValue] = false
            }
        }
        
        // create Customized Theme if more than one of colors is customized
        guard theme == self.classicTheme else { return false }
        
        // add description
        theme[DictionaryKey.metadata.rawValue] = NSMutableDictionary(dictionary: [[MetadataKey.description.rawValue]: NSLocalizedString("Auto-generated theme that is migrated from user’s coloring setting on CotEditor 1.x", comment: "")])
        
        guard self.save(themeDictionary: theme, name: themeName, completionHandler: nil) else { return false }
        
        // set as default theme
        UserDefaults.standard.set(themeName, forKey: DefaultKey.theme.rawValue)
        
        self.updateCache(completionHandler: nil)
        
        return true
    }
    
    
    /// CotEditor 1.5までで使用されていたデフォルトテーマに新たなキーワードを加えたもの
    private var classicTheme: ThemeDictionary {
        
        let url = self.urlForBundledSetting(withName: "Classic", available: false)!
        
        return self.themeDictionary(fileURL: url)!
    }
    
    
    /// CotEditor 1.5までで使用されていたカラーリング設定のUserDefaultsキーとテーマファイルで使用しているキーの対応テーブル
    private var classicThemeKeyTable: [String: ThemeKey] {
        return ["textColor": .text,
                "backgroundColor": .background,
                "invisibleCharactersColor": .invisibles,
                "selectionColor": .selection,
                "insertionPointColor": .insertionPoint,
                "highlightLineColor": .lineHighlight,
                "keywordsColor": .keywords,
                "commandsColor": .commands,
                "valuesColor": .values,
                "numbersColor": .numbers,
                "stringsColor": .strings,
                "charactersColor": .characters,
                "commentsColor": .comments,
        ]
    }
    
}
