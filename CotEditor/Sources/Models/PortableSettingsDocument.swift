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
//  © 2025−2026 1024jp
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
import SemanticVersioning

extension UTType {
    
    static let cotSettings = UTType(exportedAs: "com.coteditor.CotEditor.settings")
}


struct PortableSettingsDocument: FileDocument {
    
    struct Info: Equatable, Codable {
        
        var date: Date
        var version: Version
    }
    
    
    struct SettingTypes: OptionSet, Hashable {
        
        var rawValue: Int
        
        static let settings     = Self(rawValue: 1 << 0)
        static let replacements = Self(rawValue: 1 << 1)
        static let syntaxes     = Self(rawValue: 1 << 2)
        static let themes       = Self(rawValue: 1 << 3)
        
        static let all: Self = [.settings, .replacements, .syntaxes, .themes]
    }
    
    
    enum Error: Swift.Error {
        
        case versionMismatch(Version)
    }
    
    
    private enum WrapperKey {
        
        static let info = "Info.plist"
        static let defaults = "Defaults.plist"
        static let shortcuts = "Shortcuts.plist"
        static let applicationSupport = "Application Support"
        static let keyBindings = "KeyBindings"
        static let replacements = "Replacements"
        static let syntaxes = "Syntaxes"
        static let themes = "Themes"
    }
    
    
    static let readableContentTypes: [UTType] = [.cotSettings]
    
    
    var info: Info
    
    var defaults: [String: PropertyListValue]
    var keyBindings: Data?
    var replacements: [String: any Persistable]
    var syntaxes: [String: any Persistable]
    var themes: [String: any Persistable]
    
    
    init(contentsOf fileURL: URL) throws {
        
        assert((try? fileURL.resourceValues(forKeys: [.contentTypeKey]))?.contentType == .cotSettings)
        
        let file = try FileWrapper(url: fileURL)
        
        try self.init(file: file)
    }
    
    
    init(configuration: ReadConfiguration) throws {
        
        try self.init(file: configuration.file)
    }
    
    
    private init(file: FileWrapper) throws {
        
        guard
            file.isDirectory,
            let fileWrappers = file.fileWrappers,
            let infoData = fileWrappers[WrapperKey.info]?.regularFileContents
        else { throw CocoaError(.fileReadCorruptFile) }
        
        self.info = try PropertyListDecoder().decode(Info.self, from: infoData)
        
        guard
            let defaultsData = fileWrappers[WrapperKey.defaults]?.regularFileContents,
            let plist = try PropertyListSerialization.propertyList(from: defaultsData, format: nil) as? [String: Any]
        else { throw CocoaError(.propertyListReadCorrupt) }
        
        self.defaults = plist.mapValues(PropertyListValue.init)
        
        self.keyBindings = fileWrappers[WrapperKey.keyBindings]?.fileWrappers?[WrapperKey.shortcuts]?.regularFileContents
        self.replacements = fileWrappers[WrapperKey.replacements]?.fileWrappers?.compactMapValues(\.regularFileContents) ?? [:]
        self.syntaxes = fileWrappers[WrapperKey.syntaxes]?.fileWrappers?.compactMapValues(\.regularFileContents) ?? [:]
        self.themes = fileWrappers[WrapperKey.themes]?.fileWrappers?.compactMapValues(\.regularFileContents) ?? [:]
    }
    
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let infoData = try encoder.encode(self.info)
        let infoWrapper = FileWrapper(regularFileWithContents: infoData)
        
        let defaults = self.defaults.mapValues(\.any)
        let defaultsData = try PropertyListSerialization.data(fromPropertyList: defaults, format: .xml, options: 0)
        let defaultsWrapper = FileWrapper(regularFileWithContents: defaultsData)
        
        var dictionary: [String: FileWrapper] = [
            WrapperKey.info: infoWrapper,
            WrapperKey.defaults: defaultsWrapper,
        ]
        
        if let keyBindings {
            dictionary[WrapperKey.keyBindings] = FileWrapper(directoryWithFileWrappers: [
                WrapperKey.shortcuts: FileWrapper(regularFileWithContents: keyBindings),
            ])
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
        ]
    }
    
    
    /// Verifies that the receiver's version matches the running app's version.
    func checkVersion() throws(Error) {
        
        guard self.info.version == Bundle.main.version else {
            throw .versionMismatch(self.info.version)
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
        ]
    }
    
    
    init(including types: SettingTypes) throws {
        
        self.info = Info(date: .now, version: Bundle.main.version!)
        
        if types.contains(.settings) {
            let keys = DefaultSettings.portableKeys.map(\.rawValue)
            self.defaults = UserDefaults.standard.dictionaryWithValues(forKeys: keys)
                .mapValues(PropertyListValue.init)
            self.keyBindings = try KeyBindingManager.shared.userSettingsData()
        } else {
            self.defaults = [:]
        }
        
        self.replacements = types.contains(.replacements) ? ReplacementManager.shared.exportSettings() : [:]
        self.syntaxes = types.contains(.syntaxes) ? SyntaxManager.shared.exportSettings() : [:]
        self.themes = types.contains(.themes) ? ThemeManager.shared.exportSettings() : [:]
    }
    
    
    /// Applies settings to the current user environment.
    func applySettings(types: SettingTypes = .all) throws {
        
        if types.contains(.settings), !self.defaults.isEmpty {
            UserDefaults.standard.setValuesForKeys(self.defaults.mapValues(\.any))
        }
        if types.contains(.settings), let keyBindings {
            try KeyBindingManager.shared.importSetting(data: keyBindings)
        }
        
        if types.contains(.replacements) {
            for (name, data) in self.replacements {
                try ReplacementManager.shared.importSetting(payload: data, name: name, overwrite: true)
            }
        }
        
        if types.contains(.syntaxes) {
            for (name, data) in self.syntaxes {
                try SyntaxManager.shared.importSetting(payload: data, name: name, overwrite: true)
            }
        }
        
        if types.contains(.themes) {
            for (name, data) in self.themes {
                try ThemeManager.shared.importSetting(payload: data, name: name, overwrite: true)
            }
        }
    }
}
