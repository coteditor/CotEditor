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
//  © 2014-2024 1024jp
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

import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor @objc protocol ThemeChanging: AnyObject {
    
    func changeTheme(_ sender: NSMenuItem)
}



// MARK: -

final class ThemeManager: SettingFileManaging {
    
    typealias Setting = Theme
    
    
    // MARK: Public Properties
    
    static let shared = ThemeManager()
    
    
    // MARK: Setting File Managing Properties
    
    let didUpdateSetting: PassthroughSubject<SettingChange, Never> = .init()
    
    static let directoryName: String = "Themes"
    let fileType: UTType = .cotTheme
    let reservedNames: [String] = []
    
    @Published var settingNames: [String] = []
    private(set) var bundledSettingNames: [String] = []
    var cachedSettings: [String: Setting] = [:]
    
    
    
    // MARK: Lifecycle
    
    private init() {
        
        // cache bundled setting names
        self.bundledSettingNames = Bundle.main.urls(forResourcesWithExtension: self.fileType.preferredFilenameExtension, subdirectory: Self.directoryName)!
            .map { self.settingName(from: $0) }
            .sorted(options: [.localized, .caseInsensitive])
        
        // cache user setting names
        self.loadUserSettings()
    }
    
    
    
    // MARK: Public Methods
    
    /// The default setting by taking the appearance state into consideration.
    var defaultSettingName: String {
        
        let defaultSettingName = DefaultSettings.defaults[.theme] as! String
        let forDark = self.usesDarkAppearance
        
        return self.equivalentSettingName(to: defaultSettingName, forDark: forDark)!
    }
    
    
    /// The user default setting by taking the appearance state into consideration.
    var userDefaultSettingName: String {
        
        let settingName = UserDefaults.standard[.theme]
        
        if UserDefaults.standard[.pinsThemeAppearance] {
            return settingName
        }
        
        if let equivalentSettingName = self.equivalentSettingName(to: settingName, forDark: self.usesDarkAppearance) {
            return equivalentSettingName
        }
        
        guard self.settingNames.contains(settingName) else { return self.defaultSettingName }
        
        return settingName
    }
    
    
    /// Whether document windows currently use the dark appearance.
    var usesDarkAppearance: Bool {
        
        switch UserDefaults.standard[.documentAppearance] {
            case .default: NSApp.effectiveAppearance.isDark
            case .light: false
            case .dark: true
        }
    }
    
    
    /// Saves the given setting file.
    ///
    /// - Parameters:
    ///   - setting: The setting to save.
    ///   - name: The name of the setting to save.
    func save(setting: Setting, name: String) throws {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(setting)
        let fileURL = self.preparedURLForUserSetting(name: name)
        
        try FileManager.default.createIntermediateDirectories(to: fileURL)
        try data.write(to: fileURL)
        
        self.cachedSettings[name] = setting
        
        let change: SettingChange = self.settingNames.contains(name)
            ? .updated(from: name, to: name)
            : .added(name)
        self.updateSettingList(change: change)
    }
    
    
    /// Creates a new untitled setting.
    ///
    /// - Returns: The setting name created.
    @discardableResult
    func createUntitledSetting() throws -> String {
        
        let name = self.savableSettingName(for: String(localized: "Untitled", comment: "initial setting file name"))
        
        try self.save(setting: Setting(), name: name)
        
        return name
    }
    
    
    /// Returns whether given setting name is dark theme.
    ///
    /// - Parameter name: The setting name to test.
    /// - Returns: A bool value.
    func isDark(name: String) -> Bool {
        
        name.hasSuffix("(Dark)")
    }
    
    
    /// Returns the setting name of dark/light version of given one if any exists.
    ///
    /// - Parameters:
    ///   - name: The base setting name.
    ///   - forDark: `true` when the dark mode version should be returned.
    /// - Returns: A setting name or `nil`, if not exists.
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
    
    
    
    // MARK: Setting File Managing
    
    /// Loads the setting from the file at the given URL.
    func loadSetting(at fileURL: URL) throws -> Setting {
        
        try Theme(contentsOf: fileURL)
    }
    
    
    /// Loads the settings in the user domain.
    func loadUserSettings() {
        
        // get user setting names if exists
        let userSettingNames = self.userSettingFileURLs
            .map { self.settingName(from: $0) }
        
        self.settingNames = (self.bundledSettingNames + userSettingNames).uniqued
            .sorted(options: [.localized, .caseInsensitive])
        
        // reset user default if not found
        if !self.settingNames.contains(UserDefaults.standard[.theme]) {
            UserDefaults.standard.restore(key: .theme)
        }
    }
}
