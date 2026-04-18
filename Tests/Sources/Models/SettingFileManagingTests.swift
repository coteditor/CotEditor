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
import SyntaxFormat
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
    
    
    @Test func importLegacyYAMLSyntaxConvertsAndSavesInNativeFormat() throws {
        
        let manager = TestSyntaxManager()
        let name = "Legacy YAML \(UUID().uuidString)"
        
        try self.cleanUp(name: name, manager: manager)
        defer { try? self.cleanUp(name: name, manager: manager) }
        
        let url = try self.createYAMLFile(text: """
            kind: code
            extensions:
              - keyString: legacy
            keywords:
              - beginString: foo
            """)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        
        try manager.importSetting(.url(url), name: name, type: .yaml, overwrite: true)
        
        manager.cachedSettings.removeAll()
        
        let setting = try manager.setting(name: name)
        let savedURL = try #require(manager.urlForUserSetting(name: name))
        
        #expect(setting.kind == .code)
        #expect(setting.fileMap.extensions == ["legacy"])
        #expect(setting.highlights[.keywords] == [.init(begin: "foo")])
        #expect(savedURL.pathExtension == UTType.cotSyntax.preferredFilenameExtension)
    }
    
    
    @Test func renamingWithSurroundingWhitespaceInvalidatesSanitizedCacheEntry() throws {
        
        let manager = TestReplacementManager()
        let sourceName = "Rename Source \(UUID().uuidString)"
        let destinationName = "Rename Destination \(UUID().uuidString)"
        let originalSetting = MultipleReplace(replacements: [.init(findString: "old", replacementString: "new")])
        let staleSetting = MultipleReplace(replacements: [.init(findString: "stale", replacementString: "value")])
        
        try self.cleanUp(name: sourceName, manager: manager)
        try self.cleanUp(name: destinationName, manager: manager)
        defer {
            try? self.cleanUp(name: sourceName, manager: manager)
            try? self.cleanUp(name: destinationName, manager: manager)
        }
        
        try manager.save(setting: originalSetting, name: sourceName)
        manager.cachedSettings[destinationName] = staleSetting
        
        let renamedName = try manager.renameSetting(name: sourceName, to: "  \(destinationName)  ")
        
        #expect(renamedName == destinationName)
        #expect(manager.settingNames.contains(destinationName))
        #expect(!manager.settingNames.contains("  \(destinationName)  "))
        #expect(try manager.setting(name: destinationName) == originalSetting)
    }
    
    
    // MARK: Private Methods
    
    private func createReplacementFile(setting: MultipleReplace, type: UTType) throws -> URL {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        
        return try self.createTemporaryFile(type: type, data: encoder.encode(setting))
    }
    
    
    private func createTSVFile(text: String) throws -> URL {
        
        try self.createTemporaryFile(type: .tabSeparatedText, data: Data(text.utf8))
    }
    
    
    private func createYAMLFile(text: String) throws -> URL {
        
        try self.createTemporaryFile(type: .yaml, data: Data(text.utf8))
    }
    
    
    private func createTemporaryFile(type: UTType, data: Data) throws -> URL {
        
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        let fileURL = directoryURL.appendingPathComponent("Imported", conformingTo: type)
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    
    private func cleanUp<Manager: SettingFileManaging>(name: String, manager: Manager) throws {
        
        if manager.settingNames.contains(name) {
            try manager.removeSetting(name: name)
        }
    }
}


@MainActor private final class TestReplacementManager: SettingFileManaging {
    
    typealias Setting = MultipleReplace
    
    static let directoryName = "TestReplacements-\(UUID().uuidString)"
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


@MainActor private final class TestSyntaxManager: SettingFileManaging {
    
    typealias Setting = Syntax
    
    static let directoryName = "TestSyntaxes-\(UUID().uuidString)"
    static let constantSettings: [String: Setting] = [:]
    
    let reservedNames: [String] = []
    let bundledSettingNames: [String] = []
    var settingNames: [String] = []
    var cachedSettings: [String: Setting] = [:]
    
    
    init() {
        
        self.settingNames = self.listAvailableSettings()
    }
    
    
    nonisolated func listAvailableSettings() -> [String] {
        
        self.userSettingFileURLs
            .map(Self.settingName(from:))
            .sorted(using: .localizedStandard)
    }
}
