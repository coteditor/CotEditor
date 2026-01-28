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
//  © 2017-2026 1024jp
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
import Combine
import TextFind
import URLUtils

@MainActor final class ReplacementManager: SettingFileManaging {
    
    typealias Setting = MultipleReplace
    
    
    // MARK: Public Properties
    
    static let shared = ReplacementManager()
    
    
    // MARK: Setting File Managing Properties
    
    static let directoryName: String = "Replacements"
    static let constantSettings: [String: Setting] = [:]
    let reservedNames: [String] = []
    
    let bundledSettingNames: [String] = []
    @Published var settingNames: [String] = []
    var cachedSettings: [String: Setting] = [:]
    
    
    // MARK: Lifecycle
    
    private init() {
        
        self.settingNames = self.listAvailableSettings()
    }
    
    
    // MARK: Public Methods
    
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
        
        self.userSettingFileURLs
            .map(Self.settingName(from:))
            .sorted(using: .localizedStandard)
    }
}
