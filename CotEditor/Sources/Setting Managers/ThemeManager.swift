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
//  © 2014-2026 1024jp
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
import Defaults
import URLUtils

@MainActor final class ThemeManager: SettingFileManaging {
    
    typealias Setting = Theme
    
    
    // MARK: Public Properties
    
    static let shared = ThemeManager()
    
    
    // MARK: Setting File Managing Properties
    
    static let directoryName: String = "Themes"
    static let constantSettings: [String: Setting] = [:]
    
    let bundledSettingNames: [String]
    @Published var settingNames: [String] = []
    var cachedSettings: [String: Setting] = [:]
    
    
    // MARK: Lifecycle
    
    private init() {
        
        // cache bundled setting names
        self.bundledSettingNames = Bundle.main.urls(forResourcesWithExtension: Setting.fileType.preferredFilenameExtension, subdirectory: Self.directoryName)!
            .map(Self.settingName(from:))
            .sorted(using: .localizedStandard)
        
        // cache user setting names
        self.settingNames = self.listAvailableSettings()
    }
    
    
    // MARK: Public Methods
    
    /// Returns whether the given setting name is a dark theme.
    ///
    /// - Parameter name: The setting name to test.
    /// - Returns: A Boolean value.
    nonisolated static func isDark(name: String) -> Bool {
        
        name.hasSuffix("(Dark)")
    }
    
    
    /// Returns the user's effective default theme name for the specified system appearance.
    ///
    /// - Parameters:
    ///   - inDarkMode: The system appearance to evaluate.
    /// - Returns: The resolved theme name.
    func userDefaultSettingName(inDarkMode: Bool) -> String {
        
        let settingName = UserDefaults.standard[.theme]
        
        if UserDefaults.standard[.pinsThemeAppearance] {
            return settingName
        }
        
        let usesDark = self.usesDarkAppearance(inDarkMode: inDarkMode)
        
        if let equivalentSettingName = self.equivalentSettingName(to: settingName, forDark: usesDark) {
            return equivalentSettingName
        }
        
        if self.settingNames.contains(settingName) {
            return settingName
        }
        
        let defaultSettingName = DefaultSettings.defaults[.theme] as! String
        
        return self.equivalentSettingName(to: defaultSettingName, forDark: usesDark)!
    }
    
    
    /// Returns the setting name for the dark or light variant of the given setting, if available.
    ///
    /// - Parameters:
    ///   - name: The base setting name.
    ///   - forDark: `true` when the dark mode version should be returned.
    /// - Returns: A setting name, or `nil` if none exists.
    func equivalentSettingName(to name: String, forDark: Bool) -> String? {
        
        let baseName = name.replacing(/\ \((Dark|Light)\)$/, with: "", maxReplacements: 1)
        
        let settingName = baseName + " " + (forDark ? "(Dark)" : "(Light)")
        if self.settingNames.contains(settingName) {
            return settingName
        }
        
        if !forDark, self.settingNames.contains(baseName) {
            return baseName
        }
        
        return nil
    }
    
    
    /// Returns whether document windows use the dark appearance under the specified system appearance.
    ///
    /// - Parameters:
    ///   - inDarkMode: The system appearance to evaluate.
    /// - Returns: `true` if document windows should use the dark appearance; otherwise, `false`.
    func usesDarkAppearance(inDarkMode: Bool) -> Bool {
        
        switch UserDefaults.standard[.documentAppearance] {
            case .default: inDarkMode
            case .light: false
            case .dark: true
        }
    }
    
    
    /// Saves the given setting to the user domain.
    ///
    /// - Parameters:
    ///   - setting: The setting to save.
    ///   - name: The name under which to save the setting.
    func save(setting: Setting, name: String) throws {
        
        try self.write(setting: setting, name: name)
        
        self.cachedSettings[name] = setting
        
        let change: SettingChange = self.settingNames.contains(name)
            ? .updated(from: name, to: name)
            : .added(name)
        self.updateSettingList(change: change)
    }
    
    
    /// Creates a new untitled setting.
    ///
    /// - Returns: The name of the created setting.
    @discardableResult func createUntitledSetting() throws -> String {
        
        let name = String(localized: "Untitled", comment: "initial setting filename")
            .appendingUniqueNumber(in: self.settingNames)
        
        try self.save(setting: Setting(), name: name)
        
        return name
    }
    
    
    // MARK: Setting File Managing
    
    /// Builds the list of available settings by considering both user and bundled settings.
    nonisolated func listAvailableSettings() -> [String] {
        
        let userSettingNames = self.userSettingFileURLs
            .map(Self.settingName(from:))
        
        let settingNames = Set(self.bundledSettingNames + userSettingNames)
            .sorted(using: .localizedStandard)
        
        // reset user defaults if not found
        if !settingNames.contains(UserDefaults.standard[.theme]) {
            UserDefaults.standard.restore(key: .theme)
        }
        
        return settingNames
    }
}
