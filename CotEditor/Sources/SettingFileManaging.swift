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
//  © 2016-2024 1024jp
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
import AppKit.NSApplication

enum SettingChange {
    
    case added(_ name: String)
    case removed(_ name: String)
    case updated(from: String, to: String)
    
    
    var old: String? {
        
        switch self {
            case .removed(let name), .updated(from: let name, to: _):
                name
            case .added:
                nil
        }
    }
    
    
    var new: String? {
        
        switch self {
            case .added(let name), .updated(from: _, to: let name):
                name
            case .removed:
                nil
        }
    }
}


struct SettingState: Equatable {
    
    var name: String
    var isBundled: Bool
    var isCustomized: Bool
    
    var isRestorable: Bool  { self.isBundled && self.isCustomized }
}



// MARK: -

protocol SettingFileManaging: AnyObject {
    
    associatedtype Setting
    
    
    /// Publishes when a setting file is updated with new/previous setting names.
    var didUpdateSetting: PassthroughSubject<SettingChange, Never> { get }
    
    
    /// Directory name in both Application Support and bundled Resources.
    static var directoryName: String { get }
    
    /// UTType of user setting file
    var fileType: UTType { get }
    
    /// List of names that cannot be used for user setting names.
    var reservedNames: [String] { get }
    
    /// List of names of setting filename (without extension).
    var settingNames: [String] { get set }
    
    /// List of names of setting filename which are bundled (without extension).
    var bundledSettingNames: [String] { get }
    
    /// Stored settings to avoid loading frequently-used setting files multiple times.
    var cachedSettings: [String: Setting] { get set }
    
    
    /// Returns setting instance corresponding to the given setting name.
    func setting(name: String) -> Setting?
    
    /// Loads setting from the file at the given URL.
    func loadSetting(at fileURL: URL) throws -> Setting
    
    /// Loads settings in the user domain.
    func loadUserSettings()
}



extension SettingFileManaging {
    
    // MARK: Default implementation
    
    /// Returns setting instance corresponding to the given setting name.
    func setting(name: String) -> Setting? {
        
        if let setting = self.cachedSettings[name] {
            return setting
        }
        
        guard let url = self.urlForUsedSetting(name: name) else { return nil }
        
        let setting = try? self.loadSetting(at: url)
        self.cachedSettings[name] = setting
        
        return setting
    }
    
    
    
    // MARK: Public Methods
    
    /// File urls for user settings.
    var userSettingFileURLs: [URL] {
        
        (try? FileManager.default.contentsOfDirectory(at: self.userSettingDirectoryURL,
                                                      includingPropertiesForKeys: nil,
                                                      options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]))?
            .filter { $0.conforms(to: self.fileType) } ?? []
    }
    
    
    /// Creates the setting name from a URL (don't care if it exists).
    func settingName(from fileURL: URL) -> String {
        
        fileURL.deletingPathExtension().lastPathComponent
    }
    
    
    /// Returns a valid setting file URL for the setting name or nil if not exists.
    func urlForUsedSetting(name: String) -> URL? {
        
        self.urlForUserSetting(name: name) ?? self.urlForBundledSetting(name: name)
    }
    
    
    /// Returns a setting file URL in the application's Resources domain or nil if not exists.
    func urlForBundledSetting(name: String) -> URL? {
        
        Bundle.main.url(forResource: name, withExtension: self.fileType.preferredFilenameExtension, subdirectory: Self.directoryName)
    }
    
    
    /// Returns a setting file URL in the user's Application Support domain or nil if not exists.
    func urlForUserSetting(name: String) -> URL? {
        
        guard self.settingNames.contains(name) else { return nil }
        
        let url = self.preparedURLForUserSetting(name: name)
        
        return url.isReachable ? url : nil
    }
    
    
    /// Returns a setting file URL in the user's Application Support domain (don't care if it exists).
    func preparedURLForUserSetting(name: String) -> URL {
        
        self.userSettingDirectoryURL.appendingPathComponent(name, conformingTo: self.fileType)
    }
    
    
    /// Returns whether the setting name is one of the bundled settings.
    func state(of name: String) -> SettingState? {
        
        SettingState(name: name,
                     isBundled: self.bundledSettingNames.contains(name),
                     isCustomized: self.urlForUserSetting(name: name) != nil)
    }
    
    
    /// Returns setting name appending number suffix without extension.
    func savableSettingName(for proposedName: String, appendingCopySuffix: Bool = false) -> String {
        
        let suffix = appendingCopySuffix ? String(localized: "copy", comment: "suffix for copied setting file") : nil
        
        return self.settingNames.createAvailableName(for: proposedName, suffix: suffix)
    }
    
    
    /// Validates whether the setting name is valid (for a filename) and throw an error if not.
    ///
    /// - Parameters:
    ///   - settingName: The setting name to validate.
    ///   - originalName: The original name of the setting file if it was renamed.
    /// - Throws: `InvalidNameError`
    func validate(settingName: String, originalName: String?) throws {
        
        // just case difference is OK
        if originalName?.caseInsensitiveCompare(settingName) == .orderedSame {
            return
        }
        
        if settingName.isEmpty {
            throw InvalidNameError.empty
        }
        
        if settingName.contains("/") {  // invalid for filename
            throw InvalidNameError.containSlash
        }
        
        if settingName.hasPrefix(".") {  // invalid for filename
            throw InvalidNameError.startWithDot
        }
        
        if let duplicateName = self.settingNames.first(where: { $0.caseInsensitiveCompare(settingName) == .orderedSame }) {
            throw InvalidNameError.duplicated(name: duplicateName)
        }
        
        if let reservedName = self.reservedNames.first(where: { $0.caseInsensitiveCompare(settingName) == .orderedSame }) {
            throw InvalidNameError.reserved(name: reservedName)
        }
    }
    
    
    /// Deletes user's setting file for the setting name.
    ///
    /// - Throws: `SettingFileError`
    func removeSetting(name: String) throws {
        
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
    
    
    /// Restores the setting with name.
    func restoreSetting(name: String) throws {
        
        guard self.state(of: name)?.isRestorable == true else { return }  // only bundled setting can be restored
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        try FileManager.default.removeItem(at: url)
        
        self.cachedSettings[name] = nil
        
        let change: SettingChange = .updated(from: name, to: name)
        self.updateSettingList(change: change)
    }
    
    
    /// Duplicates the setting with name.
    @discardableResult
    func duplicateSetting(name: String) throws -> String {
        
        let newName = self.savableSettingName(for: name, appendingCopySuffix: true)
        
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
    
    
    /// Renames the setting with name.
    func renameSetting(name: String, to newName: String) throws {
        
        let sanitizedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        try self.validate(settingName: sanitizedNewName, originalName: name)
        
        try FileManager.default.moveItem(at: self.preparedURLForUserSetting(name: name),
                                         to: self.preparedURLForUserSetting(name: sanitizedNewName))
        
        self.cachedSettings[name] = nil
        self.cachedSettings[newName] = nil
        
        let change: SettingChange = .updated(from: name, to: newName)
        self.updateSettingList(change: change)
    }
    
    
    /// Exports setting file to passed-in URL.
    func exportSetting(name: String, to fileURL: URL, hidesExtension: Bool) throws {
        
        let sourceURL = self.preparedURLForUserSetting(name: name)
        
        var resourceValues = URLResourceValues()
        resourceValues.hasHiddenExtension = hidesExtension
        
        var coordinationError: NSError?
        var writingError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: sourceURL, options: .withoutChanges,
                                       writingItemAt: fileURL, options: .forMoving, error: &coordinationError)
        { (newReadingURL, newWritingURL) in
            
            do {
                if newWritingURL.isReachable {
                    try FileManager.default.removeItem(at: newWritingURL)
                }
                try FileManager.default.copyItem(at: newReadingURL, to: newWritingURL)
                
                var newWritingURL = newWritingURL
                try newWritingURL.setResourceValues(resourceValues)
                
            } catch {
                writingError = error as NSError
            }
        }
        
        if let error = writingError ?? coordinationError {
            throw error
        }
    }
    
    
    /// Imports setting at passed-in URL.
    ///
    /// - Throws: `SettingFileError` or `ImportDuplicationError`
    func importSetting(fileURL: URL) throws {
        
        let importName = self.settingName(from: fileURL)
        
        // check duplication
        for name in self.settingNames {
            guard name.caseInsensitiveCompare(importName) == .orderedSame else { continue }
            
            guard self.urlForUserSetting(name: name) == nil else {  // duplicated
                throw ImportDuplicationError(name: name, type: self.fileType, continuationHandler: { [unowned self] in
                    try self.overwriteSetting(fileURL: fileURL)
                })
            }
        }
        
        try self.overwriteSetting(fileURL: fileURL)
    }
    
    
    /// Updates the managed setting list by applying the given change.
    ///
    /// - Parameter change: The change.
    func updateSettingList(change: SettingChange) {
        
        defer {
            self.didUpdateSetting.send(change)
        }
        
        guard change.old != change.new else { return }
        
        var settingNames = self.settingNames
        
        if let old = change.old {
            settingNames.removeFirst(old)
        }
        if let new = change.new, !settingNames.contains(new) {
            settingNames.append(new)
        }
        settingNames.sort(options: [.localized, .caseInsensitive])
        
        guard settingNames != self.settingNames else { return }
        
        self.settingNames = settingNames
    }
    
    
    
    // MARK: Private Methods
    
    /// The user setting directory URL in Application Support.
    private var userSettingDirectoryURL: URL {
        
        .applicationSupportDirectory(component: Self.directoryName)
    }
    
    
    /// Forces importing the setting at the passed-in URL.
    ///
    /// - Parameter fileURL: The URL of the file to import.
    /// - Throws: `SettingFileError`
    private func overwriteSetting(fileURL: URL) throws {
        
        let name = self.settingName(from: fileURL)
        let destURL = self.preparedURLForUserSetting(name: name)
        
        try FileManager.default.createIntermediateDirectories(to: destURL)
        
        // copy file
        var coordinationError: NSError?
        var writingError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: fileURL, options: [.withoutChanges, .resolvesSymbolicLink],
                                       writingItemAt: destURL, options: .forReplacing, error: &coordinationError)
        { (newReadingURL, newWritingURL) in
            
            do {
                if newWritingURL.isReachable {
                    try FileManager.default.removeItem(at: newWritingURL)
                }
                try FileManager.default.copyItem(at: newReadingURL, to: newWritingURL)
                
            } catch {
                writingError = error as NSError
            }
        }
        
        if let error = writingError ?? coordinationError {
            throw SettingFileError(.importFailed, name: name, underlyingError: error)
        }
        
        // update internal cache
        let change: SettingChange = self.settingNames.contains(name)
            ? .updated(from: name, to: name)
            : .added(name)
        self.updateSettingList(change: change)
    }
}



// MARK: - Errors

enum InvalidNameError: LocalizedError {
    
    case empty
    case containSlash
    case startWithDot
    case duplicated(name: String)
    case reserved(name: String)
    
    
    var errorDescription: String? {
        
        switch self {
            case .empty:
                String(localized: "InvalidNameError.empty.description",
                       defaultValue: "Name can’t be empty.")
            case .containSlash:
                String(localized: "InvalidNameError.containSlash.description",
                       defaultValue: "Name can’t contain “/”.")
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
            case .noSourceFile:
                String(localized: "SettingFileError.noSourceFile.description",
                       defaultValue: "No original file for “\(self.name)” was found.")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        self.underlyingError?.localizedRecoverySuggestion
    }
}



struct ImportDuplicationError: LocalizedError, RecoverableError {
    
    var name: String
    var type: UTType
    var continuationHandler: (() throws -> Void)
    
    
    var errorDescription: String? {
        
        switch self.type {
            case .yaml:
                String(localized: "ImportDuplicationError.syntax.description",
                       defaultValue: "A new syntax named “\(self.name)” will be installed, but a custom syntax with the same name already exists.")
            case .cotTheme:
                String(localized: "ImportDuplicationError.theme.description",
                       defaultValue: "A new theme named “\(self.name)” will be installed, but a custom theme with the same name already exists.")
            case .cotReplacement:
                String(localized: "ImportDuplicationError.replacement.description",
                       defaultValue: "A new replacement definition named “\(self.name)” will be installed, but a definition with the same name already exists.")
            default:
                fatalError()
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.type {
            case .yaml:
                String(localized: "ImportDuplicationError.syntax.recoverySuggestion",
                       defaultValue: "Do you want to replace it?\nReplaced syntax can’t be restored.")
            case .cotTheme:
                String(localized: "ImportDuplicationError.theme.recoverySuggestion",
                       defaultValue: "Do you want to replace it?\nReplaced theme can’t be restored.")
            case .cotReplacement:
                String(localized: "ImportDuplicationError.replacement.recoverySuggestion",
                       defaultValue: "Do you want to replace it?\nReplaced definition can’t be restored.")
            default:
                fatalError()
        }
    }
    
    
    var recoveryOptions: [String] {
        
        [String(localized: "Cancel"),
         String(localized: "ImportDuplicationError.recoveryOption.replace",
                defaultValue: "Replace", comment: "button label")]
    }
    
    
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        
        switch recoveryOptionIndex {
            case 0:  // == Cancel
                return false
                
            case 1:  // == Replace
                do {
                    try self.continuationHandler()
                } catch {
                    Task { @MainActor in
                        NSApp.presentError(error)
                    }
                    return false
                }
                return true
                
            default:
                preconditionFailure()
        }
    }
}
