//
//  PortableSettingsDocumentTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-04-18.
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
import AppKit.NSEvent
import UniformTypeIdentifiers
import Testing
import Defaults
import FolderFind
import SemanticVersioning
import Shortcut
import SyntaxFormat
@testable import CotEditor

@MainActor struct PortableSettingsDocumentTests {
    
    /// Verifies that archives created before source metadata was added remain readable.
    ///
    /// - Throws: An error if creating or reading the archive fails.
    @Test func settingsArchiveWithoutSourceMetadataIsReadable() throws {
        
        let archiveURL = try self.createSettingsArchive()
        defer { try? FileManager.default.removeItem(at: archiveURL.deletingLastPathComponent()) }
        
        let document = try PortableSettingsDocument(contentsOf: archiveURL)
        
        #expect(document.info.date == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(document.info.version == Version(7, 0, 0))
        #expect(document.info.machineName == nil)
        #expect(document.info.userName == nil)
        #expect(document.info.sourceID == nil)
        let info = try PortableSettingsDocument.Info(contentsOf: archiveURL.appending(component: PortableSettingsDocument.Info.filename))
        #expect(info == document.info)
    }
    
    
    /// Verifies that an archive preserves the source metadata stored in its property list.
    ///
    /// - Throws: An error if encoding, writing, or reading the archive fails.
    @Test func settingsArchivePreservesSourceMetadata() throws {
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        let archiveURL = directoryURL.appending(component: "Settings", directoryHint: .isDirectory).appendingPathExtension(for: .cotSettings)
        let info = PortableSettingsDocument.Info(date: Date(timeIntervalSince1970: 1_700_000_000), version: Version(7, 0, 0),
                                                 machineName: "テスト用Mac", userName: "tester", sourceID: UUID())
        var document = try PortableSettingsDocument(including: [])
        document.info = info
        let file = try document.fileWrapper()
        let infoData = try #require(file.fileWrappers?[PortableSettingsDocument.Info.filename]?.regularFileContents)
        let plist = try #require(PropertyListSerialization.propertyList(from: infoData, format: nil) as? [String: Any])
        
        #expect(plist["machineName"] as? String == info.machineName)
        #expect(plist["userName"] as? String == info.userName)
        #expect(plist["sourceID"] as? String == info.sourceID?.uuidString)
        
        try file.write(to: archiveURL, options: .atomic, originalContentsURL: nil)
        #expect(try PortableSettingsDocument(contentsOf: archiveURL).info == info)
    }
    
    
    /// Verifies that manual exports omit the source environment.
    ///
    /// - Throws: An error if creating the archive fails.
    @Test func exportedArchiveInfoOmitsSource() throws {
        
        let document = try PortableSettingsDocument(including: [])
        
        #expect(document.info.machineName == nil)
        #expect(document.info.userName == nil)
        #expect(document.info.sourceID == nil)
    }
    
    
    /// Tests exporting shared text customizations only when general settings are selected.
    ///
    /// - Parameter includesSettings: Whether general settings are included in the export.
    /// - Throws: If configuring, exporting, or decoding the customizations fails.
    @Test(arguments: [false, true])
    func exportsTextKeyBindings(includesSettings: Bool) throws {
        
        let manager = KeyBindingManager.shared
        let previous = manager.textKeyBindings
        defer { manager.textKeyBindings = previous }
        var bindings = TextKeyBindingMap()
        try bindings.setShortcuts([Shortcut(.home, modifiers: [])], for: .moveToLeftEndOfLine)
        try bindings.setShortcuts([], for: .deleteForward)
        manager.textKeyBindings = bindings
        let document = try PortableSettingsDocument(including: includesSettings ? .settings : [])
        
        if includesSettings {
            let data = try #require(document.textKeyBindings)
            #expect(try PropertyListDecoder().decode(TextKeyBindingMap.self, from: data) == bindings)
        } else {
            #expect(document.textKeyBindings == nil)
        }
    }
    
    
    /// Tests importing text payloads only with general settings, preserving current bindings after invalid input.
    ///
    /// - Parameter includesSettings: Whether general settings are selected for import.
    /// - Throws: If preparing the document or defaults store fails.
    @Test(arguments: [false, true])
    func importsTextKeyBindingsOnlyWithSettings(includesSettings: Bool) throws {
        
        let suiteName = "PortableSettingsDocumentTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let previous = KeyBindingManager.shared.textKeyBindings
        var document = try PortableSettingsDocument(including: [])
        document.textKeyBindings = Data("invalid".utf8)
        
        if includesSettings {
            #expect(throws: (any Error).self) { try document.applySettings(types: .settings, to: defaults) }
        } else {
            try document.applySettings(types: .fileScopes, to: defaults)
        }
        #expect(KeyBindingManager.shared.textKeyBindings == previous)
    }
    
    
    @Test(arguments: [false, true])
    func settingsArchiveRoundTripKeepsCustomSyntaxPackage(removesSource: Bool) throws {
        
        let archiveURL = try self.createSettingsArchive()
        defer { try? FileManager.default.removeItem(at: archiveURL.deletingLastPathComponent()) }
        
        let document = try PortableSettingsDocument(contentsOf: archiveURL)
        if removesSource {
            try FileManager.default.removeItem(at: archiveURL)
        }
        let payload = try #require(document.syntaxes["Sample.cotsyntax"])
        let fileWrapper = try #require(payload as? FileWrapper)
        let syntax = try Syntax(payload: fileWrapper, type: .cotSyntax)
        
        #expect(document.bundledSettings[.syntaxes] == ["Sample.cotsyntax"])
        #expect(fileWrapper.fileWrappers?["Info.json"]?.regularFileContents != nil)
        #expect(syntax.kind == .code)
        #expect(syntax.fileMap.extensions == ["sample"])
    }


    @Test func defaultWindowSizeIsPortable() {

        let keys = DefaultSettings.portableKeys.map(\.rawValue)

        #expect(keys.contains(DefaultKeys.windowWidth.rawValue))
        #expect(keys.contains(DefaultKeys.windowHeight.rawValue))
    }
    
    
    @Test(arguments: [false, true])
    func appliesOnlySelectedDefaults(fileScopes: Bool) throws {
        
        let suiteName = "PortableSettingsDocumentTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        
        let windowWidthKey = DefaultKeys.windowWidth.rawValue
        let fileScopesKey = DefaultKeys.folderFindSavedScopes.rawValue
        let currentWindowWidth = 320.0
        let importedWindowWidth = 640.0
        let currentData = try self.scopeData(value: "current")
        let duplicateCurrentData = try self.scopeData(value: "duplicate-current")
        let duplicateImportedData = try self.scopeData(value: "duplicate-imported")
        let importedData = try self.scopeData(value: "imported")
        let currentFileScopes = [
            "Current": currentData,
            "Duplicate": duplicateCurrentData,
        ]
        let importedFileScopes = [
            "Duplicate": duplicateImportedData,
            "Imported": importedData,
        ]
        let mergedFileScopes = [
            "Current": currentData,
            "Duplicate": duplicateImportedData,
            "Imported": importedData,
        ]
        
        userDefaults.set(currentWindowWidth, forKey: windowWidthKey)
        userDefaults.set(currentFileScopes, forKey: fileScopesKey)
        
        var document = try PortableSettingsDocument(including: [])
        document.defaults = [
            windowWidthKey: try #require(PropertyListValue(importedWindowWidth)),
            fileScopesKey: try #require(PropertyListValue(importedFileScopes)),
        ]
        
        try document.applySettings(types: fileScopes ? .fileScopes : .settings, to: userDefaults)
        
        #expect(userDefaults.double(forKey: windowWidthKey) == (fileScopes ? currentWindowWidth : importedWindowWidth))
        #expect(userDefaults.object(forKey: fileScopesKey) as? [String: Data] == (fileScopes ? mergedFileScopes : currentFileScopes))
    }
    
    
    @Test func emptyFileScopesKeepExistingScopes() throws {
        
        let suiteName = "PortableSettingsDocumentTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        
        let fileScopesKey = DefaultKeys.folderFindSavedScopes.rawValue
        let currentFileScopes = ["Current": Data([0x01])]
        
        userDefaults.set(currentFileScopes, forKey: fileScopesKey)
        
        var document = try PortableSettingsDocument(including: [])
        document.defaults = [fileScopesKey: try #require(PropertyListValue([String: Data]()))]
        
        try document.applySettings(types: .fileScopes, to: userDefaults)
        
        #expect(userDefaults.object(forKey: fileScopesKey) as? [String: Data] == currentFileScopes)
    }
    
    
    @Test func undecodableFileScopesAreNotImported() throws {
        
        let suiteName = "PortableSettingsDocumentTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        
        let fileScopesKey = DefaultKeys.folderFindSavedScopes.rawValue
        let validData = try self.scopeData(value: "valid")
        let fileScopes = try #require(PropertyListValue([
            "Valid": validData,
            "Broken": Data([0x01]),
        ]))
        
        var document = try PortableSettingsDocument(including: [])
        document.defaults = [fileScopesKey: fileScopes]
        
        try document.applySettings(types: .fileScopes, to: userDefaults)
        
        #expect(userDefaults.object(forKey: fileScopesKey) as? [String: Data] == ["Valid": validData])
    }
    
    
    // MARK: Private Methods
    
    /// Creates a settings archive with a custom syntax package for a test.
    ///
    /// - Returns: The URL of the created archive.
    /// - Throws: An error if encoding or writing the archive fails.
    private func createSettingsArchive() throws -> URL {
        
        let infoData = try PropertyListSerialization.data(fromPropertyList: [
            "date": Date(timeIntervalSince1970: 1_700_000_000),
            "version": "7.0.0",
        ], format: .xml, options: 0)
        
        let defaultsData = try PropertyListSerialization.data(fromPropertyList: [:], format: .xml, options: 0)
        let syntaxInfoData = Data("""
            {
              "kind" : "code",
              "fileMap" : {
                "extensions" : [
                  "sample"
                ]
              }
            }
            """.utf8)
        
        let archive = FileWrapper(directoryWithFileWrappers: [
            "Info.plist": FileWrapper(regularFileWithContents: infoData),
            "Defaults.plist": FileWrapper(regularFileWithContents: defaultsData),
            "Syntaxes": FileWrapper(directoryWithFileWrappers: [
                "Sample.cotsyntax": FileWrapper(directoryWithFileWrappers: [
                    "Info.json": FileWrapper(regularFileWithContents: syntaxInfoData),
                ]),
            ]),
        ])
        
        let directoryURL = try FileManager.default.makeTemporaryDirectory()
        let archiveURL = directoryURL.appendingPathComponent("Settings").appendingPathExtension("cotsettings")
        
        try archive.write(to: archiveURL, options: .atomic, originalContentsURL: nil)
        
        return archiveURL
    }
    
    
    /// Creates encoded file scope data for a test.
    ///
    /// - Parameter value: The rule value to embed.
    /// - Returns: The JSON-encoded file scope data.
    /// - Throws: An error if the encoding fails.
    private func scopeData(value: String) throws -> Data {
        
        try JSONEncoder().encode(FileScope(rules: [FileScope.Rule(target: .filename, comparison: .contains, value: value)]))
    }
}
