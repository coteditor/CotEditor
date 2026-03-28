//
//  SettingFileManagingTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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
import UniformTypeIdentifiers
import Testing
import TextFind
@testable import CotEditor

@MainActor struct SettingFileManagingTests {
    
    @Test func overwriteImportedNativeSettingReplacesExistingFile() throws {
        
        let manager = TestReplacementManager()
        let name = "Native Import \(UUID().uuidString)"
        
        try self.cleanUp(name: name, manager: manager)
        defer { try? self.cleanUp(name: name, manager: manager) }
        
        try manager.save(setting: MultipleReplace(replacements: [.init(findString: "before", replacementString: "old")]), name: name)
        
        let importedSetting = MultipleReplace(replacements: [.init(findString: "after", replacementString: "new")])
        let url = try self.createReplacementFile(setting: importedSetting, type: .cotReplacement)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        
        try manager.importSetting(.url(url), name: name, type: .cotReplacement, overwrite: true)
        
        manager.cachedSettings.removeAll()
        #expect(try manager.setting(name: name) == importedSetting)
    }
    
    
    @Test func overwriteImportedTSVAfterConfirmationKeepsSourceType() throws {
        
        let manager = TestReplacementManager()
        let name = "TSV Import 日本語 \(UUID().uuidString)"
        
        try self.cleanUp(name: name, manager: manager)
        defer { try? self.cleanUp(name: name, manager: manager) }
        
        try manager.save(setting: MultipleReplace(replacements: [.init(findString: "cat", replacementString: "dog")]), name: name)
        
        let importedSetting = MultipleReplace(replacements: [.init(findString: "hello", replacementString: "こんにちは")])
        let url = try self.createTSVFile(text: "hello\tこんにちは\n")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        
        let error = #expect(throws: ImportDuplicationError.self) {
            try manager.importSetting(.url(url), name: name, type: .tabSeparatedText, overwrite: false)
        }
        
        let duplicationError = try #require(error)
        #expect(duplicationError.type == UTType.tabSeparatedText)
        
        try manager.importSetting(duplicationError.item, name: duplicationError.name, type: duplicationError.type, overwrite: true)
        
        manager.cachedSettings.removeAll()
        #expect(try manager.setting(name: name) == importedSetting)
    }
    
    
    // MARK: Private Methods
    
    private func createReplacementFile(setting: MultipleReplace, type: UTType) throws -> URL {
        
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        let fileURL = directoryURL.appendingPathComponent("Imported", conformingTo: type)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(setting).write(to: fileURL)
        
        return fileURL
    }
    
    
    private func createTSVFile(text: String) throws -> URL {
        
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        let fileURL = directoryURL.appendingPathComponent("Imported", conformingTo: UTType.tabSeparatedText)
        try Data(text.utf8).write(to: fileURL)
        
        return fileURL
    }
    
    
    private func cleanUp(name: String, manager: TestReplacementManager) throws {
        
        if manager.settingNames.contains(name) {
            try manager.removeSetting(name: name)
        }
    }
}


@MainActor private final class TestReplacementManager: SettingFileManaging {
    
    typealias Setting = MultipleReplace
    
    static let directoryName = "Replacements"
    static let userDirectoryName: String? = "Tests/Replacements-\(UUID().uuidString)"
    static let constantSettings: [String: Setting] = [:]
    
    let reservedNames: [String] = []
    let bundledSettingNames: [String] = []
    var settingNames: [String] = []
    var cachedSettings: [String: Setting] = [:]
    
    
    init() {
        
        self.settingNames = self.listAvailableSettings()
    }
    
    
    func save(setting: Setting, name: String) throws {
        
        try self.write(setting: setting, name: name)
        
        self.cachedSettings[name] = setting
        
        let change: SettingChange = self.settingNames.contains(name)
            ? .updated(from: name, to: name)
            : .added(name)
        self.updateSettingList(change: change)
    }
    
    
    nonisolated func listAvailableSettings() -> [String] {
        
        self.userSettingFileURLs
            .map(Self.settingName(from:))
            .sorted(using: .localizedStandard)
    }
}
