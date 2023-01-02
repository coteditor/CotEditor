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
//  © 2016-2023 1024jp
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
import AppKit.NSApplication
import UniformTypeIdentifiers

enum SettingChange {
    
    case added(_ name: String)
    case removed(_ name: String)
    case updated(from: String, to: String)
    
    
    var old: String? {
        
        switch self {
            case .removed(let name), .updated(from: let name, to: _):
                return name
            case .added:
                return nil
        }
    }
    
    
    var new: String? {
        
        switch self {
            case .added(let name), .updated(from: _, to: let name):
                return name
            case .removed:
                return nil
        }
    }
}



// MARK: -

protocol SettingFileManaging: SettingManaging {
    
    associatedtype Setting
    
    
    /// Publishes when a setting file is updated with new/previous setting names.
    var didUpdateSetting: PassthroughSubject<SettingChange, Never> { get }
    
    
    /// Directory name in both Application Support and bundled Resources.
    static var directoryName: String { get }
    
    /// UTType of user setting file
    var fileType: UTType { get }
    
    /// List of names of setting file name (without extension).
    var settingNames: [String] { get set }
    
    /// List of names of setting file name which are bundled (without extension).
    var bundledSettingNames: [String] { get }
    
    /// Stored settings to avoid loading frequently-used setting files multiple times.
    var cachedSettings: [String: Setting] { get set }
    
    
    /// Return setting instance corresponding to the given setting name.
    func setting(name: String) -> Setting?
    
    /// Load setting from the file at the given URL.
    func loadSetting(at fileURL: URL) throws -> Setting
    
    /// Load settings in the user domain.
    func loadUserSettings()
}



extension SettingFileManaging {
    
    // MARK: Default implementation
    
    /// return setting instance corresponding to the given setting name
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
    
    /// file urls for user settings
    var userSettingFileURLs: [URL] {
        
        (try? FileManager.default.contentsOfDirectory(at: self.userSettingDirectoryURL,
                                                      includingPropertiesForKeys: nil,
                                                      options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]))?
            .filter { $0.conforms(to: self.fileType) } ?? []
    }
    
    
    /// create setting name from a URL (don't care if it exists)
    func settingName(from fileURL: URL) -> String {
        
        fileURL.deletingPathExtension().lastPathComponent
    }
    
    
    /// return a valid setting file URL for the setting name or nil if not exists
    func urlForUsedSetting(name: String) -> URL? {
        
        self.urlForUserSetting(name: name) ?? self.urlForBundledSetting(name: name)
    }
    
    
    /// return a setting file URL in the application's Resources domain or nil if not exists
    func urlForBundledSetting(name: String) -> URL? {
        
        Bundle.main.url(forResource: name, withExtension: self.fileType.preferredFilenameExtension, subdirectory: Self.directoryName)
    }
    
    
    /// return a setting file URL in the user's Application Support domain or nil if not exists
    func urlForUserSetting(name: String) -> URL? {
        
        guard self.settingNames.contains(name) else { return nil }
        
        let url = self.preparedURLForUserSetting(name: name)
        
        return url.isReachable ? url : nil
    }
    
    
    /// return a setting file URL in the user's Application Support domain (don't care if it exists)
    func preparedURLForUserSetting(name: String) -> URL {
        
        self.userSettingDirectoryURL.appendingPathComponent(name, conformingTo: self.fileType)
    }
    
    
    /// whether the setting name is one of the bundled settings
    func isBundledSetting(name: String) -> Bool {
        
        self.bundledSettingNames.contains(name)
    }
    
    
    /// whether the setting name is customized by the user
    func isCustomizedSetting(name: String) -> Bool {
        
        self.urlForUserSetting(name: name) != nil
    }
    
    
    /// return setting name appending number suffix without extension
    func savableSettingName(for proposedName: String, appendingCopySuffix: Bool = false) -> String {
        
        let suffix = appendingCopySuffix ? String(localized: "copy", comment: "copied file suffix") : nil
        
        return self.settingNames.createAvailableName(for: proposedName, suffix: suffix)
    }
    
    
    /// Validate whether the setting name is valid (for a file name) and throw an error if not.
    ///
    /// - Parameters:
    ///   - settingName: The setting name to validate.
    ///   - originalName: The original name of the setting file if it was renamed.
    /// - Throws: `InvalidNameError`
    func validate(settingName: String, originalName: String?) throws {
        
        // just case difference is OK
        if let originalName = originalName, settingName.caseInsensitiveCompare(originalName) != .orderedSame {
            return
        }
        
        if settingName.isEmpty {
            throw InvalidNameError.empty
        }
        
        if settingName.contains("/") {  // Containing "/" is invalid for a file name.
            throw InvalidNameError.containSlash
        }
        
        if settingName.hasPrefix(".") {  // Starting with "." is invalid for a file name.
            throw InvalidNameError.startWithDot
        }
        
        if self.settingNames.contains(where: { $0.caseInsensitiveCompare(settingName) == .orderedSame }) {
            throw InvalidNameError.duplicated(name: settingName)
        }
    }
    
    
    /// Delete user's setting file for the setting name.
    ///
    /// - Throws: `SettingFileError`
    func removeSetting(name: String) throws {
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
        } catch {
            throw SettingFileError(kind: .deletionFailed, name: name, error: error as NSError)
        }
        
        self.cachedSettings[name] = nil
        
        let change: SettingChange = .removed(name)
        self.updateSettingList(change: change)
    }
    
    
    /// restore the setting with name
    func restoreSetting(name: String) throws {
        
        guard self.isBundledSetting(name: name) else { return }  // only bundled setting can be restored
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        try FileManager.default.removeItem(at: url)
        
        self.cachedSettings[name] = nil
        
        let change: SettingChange = .updated(from: name, to: name)
        self.updateSettingList(change: change)
    }
    
    
    /// duplicate the setting with name
    @discardableResult
    func duplicateSetting(name: String) throws -> String {
        
        let newName = self.savableSettingName(for: name, appendingCopySuffix: true)
        
        guard let sourceURL = self.urlForUsedSetting(name: name) else {
            throw SettingFileError(kind: .noSourceFile, name: name, error: nil)
        }
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        try FileManager.default.copyItem(at: sourceURL,
                                         to: self.preparedURLForUserSetting(name: newName))
        
        let change: SettingChange = .added(newName)
        self.updateSettingList(change: change)
        
        return newName
    }
    
    
    /// rename the setting with name
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
    
    
    /// export setting file to passed-in URL
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
    
    
    /// Import setting at passed-in URL.
    ///
    /// - Throws: `SettingFileError`
    func importSetting(fileURL: URL) throws {
        
        let importName = self.settingName(from: fileURL)
        
        // check duplication
        for name in self.settingNames {
            guard name.caseInsensitiveCompare(importName) == .orderedSame else { continue }
            
            guard self.urlForUserSetting(name: name) == nil else {  // duplicated
                throw ImportDuplicationError(name: name, type: self.fileType, replacingClosure: { [unowned self] in
                    try self.overwriteSetting(fileURL: fileURL)
                })
            }
        }
        
        try self.overwriteSetting(fileURL: fileURL)
    }
    
    
    /// Update the managed setting list by applying the given change.
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
    
    /// Force importing the setting at the passed-in URL.
    ///
    /// - Parameter fileURL: The URL of the file to import.
    /// - Throws: `SettingFileError`
    private func overwriteSetting(fileURL: URL) throws {
        
        let name = self.settingName(from: fileURL)
        let destURL = self.preparedURLForUserSetting(name: name)
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
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
            throw SettingFileError(kind: .importFailed, name: name, error: error)
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
    
    
    var errorDescription: String? {
        
        switch self {
            case .empty:
                return "Name can’t be empty.".localized
            case .containSlash:
                return "You can’t use a name that contains “/”.".localized
            case .startWithDot:
                return "You can’t use a name that begins with a dot “.”.".localized
            case .duplicated(let name):
                return String(localized: "The name “\(name)” is already taken.")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        "Please choose another name.".localized
    }
}



struct SettingFileError: LocalizedError {
    
    enum ErrorKind {
        
        case deletionFailed
        case importFailed
        case noSourceFile
    }
    
    var kind: ErrorKind
    var name: String
    var error: NSError?
    
    
    var errorDescription: String? {
        
        switch self.kind {
            case .deletionFailed:
                return String(localized: "“\(self.name)” couldn’t be deleted.")
            case .importFailed:
                return String(localized: "“\(self.name)” couldn’t be imported.")
            case .noSourceFile:
                return String(localized: "No original file for “\(self.name)” was found.")
        }
    }
    
    
    var recoverySuggestion: String? {
        
        self.error?.localizedRecoverySuggestion
    }
}



struct ImportDuplicationError: LocalizedError, RecoverableError {
    
    var name: String
    var type: UTType
    var replacingClosure: (() throws -> Void)
    
    
    var errorDescription: String? {
        
        switch self.type {
            case .yaml:
                return String(localized: "A new style named “\(self.name)” will be installed, but a custom style with the same name already exists.")
            case .cotTheme:
                return String(localized: "A new theme named “\(self.name)” will be installed, but a custom theme with the same name already exists.")
            case .cotReplacement:
                return String(localized: "A new replacement definition named “\(self.name)” will be installed, but a definition with the same name already exists.")
            default:
                fatalError()
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.type {
            case .yaml:
                return "Do you want to replace it?\nReplaced style can’t be restored.".localized
            case .cotTheme:
                return "Do you want to replace it?\nReplaced theme can’t be restored.".localized
            case .cotReplacement:
                return "Do you want to replace it?\nReplaced definition can’t be restored.".localized
            default:
                fatalError()
        }
    }
    
    
    var recoveryOptions: [String] {
        
        ["Cancel".localized,
         "Replace".localized]
    }
    
    
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        
        switch recoveryOptionIndex {
            case 0:  // == Cancel
                return false
            
            case 1:  // == Replace
                do {
                    try self.replacingClosure()
                } catch {
                    NSApp.presentError(error)
                    return false
                }
                return true
            
            default:
                preconditionFailure()
        }
    }
}
