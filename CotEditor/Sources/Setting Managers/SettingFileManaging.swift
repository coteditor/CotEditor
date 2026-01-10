//
//  SettingFileManaging.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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
import AppKit.NSApplication
import URLUtils

typealias SettingChange = ItemChange<String>


struct SettingState: Equatable, Hashable {
    
    var name: String
    var isBundled: Bool
    var isCustomized: Bool
    
    var isRestorable: Bool  { self.isBundled && self.isCustomized }
}


extension SettingState: Identifiable {
    
    var id: String { self.name }
}


extension NSNotification.Name {
    
    /// A notification posted when a setting file is updated, with the new and/or previous setting names.
    static let didUpdateSettingNotification = Notification.Name("SettingFileManaging.didUpdateSettingNotification")
}


extension URL {
    
    /// Returns the URL for the given subdirectory in the user's Application Support directory.
    ///
    /// - Parameter subDirectory: The name of the subdirectory in Application Support.
    /// - Returns: A directory URL.
    static func applicationSupportDirectory(component subDirectory: String) -> URL {
        
        .applicationSupportDirectory
        .appending(component: "CotEditor", directoryHint: .isDirectory)
        .appending(component: subDirectory, directoryHint: .isDirectory)
    }
}


// MARK: -

@MainActor protocol SettingFileManaging: AnyObject, Sendable {
    
    associatedtype Setting: Equatable, Sendable
    associatedtype PersistentSetting: Persistable
    
    
    /// The directory name used in both Application Support and the app bundle’s Resources.
    nonisolated static var directoryName: String { get }
    
    /// The UTType for user setting files.
    nonisolated static var fileType: UTType { get }
    
    /// The list of reserved names that cannot be used for user settings.
    nonisolated var reservedNames: [String] { get }
    
    /// The list of bundled setting names (without extensions).
    nonisolated var bundledSettingNames: [String] { get }
    
    /// The list of available setting names (without extensions).
    var settingNames: [String] { get set }
    
    /// A cache of settings to avoid loading frequently used files multiple times.
    var cachedSettings: [String: Setting] { get set }
    
    
    /// Returns a built-in constant setting for the given name, if available.
    nonisolated static func constantSetting(name: String) -> Setting?
    
    /// Loads the persisted representation at the given URL.
    nonisolated static func persistence(at url: URL) throws -> PersistentSetting
    
    /// Encodes the provided setting into a persistable representation to store.
    nonisolated static func persistence(from setting: Setting) throws -> PersistentSetting
    
    /// Loads a setting from a persisted representation.
    nonisolated static func loadSetting(from persistent: any Persistable, type: UTType) throws -> sending Setting
    
    /// Builds the list of available settings by considering both user and bundled settings.
    nonisolated func listAvailableSettings() -> [String]
    
    /// Notifies the manager that a setting was updated.
    func didUpdateSetting(change: SettingChange)
}


extension SettingFileManaging {
    
    // MARK: Default implementation
    
    /// Returns a built-in constant setting for the given name, if available.
    nonisolated static func constantSetting(name: String) -> Setting? {
        
        nil
    }
    
    
    /// Notifies the manager that a setting was updated.
    ///
    /// - Parameters:
    ///   - change: The change to report.
    func didUpdateSetting(change: SettingChange) {
        
        // do nothing by default
    }
    
    
    // MARK: Public Methods
    
    /// The file URLs for user settings.
    nonisolated var userSettingFileURLs: [URL] {
        
        (try? FileManager.default.contentsOfDirectory(at: self.userSettingDirectoryURL,
                                                      includingPropertiesForKeys: nil,
                                                      options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]))?
            .filter { $0.conforms(to: Self.fileType) } ?? []
    }
    
    
    /// The names of settings customized by the user.
    nonisolated var userSettingNames: [String] {
    
        self.userSettingFileURLs.map(Self.settingName(from:))
    }
    
    
    /// Creates a setting name from a file URL (whether the file exists or not).
    ///
    /// - Parameters:
    ///   - fileURL: The file URL.
    /// - Returns: The setting name.
    nonisolated static func settingName(from fileURL: URL) -> String {
        
        fileURL.deletingPathExtension().lastPathComponent
    }
    
    
    /// Returns the URL for a user setting in Application Support if it exists.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: The user setting URL, or `nil` if not found.
    func urlForUserSetting(name: String) -> URL? {
        
        guard self.settingNames.contains(name) else { return nil }
        
        let url = self.preparedURLForUserSetting(name: name)
        
        return url.isReachable ? url : nil
    }
    
    
    /// Returns the persistent user setting for the given name, if available.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: The corresponding persistable representation of the user setting, or `nil` if the file doesn't exist or can't be read.
    func persistenceForUserSetting(name: String) -> PersistentSetting? {
        
        guard let url = self.urlForUserSetting(name: name) else { return nil }
        
        return try? Self.persistence(at: url)
    }
    
    
    /// Returns the state for a setting.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: The setting state, or `nil` if not found.
    func state(of name: String) -> SettingState? {
        
        SettingState(name: name,
                     isBundled: self.bundledSettingNames.contains(name),
                     isCustomized: self.urlForUserSetting(name: name) != nil)
    }
    
    
    /// Validates whether the setting name is valid for use as a filename and throws an error if not.
    ///
    /// - Parameters:
    ///   - settingName: The setting name to validate.
    ///   - originalName: The original name of the setting file, if it was renamed.
    /// - Throws: `InvalidNameError` if the name is invalid.
    func validate(settingName: String, originalName: String?) throws(InvalidNameError) {
        
        // just case difference is allowed
        if originalName?.caseInsensitiveCompare(settingName) == .orderedSame {
            return
        }
        
        if settingName.isEmpty {
            throw .empty
        }
        
        if (settingName + (Self.fileType.preferredFilenameExtension.map({ "." + $0 }) ?? "")).utf16.count > Int(NAME_MAX) {
            throw .tooLong
        }
        
        if settingName.contains("/") {  // invalid for filename
            throw .invalidCharacter("/")
        }
        
        if settingName.contains(":") {  // invalid for filename
            throw .invalidCharacter(":")
        }
        
        if settingName.contains(where: \.isNewline) {  // invalid for filename
            throw .newLine
        }
        
        if settingName.hasPrefix(".") {  // invalid for filename
            throw .startWithDot
        }
        
        if let duplicateName = self.settingNames.first(where: { $0.caseInsensitiveCompare(settingName) == .orderedSame }) {
            throw .duplicated(name: duplicateName)
        }
        
        if let reservedName = self.reservedNames.first(where: { $0.caseInsensitiveCompare(settingName) == .orderedSame }) {
            throw .reserved(name: reservedName)
        }
    }
    
    
    /// Returns the setting instance for the given setting name, or throws an error if a valid one cannot be found.
    ///
    /// - Parameter name: The setting name.
    /// - Returns: A Setting instance.
    func setting(name: String) throws(SettingFileError) -> Setting {
        
        if let setting = Self.constantSetting(name: name) {
            return setting
        }
        
        if let setting = self.cachedSettings[name] {
            return setting
        }
        
        guard let url = self.urlForUsedSetting(name: name) else {
            throw SettingFileError(.noSourceFile, name: name)
        }
        
        let setting: Setting
        
        do {
            setting = try self.loadSetting(at: url)
        } catch {
            throw SettingFileError(.loadFailed, name: name, underlyingError: error as NSError)
        }
        self.cachedSettings[name] = setting
        
        return setting
    }
    
    
    /// Deletes the user setting file for the given name.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Throws: `SettingFileError` if deletion fails.
    func removeSetting(name: String) throws(SettingFileError) {
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } catch {
            throw SettingFileError(.deletionFailed, name: name, underlyingError: error as NSError)
        }
        
        self.cachedSettings[name] = nil
        
        let change: SettingChange = .removed(name)
        self.updateSettingList(change: change)
    }
    
    
    /// Restores a bundled setting by removing its customized version.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Throws: An error if file deletion fails.
    func restoreSetting(name: String) throws {
        
        guard self.state(of: name)?.isRestorable == true else { return }  // only bundled setting can be restored
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        try FileManager.default.removeItem(at: url)
        
        self.cachedSettings[name] = nil
        
        let change: SettingChange = .updated(from: name, to: name)
        self.updateSettingList(change: change)
    }
    
    
    /// Duplicates a setting with a unique name.
    ///
    /// - Parameters:
    ///   - name: The original setting name.
    /// - Returns: The name of the newly created setting.
    @discardableResult func duplicateSetting(name: String) throws -> String {
        
        let newName = name.appendingUniqueNumber(in: self.settingNames)
        
        guard let sourceURL = self.urlForUsedSetting(name: name) else {
            throw SettingFileError(.noSourceFile, name: name)
        }
        
        let destURL = self.preparedURLForUserSetting(name: newName)
        
        try FileManager.default.createIntermediateDirectories(to: destURL)
        try FileManager.default.copyItem(at: sourceURL, to: destURL)
        
        let change: SettingChange = .added(newName)
        self.updateSettingList(change: change)
        
        return newName
    }
    
    
    /// Renames a setting.
    ///
    /// - Parameters:
    ///   - name: The current setting name.
    ///   - newName: The new setting name.
    /// - Throws: An `InvalidNameError` or file operation error.
    func renameSetting(name: String, to newName: String) throws {
        
        let sanitizedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        try self.validate(settingName: sanitizedNewName, originalName: name)
        
        try FileManager.default.moveItem(at: self.preparedURLForUserSetting(name: name),
                                         to: self.preparedURLForUserSetting(name: sanitizedNewName))
        
        self.cachedSettings[name] = nil
        self.cachedSettings[newName] = nil
        
        let change: SettingChange = .updated(from: name, to: sanitizedNewName)
        self.updateSettingList(change: change)
    }
    
    
    /// Imports a setting.
    ///
    /// - Parameters:
    ///   - persistence: The persistable representation to import.
    ///   - name: The name of the setting to import.
    ///   - type: The UTType of the provided persistence. If `nil`, defaults to the manager’s file type.
    ///   - overwrite: Whether to overwrite an existing setting if one exists.
    /// - Throws: `ImportDuplicationError` (only when `overwrite` is `false` and a duplicate exists), or any other error that occurs.
    func importSetting(persistence: any Persistable, name: String, type: UTType? = nil, overwrite: Bool) throws {
        
        // check duplication
        if !overwrite {
            for existingName in self.settingNames {
                guard existingName.caseInsensitiveCompare(name) == .orderedSame else { continue }
                
                guard self.urlForUserSetting(name: existingName) == nil else {  // duplicated
                    throw ImportDuplicationError(name: existingName, persistence: persistence)
                }
            }
        }
        
        // test if the setting file can be read correctly
        let type = type ?? Self.fileType
        let setting = try Self.loadSetting(from: persistence, type: type)
        let persistenceToStore = type.conforms(to: Self.fileType) ? persistence : try Self.persistence(from: setting)
        
        // write file
        let destURL = self.preparedURLForUserSetting(name: name)
        do {
            try FileManager.default.createIntermediateDirectories(to: destURL)
            try persistenceToStore.write(to: destURL)
        } catch {
            throw SettingFileError(.importFailed, name: name, underlyingError: error as NSError)
        }
        
        self.cachedSettings[name] = setting
        
        let change: SettingChange = self.settingNames.contains(name)
            ? .updated(from: name, to: name)
            : .added(name)
        self.updateSettingList(change: change)
    }
    
    
    /// Exports all user setting files as a dictionary mapping each file's name to its persistable representation.
    ///
    /// - Returns: A dictionary mapping each user setting file’s name to its persistable content.
    func exportSettings() -> [String: some Persistable] {
        
        self.userSettingFileURLs.reduce(into: [:]) { dictionary, url in
            dictionary[url.lastPathComponent] = try? Self.persistence(at: url)
        }
    }
    
    
    /// Reloads settings in the user domain.
    func invalidateUserSettings() async {
        
        self.cachedSettings.removeAll()
        self.settingNames = await Task.detached {
            self.listAvailableSettings()
        }.value
    }
    
    
    /// Writes a setting to the user domain.
    ///
    /// - Parameters:
    ///   - setting: The setting instance to persist.
    ///   - name: The name used to determine the destination file URL.
    /// - Throws: An error if writing or file operations fail.
    func write(setting: Setting, name: String) throws {
        
        let fileURL = self.preparedURLForUserSetting(name: name)
        
        // just remove the current custom setting file in the user domain
        // if the new setting is the same as bundled one
        if let bundledURL = self.urlForBundledSetting(name: name),
           let bundledSetting = try? self.loadSetting(at: bundledURL),
           setting == bundledSetting
        {
            if fileURL.isReachable {
                try FileManager.default.removeItem(at: fileURL)
            }
            
        } else {
            // save the file to the user domain
            let persistence = try Self.persistence(from: setting)
            
            try FileManager.default.createIntermediateDirectories(to: fileURL)
            try persistence.write(to: fileURL)
        }
    }
    
    
    /// Updates the managed setting list by applying the given change.
    ///
    /// - Parameter change: The change to apply.
    func updateSettingList(change: SettingChange) {
        
        assert(Thread.isMainThread)
        
        defer {
            self.didUpdateSetting(change: change)
            NotificationCenter.default.post(name: .didUpdateSettingNotification, object: self, userInfo: ["change": change])
        }
        
        guard change.old != change.new else { return }
        
        var settingNames = self.settingNames
        
        if let old = change.old {
            settingNames.removeFirst(old)
        }
        if let new = change.new, !settingNames.contains(new) {
            settingNames.append(new)
        }
        settingNames.sort(using: .localizedStandard)
        
        guard settingNames != self.settingNames else { return }
        
        self.settingNames = settingNames
    }
    
    
    // MARK: Private Methods
    
    /// The user setting directory URL in Application Support.
    private nonisolated var userSettingDirectoryURL: URL {
        
        .applicationSupportDirectory(component: Self.directoryName)
    }
    
    
    /// Returns a valid file URL for a setting name if it exists.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: The URL for the setting file.
    private func urlForUsedSetting(name: String) -> URL? {
        
        self.urlForUserSetting(name: name) ?? self.urlForBundledSetting(name: name)
    }
    
    
    /// Returns the setting file URL in the application's Resources domain if it exists.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: The bundled setting URL, or `nil` if not found.
    private nonisolated func urlForBundledSetting(name: String) -> URL? {
        
        Bundle.main.url(forResource: name, withExtension: Self.fileType.preferredFilenameExtension, subdirectory: Self.directoryName)
    }
    
    
    /// Returns the user setting file URL for the given name (whether it exists or not).
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: A file URL.
    private nonisolated func preparedURLForUserSetting(name: String) -> URL {
        
        self.userSettingDirectoryURL.appendingPathComponent(name, conformingTo: Self.fileType)
    }
    
    
    /// Loads the setting from the file at the given URL.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the file to load.
    /// - Returns: A Setting instance.
    private nonisolated func loadSetting(at fileURL: URL) throws -> sending Setting {
        
        guard let type = UTType(filenameExtension: fileURL.pathExtension) else { throw CocoaError(.fileReadUnsupportedScheme) }
        
        let persistence = try Self.persistence(at: fileURL)
        
        return try Self.loadSetting(from: persistence, type: type)
    }
}


// MARK: - Errors

enum InvalidNameError: LocalizedError {
    
    case empty
    case tooLong
    case invalidCharacter(String)
    case newLine
    case startWithDot
    case duplicated(name: String)
    case reserved(name: String)
    
    
    var errorDescription: String? {
        
        switch self {
            case .empty:
                String(localized: "InvalidNameError.empty.description",
                       defaultValue: "Name can’t be empty.")
            case .tooLong:
                String(localized: "InvalidNameError.tooLong.description",
                       defaultValue: "The name is too long.")
            case .invalidCharacter(let string):
                String(localized: "InvalidNameError.invalidCharacter.description",
                       defaultValue: "Name can’t contain “\(string)”.",
                       comment: "%@ is the character invalid for filename")
            case .newLine:
                String(localized: "InvalidNameError.newLine.description",
                       defaultValue: "Name can’t contain new lines.")
            case .startWithDot:
                String(localized: "InvalidNameError.startWithDot.description",
                       defaultValue: "Name can’t begin with “.”.")
            case .duplicated(let name):
                String(localized: "InvalidNameError.duplicated.description",
                       defaultValue: "The name “\(name)” is already taken.")
            case .reserved(let name):
                String(localized: "InvalidNameError.reserved.description",
                       defaultValue: "The name “\(name)” is reserved.")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        String(localized: "InvalidNameError.recoverySuggestion",
               defaultValue: "Choose another name.")
    }
}


struct SettingFileError: LocalizedError {
    
    enum Code {
        
        case deletionFailed
        case importFailed
        case loadFailed
        case noSourceFile
    }
    
    var code: Code
    var name: String
    var underlyingError: NSError?
    
    
    init(_ code: Code, name: String, underlyingError: NSError? = nil) {
        
        self.code = code
        self.name = name
        self.underlyingError = underlyingError
    }
    
    
    var errorDescription: String? {
        
        switch self.code {
            case .deletionFailed:
                String(localized: "SettingFileError.deletionFailed.description",
                       defaultValue: "“\(self.name)” couldn’t be deleted.")
            case .importFailed:
                String(localized: "SettingFileError.importFailed.description",
                       defaultValue: "“\(self.name)” couldn’t be imported.")
            case .loadFailed:
                String(localized: "SettingFileError.loadFailed.description",
                       defaultValue: "“\(self.name)” couldn’t be loaded.")
            case .noSourceFile:
                String(localized: "SettingFileError.noSourceFile.description",
                       defaultValue: "No original file for “\(self.name)” was found.")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch (self.code, self.underlyingError) {
            case (.loadFailed, let error as DecodingError):
                String(localized: "SettingFileError.loadFailed.recoverySuggestion.decodingError",
                       defaultValue: "Decoding Error: \(error.localizedDescription)")
            default:
                self.underlyingError?.localizedRecoverySuggestion
        }
    }
}


struct ImportDuplicationError: LocalizedError {
    
    var name: String
    var persistence: any Persistable
    
    
    var errorDescription: String {
        
        String(localized: "ImportDuplicationError.description",
               defaultValue: "“\(self.name)” already exists. Do you want to replace it?",
               comment: "%@ is a name of a setting. Refer to the same expression by Apple.")
    }
    
    
    var recoverySuggestion: String {
        
        String(localized: "ImportDuplicationError.recoverySuggestion",
               defaultValue: "A custom setting with the same name already exists. Replacing it will overwrite its current content.",
               comment: "Refer to similar expressions by Apple.")
    }
}
