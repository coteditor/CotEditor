//
//  PortableSettingsDocument.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-10-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2025-2026 1024jp
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

import SwiftUI
import UniformTypeIdentifiers
import Defaults
import FolderFind
import SemanticVersioning
import URLUtils

extension UTType {
    
    static let cotSettings = UTType(exportedAs: "com.coteditor.CotEditor.settings")
}


struct PortableSettingsDocument: FileDocument, Identifiable, Sendable {
    
    struct Info: Equatable, Codable, Sendable {
        
        static let filename = "Info.plist"
        
        var date: Date
        var version: Version
        var machineName: String?
        var userName: String?
        var sourceID: UUID?
    }
    
    
    struct SettingTypes: OptionSet, Hashable {
        
        var rawValue: Int
        
        static let settings     = Self(rawValue: 1 << 0)
        static let replacements = Self(rawValue: 1 << 1)
        static let syntaxes     = Self(rawValue: 1 << 2)
        static let themes       = Self(rawValue: 1 << 3)
        static let fileScopes   = Self(rawValue: 1 << 4)
        
        static let all: Self = [.settings, .replacements, .syntaxes, .themes, .fileScopes]
    }
    
    
    enum Error: Swift.Error {
        
        case versionMismatch(Version)
    }
    
    
    private enum WrapperKey {
        
        static let defaults = "Defaults.plist"
        static let shortcuts = "Shortcuts.plist"
        static let textKeyBindings = "TextKeyBindings.plist"
        static let keyBindings = "KeyBindings"
        static let replacements = "Replacements"
        static let syntaxes = "Syntaxes"
        static let themes = "Themes"
    }
    
    
    static let readableContentTypes: [UTType] = [.cotSettings]
    
    
    var info: Info
    var id = UUID()
    
    var defaults: [String: PropertyListValue]
    var keyBindings: Data?
    var textKeyBindings: Data?
    var replacements: [String: any Persistable]
    var syntaxes: [String: any Persistable]
    var themes: [String: any Persistable]
    
    
    init(contentsOf fileURL: URL) throws {
        
        assert((try? fileURL.resourceValues(forKeys: [.contentTypeKey]))?.contentType == .cotSettings)
        
        let file = try FileWrapper(url: fileURL, options: [.immediate, .withoutMapping])
        
        try self.init(file: file)
    }
    
    
    init(configuration: ReadConfiguration) throws {
        
        try self.init(file: configuration.file)
    }
    
    
    private init(file: FileWrapper) throws {
        
        guard
            file.isDirectory,
            let fileWrappers = file.fileWrappers,
            let infoData = fileWrappers[Info.filename]?.regularFileContents
        else { throw CocoaError(.fileReadCorruptFile) }
        
        self.info = try PropertyListDecoder().decode(Info.self, from: infoData)
        
        guard
            let defaultsData = fileWrappers[WrapperKey.defaults]?.regularFileContents,
            let plist = try PropertyListSerialization.propertyList(from: defaultsData, format: nil) as? [String: Any]
        else { throw CocoaError(.propertyListReadCorrupt) }
        
        self.defaults = plist.compactMapValues(PropertyListValue.init)
        
        self.keyBindings = fileWrappers[WrapperKey.keyBindings]?.fileWrappers?[WrapperKey.shortcuts]?.regularFileContents
        self.textKeyBindings = fileWrappers[WrapperKey.keyBindings]?.fileWrappers?[WrapperKey.textKeyBindings]?.regularFileContents
        self.replacements = fileWrappers[WrapperKey.replacements]?.fileWrappers?.compactMapValues(\.persistable) ?? [:]
        self.syntaxes = fileWrappers[WrapperKey.syntaxes]?.fileWrappers?.compactMapValues(\.persistable) ?? [:]
        self.themes = fileWrappers[WrapperKey.themes]?.fileWrappers?.compactMapValues(\.persistable) ?? [:]
    }
    
    
    /// Creates the archive package for a document export.
    ///
    /// - Parameter configuration: The framework's export configuration.
    /// - Returns: The archive's file wrapper.
    /// - Throws: An error if encoding the archive metadata or defaults fails.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        
        try self.fileWrapper()
    }
    
    
    /// Creates the file package representing the receiver.
    ///
    /// - Returns: The archive's file wrapper.
    /// - Throws: An error if encoding the archive metadata or defaults fails.
    func fileWrapper() throws -> FileWrapper {
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let infoData = try encoder.encode(self.info)
        let infoWrapper = FileWrapper(regularFileWithContents: infoData)
        
        let defaults = self.defaults.mapValues(\.any)
        let defaultsData = try PropertyListSerialization.data(fromPropertyList: defaults, format: .xml, options: 0)
        let defaultsWrapper = FileWrapper(regularFileWithContents: defaultsData)
        
        var dictionary: [String: FileWrapper] = [
            Info.filename: infoWrapper,
            WrapperKey.defaults: defaultsWrapper,
        ]
        
        var keyBindingWrappers: [String: FileWrapper] = [:]
        if let keyBindings {
            keyBindingWrappers[WrapperKey.shortcuts] = FileWrapper(regularFileWithContents: keyBindings)
        }
        if let textKeyBindings {
            keyBindingWrappers[WrapperKey.textKeyBindings] = FileWrapper(regularFileWithContents: textKeyBindings)
        }
        if !keyBindingWrappers.isEmpty {
            dictionary[WrapperKey.keyBindings] = FileWrapper(directoryWithFileWrappers: keyBindingWrappers)
        }
        
        if !self.syntaxes.isEmpty {
            let childDict = self.syntaxes.mapValues(\.fileWrapper)
            dictionary[WrapperKey.syntaxes] = FileWrapper(directoryWithFileWrappers: childDict)
        }
        
        if !self.themes.isEmpty {
            let childDict = self.themes.mapValues(\.fileWrapper)
            dictionary[WrapperKey.themes] = FileWrapper(directoryWithFileWrappers: childDict)
        }
        
        if !self.replacements.isEmpty {
            let childDict = self.replacements.mapValues(\.fileWrapper)
            dictionary[WrapperKey.replacements] = FileWrapper(directoryWithFileWrappers: childDict)
        }
        
        return FileWrapper(directoryWithFileWrappers: dictionary)
    }
    
    
    /// The mapping of setting types bundled in the receiver.
    var bundledSettings: [SettingTypes: [String]] {
        
        [
            .replacements: self.replacements.keys.sorted(),
            .syntaxes: self.syntaxes.keys.sorted(),
            .themes: self.themes.keys.sorted(),
            .fileScopes: self.fileScopes.sorted(),
        ]
    }
    
    
    /// Verifies that the receiver's version matches the running app's version.
    func checkVersion() throws(Error) {
        
        guard self.info.version == Bundle.main.version else {
            throw .versionMismatch(self.info.version)
        }
    }
    
    
    /// The names of file scopes bundled in the receiver.
    private var fileScopes: [String] {
        
        switch self.defaults[DefaultKeys.folderFindSavedScopes.rawValue] {
            case .dictionary(let dictionary):
                Array(dictionary.keys)
            default:
                []
        }
    }
}


@MainActor extension PortableSettingsDocument {
    
    /// The mapping of exportable setting types.
    static var exportableSettings: [SettingTypes: [String]] {
        
        [
            .replacements: ReplacementManager.shared.userSettingNames,
            .syntaxes: SyntaxManager.shared.userSettingNames,
            .themes: ThemeManager.shared.userSettingNames,
            .fileScopes: Array(UserDefaults.standard[.folderFindSavedScopes].keys),
        ]
    }
    
    
    /// Creates an archive of the selected settings in the current user environment.
    ///
    /// - Parameters:
    ///   - types: The setting types to include.
    ///   - userDefaults: The user defaults store from which settings are exported.
    /// - Throws: An error if encoding the key binding settings fails.
    init(including types: SettingTypes, userDefaults: UserDefaults = .standard) throws {
        
        self.info = Info(date: .now, version: Bundle.main.version!)
        
        var keys: [DefaultKeys] = []
        if types.contains(.settings) {
            keys += DefaultSettings.portableKeys
        }
        if types.contains(.fileScopes) {
            keys.append(.folderFindSavedScopes)
        }
        
        self.defaults = userDefaults.dictionaryWithValues(forKeys: keys.map(\.rawValue))
            .compactMapValues(PropertyListValue.init)
        
        if types.contains(.settings) {
            self.keyBindings = try KeyBindingManager.shared.userSettingsData()
            self.textKeyBindings = try KeyBindingManager.shared.userTextSettingsData()
        }
        
        self.replacements = types.contains(.replacements) ? ReplacementManager.shared.exportSettings() : [:]
        self.syntaxes = types.contains(.syntaxes) ? SyntaxManager.shared.exportSettings() : [:]
        self.themes = types.contains(.themes) ? ThemeManager.shared.exportSettings() : [:]
    }
    
    
    /// Applies settings to the current user environment.
    ///
    /// - Parameters:
    ///   - types: The setting types to apply.
    ///   - userDefaults: The user defaults store to which general settings and file scopes are applied.
    func applySettings(types: SettingTypes = .all, to userDefaults: UserDefaults = .standard) throws {
        
        if types.contains(.replacements) {
            for (name, payload) in self.replacements {
                try ReplacementManager.shared.importSetting(.payload(payload), name: name.deletingPathExtension, overwrite: true)
            }
        }
        
        if types.contains(.syntaxes) {
            for (name, payload) in self.syntaxes {
                try SyntaxManager.shared.importSetting(.payload(payload), name: name.deletingPathExtension, overwrite: true)
            }
        }
        
        if types.contains(.themes) {
            for (name, payload) in self.themes {
                try ThemeManager.shared.importSetting(.payload(payload), name: name.deletingPathExtension, overwrite: true)
            }
        }
        
        if types.contains(.settings) {
            let portableKeys = Set(DefaultSettings.portableKeys.map(\.rawValue))
            let defaults = self.defaults.filter { portableKeys.contains($0.key) }
            
            userDefaults.setValuesForKeys(defaults.mapValues(\.any))
        }
        if types.contains(.settings) {
            if let keyBindings {
                try KeyBindingManager.shared.importSetting(data: keyBindings)
            }
            if let textKeyBindings {
                try KeyBindingManager.shared.importTextSetting(data: textKeyBindings)
            }
        }
        
        if types.contains(.fileScopes),
           let fileScopes = self.defaults[DefaultKeys.folderFindSavedScopes]?.any as? [String: Data]
        {
            // drop undecodable scopes, which would be invisible in the UI while still reserving their names
            let decoder = JSONDecoder()
            let validScopes = fileScopes.filter { (try? decoder.decode(FileScope.self, from: $0.value)) != nil }
            
            userDefaults[.folderFindSavedScopes].merge(validScopes) { _, imported in imported }
        }
    }
}


extension PortableSettingsDocument.Info {
    
    /// Reads the metadata from an archive's information file.
    ///
    /// - Parameter fileURL: The URL of the archive's Info.plist file.
    /// - Throws: An error if reading or decoding the metadata fails.
    init(contentsOf fileURL: URL) throws {
        
        self = try PropertyListDecoder().decode(Self.self, from: Data(contentsOf: fileURL))
    }
}


private extension FileWrapper {
    
    /// The persisted representation of the receiver, if supported for settings archives.
    var persistable: any Persistable? {
        
        if self.isDirectory {
            self
        } else if self.isRegularFile {
            self.regularFileContents
        } else {
            nil
        }
    }
}
