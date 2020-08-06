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
//  © 2016-2020 1024jp
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

enum SettingFileType {
    
    case syntaxStyle
    case theme
    case replacement
}


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
    
    /// Publishes when the line-up of setting files did update.
    var didUpdateSettingList: PassthroughSubject<[String], Never> { get }
    
    /// Publishes when a setting file is updated with new/previous setting names.
    var didUpdateSetting: PassthroughSubject<SettingChange, Never> { get }
    
    
    /// directory name in both Application Support and bundled Resources
    static var directoryName: String { get }
    
    /// path extensions for user setting file
    var filePathExtensions: [String] { get }
    
    /// setting file type
    var settingFileType: SettingFileType { get }
    
    /// list of names of setting file name (without extension)
    var settingNames: [String] { get set }
    
    /// list of names of setting file name which are bundled (without extension)
    var bundledSettingNames: [String] { get }
    
    /// stored settings to avoid loading frequently-used setting files multiple times
    var cachedSettings: [String: Setting] { get set }
    
    
    /// return setting instance corresponding to the given setting name
    func setting(name: String) -> Setting?
    
    /// load settings in the user domain
    func loadSetting(at fileURL: URL) throws -> Setting
    
    /// load settings in the user domain
    func checkUserSettings()
    
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
    
    /// default path extension for user setting file
    var filePathExtension: String {
        
        return self.filePathExtensions.first!
    }
    
    
    /// file urls for user settings
    var userSettingFileURLs: [URL] {
        
        return (try? FileManager.default.contentsOfDirectory(at: self.userSettingDirectoryURL,
                                                             includingPropertiesForKeys: nil,
                                                             options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]))?
            .filter { self.filePathExtensions.contains($0.pathExtension) } ?? []
    }
    
    
    /// create setting name from a URL (don't care if it exists)
    func settingName(from fileURL: URL) -> String {
        
        return fileURL.deletingPathExtension().lastPathComponent
    }
    
    
    /// return a valid setting file URL for the setting name or nil if not exists
    func urlForUsedSetting(name: String) -> URL? {
        
        return self.urlForUserSetting(name: name) ?? self.urlForBundledSetting(name: name)
    }
    
    
    /// return a setting file URL in the application's Resources domain or nil if not exists
    func urlForBundledSetting(name: String) -> URL? {
        
        return Bundle.main.url(forResource: name, withExtension: self.filePathExtension, subdirectory: Self.directoryName)
    }
    
    
    /// return a setting file URL in the user's Application Support domain or nil if not exists
    func urlForUserSetting(name: String) -> URL? {
        
        let url = self.preparedURLForUserSetting(name: name)
        
        return url.isReachable ? url : nil
    }
    
    
    /// return a setting file URL in the user's Application Support domain (don't care if it exists)
    func preparedURLForUserSetting(name: String) -> URL {
        
        return self.userSettingDirectoryURL.appendingPathComponent(name).appendingPathExtension(self.filePathExtension)
    }
    
    
    /// whether the setting name is one of the bundled settings
    func isBundledSetting(name: String) -> Bool {
        
        return self.bundledSettingNames.contains(name)
    }
    
    
    /// whether the setting name is one of the bundled settings that is customized by user
    func isCustomizedBundledSetting(name: String) -> Bool {
        
        return self.isBundledSetting(name: name) && (self.urlForUserSetting(name: name) != nil)
    }
    
    
    /// return setting name appending number suffix without extension
    func savableSettingName(for proposedName: String, appendingCopySuffix: Bool = false) -> String {
        
        let suffix = appendingCopySuffix ? "copy".localized(comment: "copied file suffix") : nil
        
        return self.settingNames.createAvailableName(for: proposedName, suffix: suffix)
    }
    
    
    /// validate whether the setting name is valid (for a file name) and throw an error if not
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
        
        if let duplicatedSettingName = self.settingNames.first(where: { $0.caseInsensitiveCompare(settingName) == .orderedSame }) {
            throw InvalidNameError.duplicated(name: duplicatedSettingName)
        }
    }
    
    
    /// delete user's setting file for the setting name
    ///
    /// - Throws: `SettingFileError`
    func removeSetting(name: String) throws {
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            
        } catch let error as NSError {
            throw SettingFileError(kind: .deletionFailed, name: name, error: error)
        }
        
        self.cachedSettings[name] = nil
        
        let change: SettingChange = .removed(name)
        self.updateSettingList(change: change)
        self.didUpdateSetting.send(change)
    }
    
    
    /// restore the setting with name
    func restoreSetting(name: String) throws {
        
        guard self.isBundledSetting(name: name) else { return }  // only bundled setting can be restored
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        try FileManager.default.removeItem(at: url)
        
        self.cachedSettings[name] = nil
        
        let change: SettingChange = .updated(from: name, to: name)
        self.updateSettingList(change: change)
        self.didUpdateSetting.send(change)
    }
    
    
    /// duplicate the setting with name
    func duplicateSetting(name: String) throws {
        
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
        self.didUpdateSetting.send(change)
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
        self.didUpdateSetting.send(change)
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
    
    
    /// import setting at passed-in URL
    ///
    /// - Throws: `SettingFileError`
    func importSetting(fileURL: URL) throws {
        
        let importName = self.settingName(from: fileURL)
        
        // check duplication
        for name in self.settingNames {
            guard name.caseInsensitiveCompare(importName) == .orderedSame else { continue }
            
            guard self.urlForUserSetting(name: name) == nil else {  // duplicated
                throw ImportDuplicationError(name: name, type: self.settingFileType, replacingClosure: { [unowned self] in
                    try self.overwriteSetting(fileURL: fileURL)
                })
            }
        }
        
        try self.overwriteSetting(fileURL: fileURL)
    }
    
    
    /// Reload internal cache data from the user domain.
    func updateSettingList(change: SettingChange) {
        
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
        
        self.didUpdateSettingList.send(self.settingNames)
    }
    
    
    /// Reload internal cache data from the user domain.
    func reloadCache() {
        
        DispatchQueue.global(qos: .utility).async { [weak self, previousSettingNames = self.settingNames] in
            guard let self = self else { return assertionFailure() }
            
            self.checkUserSettings()
            
            guard self.settingNames != previousSettingNames else { return }
            
            DispatchQueue.main.sync {
                self.didUpdateSettingList.send(self.settingNames)
            }
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// force import setting at passed-in URL
    ///
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
        let change: SettingChange = self.settingNames.contains(name) ? .updated(from: name, to: name) : .added(name)
        self.updateSettingList(change: change)
        self.didUpdateSetting.send(change)
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
                return String(format: "The name “%@” is already taken.".localized, name)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        return "Please choose another name.".localized
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
                return String(format: "“%@” couldn’t be deleted.".localized, self.name)
            case .importFailed:
                return String(format: "“%@” couldn’t be imported.".localized, self.name)
            case .noSourceFile:
                return String(format: "No original file for “%@” was found.".localized, self.name)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        return self.error?.localizedRecoverySuggestion
    }
    
}



struct ImportDuplicationError: LocalizedError, RecoverableError {
    
    var name: String
    var type: SettingFileType
    var replacingClosure: (() throws -> Void)
    
    
    var errorDescription: String? {
        
        switch self.type {
            case .syntaxStyle:
                return String(format: "A new style named “%@” will be installed, but a custom style with the same name already exists.".localized, self.name)
            case .theme:
                return String(format: "A new theme named “%@” will be installed, but a custom theme with the same name already exists.".localized, self.name)
            case .replacement:
                return String(format: "A new replacement definition named “%@” will be installed, but a definition with the same name already exists.".localized, self.name)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.type {
            case .syntaxStyle:
                return "Do you want to replace it?\nReplaced style can’t be restored.".localized
            case .theme:
                return "Do you want to replace it?\nReplaced theme can’t be restored.".localized
            case .replacement:
                return "Do you want to replace it?\nReplaced definition can’t be restored.".localized
        }
    }
    
    
    var recoveryOptions: [String] {
        
        return ["Cancel".localized,
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
