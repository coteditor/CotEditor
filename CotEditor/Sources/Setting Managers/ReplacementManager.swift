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
import Observation
import TextFind
import UniformTypeIdentifiers
import URLUtils

@MainActor final class ReplacementManager: SettingFileManaging {
    
    typealias Setting = MultipleReplace
    
    
    // MARK: Public Properties
    
    static let shared = ReplacementManager()
    
    
    // MARK: Setting File Managing Properties
    
    static let directoryName: String = "Replacements"
    static let fileType: UTType = .cotReplacement
    let reservedNames: [String] = []
    
    let bundledSettingNames: [String] = []
    @Published var settingNames: [String] = []
    var cachedSettings: [String: Setting] = [:]
    
    
    // MARK: Lifecycle
    
    private init() {
        
        self.settingNames = self.loadUserSettings()
    }
    
    
    // MARK: Public Methods
    
    /// Saves the given setting file.
    ///
    /// - Parameters:
    ///   - setting: The setting to save.
    ///   - name: The name of the setting to save.
    func save(setting: Setting, name: String) throws {
        
        let data = try Self.data(from: setting)
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
    @discardableResult func createUntitledSetting() throws -> String {
        
        let name = String(localized: "Untitled", comment: "initial setting filename")
            .appendingUniqueNumber(in: self.settingNames)
        
        try self.save(setting: Setting(), name: name)
        
        return name
    }
    
    
    // MARK: Setting File Managing
    
    /// Encodes the provided setting into data to store.
    nonisolated static func data(from setting: Setting) throws -> Data {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(setting)
    }
    
    
    /// Loads the setting from the data.
    nonisolated static func loadSetting(from data: Data, type: UTType) throws -> sending Setting {
        
        if type.conforms(to: Self.fileType) {
            try JSONDecoder().decode(Setting.self, from: data)
        } else if type.conforms(to: .tabSeparatedText), let string = String(data: data, encoding: .utf8) {
            try MultipleReplace(tabSeparatedText: string)
        } else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
    }
    
    
    /// Loads setting lineup in the user domain.
    nonisolated func loadUserSettings() -> [String] {
        
        self.userSettingFileURLs
            .filter { (try? self.loadSetting(at: $0)) != nil }  // just try loading but not store
            .map(Self.settingName(from:))
            .sorted(using: .localizedStandard)
    }
}
