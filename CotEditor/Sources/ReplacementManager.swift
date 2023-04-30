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
//  © 2017-2023 1024jp
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

final class ReplacementManager: SettingFileManaging {
    
    typealias Setting = MultipleReplace
    
    
    // MARK: Public Properties
    
    static let shared = ReplacementManager()
    
    
    // MARK: Setting File Managing Properties
    
    let didUpdateSetting: PassthroughSubject<SettingChange, Never> = .init()
    
    static let directoryName: String = "Replacements"
    let fileType: UTType = .cotReplacement
    
    @Published var settingNames: [String] = []
    let bundledSettingNames: [String] = []
    var cachedSettings: [String: Setting] = [:]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private init() {
        
        self.loadUserSettings()
    }
    
    
    
    // MARK: Public Methods
    
    /// save setting file
    func save(setting: Setting, name: String) throws {
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(setting)
        let fileURL = self.preparedURLForUserSetting(name: name)
        
        try data.write(to: fileURL, options: .atomic)
        
        self.cachedSettings[name] = setting
        
        let change: SettingChange = self.settingNames.contains(name)
            ? .updated(from: name, to: name)
            : .added(name)
        self.updateSettingList(change: change)
    }
    
    
    /// create a new untitled setting
    ///
    /// - Returns: The setting name created.
    @discardableResult
    func createUntitledSetting() throws -> String {
        
        let name = self.savableSettingName(for: String(localized: "Untitled"))
        
        try self.save(setting: Setting(), name: name)
        
        return name
    }
    
    
    
    // MARK: Setting File Managing
    
    /// Load setting from the file at the given URL.
    func loadSetting(at fileURL: URL) throws -> Setting {
        
        let decoder = JSONDecoder()
        let data = try Data(contentsOf: fileURL)
        
        return try decoder.decode(Setting.self, from: data)
    }
    
    
    /// Load settings in the user domain.
    func loadUserSettings() {
        
        // get user setting names if exists
        self.settingNames = self.userSettingFileURLs
            .filter { (try? self.loadSetting(at: $0)) != nil }  // just try loading but not store
            .map { self.settingName(from: $0) }
            .sorted(options: [.localized, .caseInsensitive])
    }
}
