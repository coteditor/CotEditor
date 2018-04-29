//
//  ReplacementManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2018 1024jp
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

final class ReplacementManager: SettingFileManager {
    
    typealias Setting = ReplacementSet
    
    
    // MARK: Public Properties
    
    static let shared = ReplacementManager()
    
    
    // MARK: Private Properties
    
    private var _settingNames: [String] = []
    private var settings: [String: Setting] = [:]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        super.init()
        
        self.loadUserSettings()
    }
    
    
    
    // MARK: Setting File Manager Methods
    
    /// directory name in both Application Support and bundled Resources
    override var directoryName: String {
        
        return "Replacements"
    }
    
    
    /// path extensions for user setting file
    override var filePathExtensions: [String] {
        
        return DocumentType.replacement.extensions
    }
    
    
    /// name of setting file type
    override var settingFileType: SettingFileType {
        
        return .replacement
    }
    
    
    /// list of names of setting file name (without extension)
    override var settingNames: [String] {
        
        return self._settingNames
    }
    
    
    /// list of names of setting file name which are bundled (without extension)
    override var bundledSettingNames: [String] {
        
        return []
    }
    
    
    
    // MARK: Public Methods
    
    ///
    func setting(name: String) -> Setting? {
        
        return self.settings[name]
    }
    
    
    /// delete theme file corresponding to the theme name
    override func removeSetting(name settingName: String) throws {
        
        try super.removeSetting(name: settingName)
        
        self.updateCache()
    }
    
    
    /// save
    func save(setting: Setting, name settingName: String, completionHandler: (() -> Void)? = nil) throws {  // @escaping
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if #available(macOS 10.13, *) {
            encoder.outputFormatting.formUnion(.sortedKeys)
        }
        
        let data = try encoder.encode(setting)
        let fileURL = self.preparedURLForUserSetting(name: settingName)
        
        try data.write(to: fileURL, options: .atomic)
        
        self.updateCache {
            completionHandler?()
        }
    }
    
    
    /// rename setting
    override func renameSetting(name: String, to newName: String) throws {
        
        try super.renameSetting(name: name, to: newName)
        
        self.updateCache { [weak self] in
            self?.notifySettingUpdate(oldName: name, newName: newName)
        }
    }
    
    
    /// create a new untitled setting
    func createUntitledSetting(completionHandler: ((_ settingName: String) -> Void)? = nil) throws {  // @escaping
        
        let name = self.savableSettingName(for: NSLocalizedString("Untitled", comment: ""))
        
        try self.save(setting: ReplacementSet(), name: name) {
            completionHandler?(name)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// load settings in the user domain
    override func loadUserSettings() {
        
        // load settings if exists
        self.settings = self.userSettingFileURLs.reduce(into: [:]) { (settings, url) in
            let name = self.settingName(from: url)
            
            settings[name] = try? self.loadSetting(at: url)
        }
        self._settingNames = self.settings.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
    
    
    /// load setting from the file at given URL
    private func loadSetting(at fileURL: URL) throws -> Setting {
        
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: fileURL)
        
        return try decoder.decode(ReplacementSet.self, from: data)
    }
    
}
