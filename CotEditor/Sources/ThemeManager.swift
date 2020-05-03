//
//  ThemeManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-04-12.
//
//  ---------------------------------------------------------------------------
//
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
import AppKit

@objc protocol ThemeHolder: AnyObject {
    
    func changeTheme(_ sender: AnyObject?)
}



// MARK: -

final class ThemeManager: SettingFileManaging {
    
    typealias Setting = Theme
    
    
    // MARK: Public Properties
    
    static let shared = ThemeManager()
    
    
    // MARK: Setting File Managing Properties
    
    static let directoryName: String = "Themes"
    let filePathExtensions: [String] = DocumentType.theme.extensions
    let settingFileType: SettingFileType = .theme
    
    private(set) var settingNames: [String] = []
    private(set) var bundledSettingNames: [String] = []
    var cachedSettings: [String: Setting] = [:]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private init() {
        
        // cache bundled setting names
        self.bundledSettingNames = Bundle.main.urls(forResourcesWithExtension: self.filePathExtension, subdirectory: Self.directoryName)!
            .map { self.settingName(from: $0) }
            .sorted(options: [.localized, .caseInsensitive])
        
        // cache user setting names
        self.checkUserSettings()
    }
    
    
    
    // MARK: Public Methods
    
    /// default setting by taking the appearance state into consideration
    var defaultSettingName: String {
        
        let defaultSettingName = DefaultSettings.defaults[.theme] as! String
        let forDark = self.usesDarkAppearance
        
        return self.equivalentSettingName(to: defaultSettingName, forDark: forDark)!
    }
    
    
    /// user default setting by taking the appearance state into consideration
    var userDefaultSettingName: String {
        
        let settingName = UserDefaults.standard[.theme]!
        
        if UserDefaults.standard[.pinsThemeAppearance] || NSAppKitVersion.current <= .macOS10_13 {
            return settingName
        }
        
        if let equivalentSettingName = self.equivalentSettingName(to: settingName, forDark: self.usesDarkAppearance) {
            return equivalentSettingName
        }
        
        guard self.settingNames.contains(settingName) else { return self.defaultSettingName }
        
        return settingName
    }
    
    
    /// save setting file
    func save(setting: Setting, name: String, completionHandler: @escaping (() -> Void) = {}) throws {
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(setting)
        let fileURL = self.preparedURLForUserSetting(name: name)
        
        try data.write(to: fileURL, options: .atomic)
        
        self.cachedSettings[name] = setting
        
        self.updateCache { [weak self] in
            self?.notifySettingUpdate(oldName: name, newName: name)
            
            completionHandler()
        }
    }
    
    
    /// create a new untitled setting
    func createUntitledSetting(completionHandler: @escaping ((_ settingName: String) -> Void) = { _ in }) throws {
        
        let name = self.savableSettingName(for: "Untitled".localized)
        
        try self.save(setting: Setting(), name: name) {
            completionHandler(name)
        }
    }
    
    
    /// return whether given setting name is dark theme
    func isDark(name: String) -> Bool {
        
        return name.range(of: "(Dark)", options: [.anchored, .backwards]) != nil
    }
    
    
    /// return setting name of dark/light version of given one if any exists
    func equivalentSettingName(to name: String, forDark: Bool) -> String? {
        
        let baseName: String
        if let range = name.range(of: "^.+(?= \\((?:Dark|Light)\\)$)", options: .regularExpression) {
            baseName = String(name[range])
        } else {
            baseName = name
        }
        
        let settingName = baseName + " " + (forDark ? "(Dark)" : "(Light)")
        if self.settingNames.contains(settingName) {
            return settingName
        }
        
        if !forDark, self.settingNames.contains(baseName) {
            return baseName
        }
        
        return nil
    }
    
    
    
    // MARK: Setting File Managing
    
    /// load setting from the file at given URL
    func loadSetting(at fileURL: URL) throws -> Setting {
        
        return try Theme.theme(contentsOf: fileURL)
    }
    
    
    /// load settings in the user domain
    func checkUserSettings() {
        
        // get user setting names if exists
        let userSettingNames = self.userSettingFileURLs
            .map { self.settingName(from: $0) }
            .sorted(options: [.localized, .caseInsensitive])
        
        self.settingNames = (self.bundledSettingNames + userSettingNames).unique
        
        // reset user default if not found
        if let userSetting = UserDefaults.standard[.theme],
            !self.settingNames.contains(userSetting)
        {
            UserDefaults.standard.restore(key: .theme)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// Whether user prefers using dark mode window.
    private var usesDarkAppearance: Bool {
        
        switch UserDefaults.standard[.documentAppearance] {
            case .default:
                guard #available(macOS 10.14, *) else { return false }
                // -> NSApperance.current doesn't return the latest appearance when the system appearance
                //    was changed after the app launch (macOS 10.14).
                return NSApp.effectiveAppearance.isDark
            case .light:
                return false
            case .dark:
                return true
        }
    }
    
}
