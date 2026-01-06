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
    
    /// Notification posted when a setting file is updated with new or previous setting names.
    static let didUpdateSettingNotification = Notification.Name("SettingFileManaging.didUpdateSettingNotification")
}


extension URL {
    
    /// Returns the URL for a given subdirectory in the user's Application Support directory.
    ///
    /// - Parameter subDirectory: The name of the subdirectory in the Application Support.
    /// - Returns: A directory URL.
    static func applicationSupportDirectory(component subDirectory: String) -> URL {
        
        .applicationSupportDirectory
        .appending(component: "CotEditor", directoryHint: .isDirectory)
        .appending(component: subDirectory, directoryHint: .isDirectory)
    }
}


// MARK: -

@MainActor protocol SettingFileManaging: AnyObject, Sendable {
    
    associatedtype Setting: Sendable
    
    
    /// The directory name in both Application Support and bundled Resources.
    nonisolated static var directoryName: String { get }
    
    /// The UTType of user setting files.
    nonisolated static var fileType: UTType { get }
    
    /// The list of names reserved and cannot be used for user setting names.
    nonisolated var reservedNames: [String] { get }
    
    /// The list of bundled setting names (without extensions).
    nonisolated var bundledSettingNames: [String] { get }
    
    /// The list of available setting names (without extensions).
    var settingNames: [String] { get set }
    
    /// Stored settings to avoid loading frequently-used setting files multiple times.
    var cachedSettings: [String: Setting] { get set }
    
    
    /// Encodes the provided setting into data to store.
    nonisolated static func data(from setting: Setting) throws -> Data
    
    /// Loads the setting from the data.
    nonisolated static func loadSetting(from data: Data, type: UTType) throws -> sending Setting
    
    /// Returns setting instance corresponding to the given setting name, or throws error if not a valid one found.
    func setting(name: String) throws(SettingFileError) -> Setting
    
    /// Loads settings from the user domain.
    nonisolated func loadUserSettings() -> [String]
    
    /// Tells that a setting did update.
    func didUpdateSetting(change: SettingChange)
}


extension SettingFileManaging {
    
    // MARK: Default implementation
    
    /// Returns setting instance corresponding to the given setting name, or throws error if not a valid one found.
    ///
    /// - Parameter name: The setting name.
    /// - Returns: A Setting instance.
    func setting(name: String) throws(SettingFileError) -> Setting {
        
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
    
    
    /// Returns the bundled version of the setting if it exists.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// Returns: The setting or `nil` if not found.
    func bundledSetting(name: String) -> Setting? {
        
        guard let url = self.urlForBundledSetting(name: name) else { return nil }
        
        return try? self.loadSetting(at: url)
    }
    
    
    /// Notifies that a setting was updated.
    ///
    /// - Parameters:
    ///   - change: The change to notify.
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
    
    
    /// The names of the setting user customized.
    nonisolated var userSettingNames: [String] {
    
        self.userSettingFileURLs.map(Self.settingName(from:))
    }
    
    
    /// Creates a setting name from a file URL (exists or not).
    ///
    /// - Parameters:
    ///   - fileURL: The file URL.
    /// - Returns: The setting name.
    nonisolated static func settingName(from fileURL: URL) -> String {
        
        fileURL.deletingPathExtension().lastPathComponent
    }
    
    
    /// Returns a valid file URL for a setting name if it exists.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: The URL for the setting file.
    func urlForUsedSetting(name: String) -> URL? {
        
        self.urlForUserSetting(name: name) ?? self.urlForBundledSetting(name: name)
    }
    
    
    /// Returns a setting file URL in the application's Resources domain if it exists.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: The bundled setting URL, or `nil` if not found.
    nonisolated func urlForBundledSetting(name: String) -> URL? {
        
        Bundle.main.url(forResource: name, withExtension: Self.fileType.preferredFilenameExtension, subdirectory: Self.directoryName)
    }
    
    
    /// Returns a setting file URL in the user's Application Support domain if it exists.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: The user setting URL, or `nil` if not found.
    func urlForUserSetting(name: String) -> URL? {
        
        guard self.settingNames.contains(name) else { return nil }
        
        let url = self.preparedURLForUserSetting(name: name)
        
        return url.isReachable ? url : nil
    }
    
    
    /// Returns a setting file URL in the user's Application Support domain if it exists.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: The data, or `nil` if the file not found or failed to load the data.
    func dataForUserSetting(name: String) -> Data? {
        
        guard let url = self.urlForUserSetting(name: name) else { return nil }
        
        return try? Data(contentsOf: url)
    }
    
    
    /// Returns the user setting file URL for the given name (exists or not).
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: A file URL.
    nonisolated func preparedURLForUserSetting(name: String) -> URL {
        
        self.userSettingDirectoryURL.appendingPathComponent(name, conformingTo: Self.fileType)
    }
    
    
    /// Returns the state of a setting.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Returns: The setting state, or `nil` if not found.
    func state(of name: String) -> SettingState? {
        
        SettingState(name: name,
                     isBundled: self.bundledSettingNames.contains(name),
                     isCustomized: self.urlForUserSetting(name: name) != nil)
    }
    
    
    /// Validates whether the setting name is valid (for a filename) and throw an error if not.
    ///
    /// - Parameters:
    ///   - settingName: The setting name to validate.
    ///   - originalName: The original name of the setting file if it was renamed.
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
    
    
    /// Restores a bundled setting by removing a customized version.
    ///
    /// - Parameters:
    ///   - name: The setting name.
    /// - Throws: An error if the file deletion fails.
    func restoreSetting(name: String) throws {
        
        guard self.state(of: name)?.isRestorable == true else { return }  // only bundled setting can be restored
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        try FileManager.default.removeItem(at: url)
        
        self.cachedSettings[name] = nil
        
        let change: SettingChange = .updated(from: name, to: name)
        self.updateSettingList(change: change)
    }
    
    
    /// Duplicates the setting with a unique name.
    ///
    /// - Parameters:
    ///   - name: The original setting name.
    /// - Returns: The name of the created setting.
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
    
    
    /// Imports the setting.
    ///
    /// - Parameters:
    ///   - data: The data to import.
    ///   - name: The name of the setting to import.
    ///   - overwrite: Whether overwrites the existing setting if exists.
    /// - Throws: `ImportDuplicationError` (only when the `overwrite` flag is `true`), or `any Error`
    func importSetting(data: Data, name: String, type: UTType? = nil, overwrite: Bool) throws {
        
        // check duplication
        if !overwrite {
            for existingName in self.settingNames {
                guard existingName.caseInsensitiveCompare(name) == .orderedSame else { continue }
                
                guard self.urlForUserSetting(name: existingName) == nil else {  // duplicated
                    throw ImportDuplicationError(name: existingName, data: data)
                }
            }
        }
        
        // test if the setting file can be read correctly
        let type = type ?? Self.fileType
        let setting = try Self.loadSetting(from: data, type: type)
        let dataToStore = type.conforms(to: Self.fileType) ? data : try Self.data(from: setting)
        
        // write file
        let destURL = self.preparedURLForUserSetting(name: name)
        do {
            try FileManager.default.createIntermediateDirectories(to: destURL)
            try dataToStore.write(to: destURL)
        } catch {
            throw SettingFileError(.importFailed, name: name, underlyingError: error as NSError)
        }
        
        self.cachedSettings[name] = setting
        
        let change: SettingChange = self.settingNames.contains(name)
            ? .updated(from: name, to: name)
            : .added(name)
        self.updateSettingList(change: change)
    }
    
    
    /// Exports all user setting files as a dictionary mapping each file's name to its data.
    ///
    /// - Returns: A dictionary where the key is the file name of each user setting and the value is the data content of that file.
    func exportSettings() -> [String: Data] {
        
        self.userSettingFileURLs.reduce(into: [:]) { dictionary, url in
            dictionary[url.lastPathComponent] = try? Data(contentsOf: url)
        }
    }
    
    
    /// Reloads settings in the user domain.
    func invalidateUserSettings() async {
        
        self.cachedSettings.removeAll()
        self.settingNames = await Task.detached {
            self.loadUserSettings()
        }.value
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
    
    
    /// Loads the setting from the file at the given URL.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the file to load.
    /// - Returns: A Setting instance.
    nonisolated func loadSetting(at fileURL: URL) throws -> sending Setting {
        
        guard let type = UTType(filenameExtension: fileURL.pathExtension) else { throw CocoaError(.fileReadUnsupportedScheme) }
        
        let data = try Data(contentsOf: fileURL)
        
        return try Self.loadSetting(from: data, type: type)
    }
    
    
    // MARK: Private Methods
    
    /// The user setting directory URL in Application Support.
    private nonisolated var userSettingDirectoryURL: URL {
        
        .applicationSupportDirectory(component: Self.directoryName)
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
    var data: Data
    
    
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
