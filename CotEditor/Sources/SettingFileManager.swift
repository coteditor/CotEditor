/*
 
 SettingFileManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-11.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation
import AppKit.NSApplication

enum SettingFileType {
    case syntaxStyle
    case theme
}



class SettingFileManager: SettingManager {
    
    /// general notification's userInfo keys
    enum NotificationKey {
        
        static let old = "OldNameKey"
        static let new = "NewNameKey"
    }
    
    
    
    // MARK: -
    // MARK: Abstract Methods
    
    /// path extension for user setting file
    var filePathExtension: String {
        
        preconditionFailure()
    }
    
    
    /// setting file type
    var settingFileType: SettingFileType {
        
        preconditionFailure()
    }
    
    
    /// list of names of setting file name (without extension)
    var settingNames: [String] {
        
        preconditionFailure()
    }
    
    
    /// list of names of setting file name which are bundled (without extension)
    var bundledSettingNames: [String] {
        
        preconditionFailure()
    }
    
    
    /// update internal cache data
    func updateCache(completionHandler: (() -> Void)? = nil) {  // @escaping
        
        preconditionFailure()
    }
    
    
    
    // MARK: Public Methods
    
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
        
        return Bundle.main.url(forResource: name, withExtension: self.filePathExtension, subdirectory: self.directoryName)
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
    
    
    /// return setting name appending localized " Copy" + number suffix without extension
    func copiedSettingName(_ originalName: String) -> String {
        
        let baseName = originalName.trimmingCharacters(in: .whitespacesAndNewlines)
        let localizedCopy = " " + NSLocalizedString("copy", comment: "copied file suffix")
        
        let regex = try! NSRegularExpression(pattern: localizedCopy + "( [0-9]+)?$")
        let copySuffixRange = regex.rangeOfFirstMatch(in: baseName, range: baseName.nsRange)
        
        let copyBaseName: String = {
            if copySuffixRange.location != NSNotFound {
                return (baseName as NSString).substring(to: copySuffixRange.location) + localizedCopy
            }
            return baseName + localizedCopy
        }()
        
        // increase number suffix
        var copiedName = copyBaseName
        var count = 2
        while self.settingNames.contains(copiedName) {
            copiedName = copyBaseName + " " + String(count)
            count += 1
        }
        
        return copiedName
    }
    
    
    /// validate whether the setting name is valid (for a file name) and throw an error if not
    func validate(settingName: String, originalName: String) throws {
        
        // just case difference is OK
        guard settingName.caseInsensitiveCompare(originalName) != .orderedSame else { return }
        
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
    /// - throws: SettingFileError
    func removeSetting(name: String) throws {
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            
        } catch let error as NSError {
            throw SettingFileError(kind: .deletionFailed, name: name, error: error)
        }
    }
    
    
    /// restore the setting with name
    func restoreSetting(name: String) throws {
        
        guard self.isBundledSetting(name: name) else { return }  // only bundled setting can be restored
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        try FileManager.default.removeItem(at: url)
    }
    
    
    /// duplicate the setting with name
    func duplicateSetting(name: String) throws {
        
        let newName = self.copiedSettingName(name)
        
        guard let sourceURL = self.urlForUsedSetting(name: name) else {
            throw SettingFileError(kind: .noSourceFile, name: name, error: nil)
        }
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        try FileManager.default.copyItem(at: sourceURL,
                                         to: self.preparedURLForUserSetting(name: newName))
        
        self.updateCache()
    }
    
    
    /// rename the setting with name
    func renameSetting(name: String, to newName: String) throws {
        
        let sanitizedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        try self.validate(settingName: sanitizedNewName, originalName: name)
        
        try FileManager.default.moveItem(at: self.preparedURLForUserSetting(name: name),
                                         to: self.preparedURLForUserSetting(name: sanitizedNewName))
    }
    
    
    /// export setting file to passed-in URL
    func exportSetting(name: String, to fileURL: URL) throws {
        
        let sourceURL = self.preparedURLForUserSetting(name: name)
        
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: sourceURL, options: .withoutChanges,
                                       writingItemAt: fileURL, options: .forMoving, error: &error)
        { (newReadingURL, newWritingURL) in
            
            do {
                try FileManager.default.copyItem(at: newReadingURL, to: newWritingURL)
                
            } catch let writingError as NSError {
                error = writingError
            }
        }
        
        if let error = error {
            throw error
        }
    }
    
    
    /// import setting at passed-in URL
    /// - throws: SettingFileError
    func importSetting(fileURL: URL) throws {
        
        let importName = self.settingName(from: fileURL)
        
        // check duplication
        for name in self.settingNames {
            guard name.caseInsensitiveCompare(importName) == .orderedSame else { continue }
            
            guard self.urlForUserSetting(name: name) == nil else {  // duplicated
                throw ImportDuplicationError(name: name, url: fileURL, type: self.settingFileType, attempter: self)
            }
        }
        
        try self.overwriteSetting(fileURL: fileURL)
    }
    
    
    
    // MARK: Private Methods
    
    /// force import setting at passed-in URL
    /// - throws: SettingFileError
    fileprivate func overwriteSetting(fileURL: URL) throws {
        
        let name = self.settingName(from: fileURL)
        let destURL = self.preparedURLForUserSetting(name: name)
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        // copy file
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: fileURL, options: [.withoutChanges, .resolvesSymbolicLink],
                                       writingItemAt: destURL, options: .forReplacing, error: &error)
        { (newReadingURL, newWritingURL) in
            
            do {
                if newWritingURL.isReachable {
                    try FileManager.default.removeItem(at: newWritingURL)
                }
                try FileManager.default.copyItem(at: newReadingURL, to: newWritingURL)
                
            } catch let writingError as NSError {
                error = writingError
            }
        }
        
        if let error = error {
            throw SettingFileError(kind: .importFailed, name: name, error: error)
        }
        
        // update internal cache
        self.updateCache()
    }
    
}



// MARK: - Error

enum InvalidNameError: LocalizedError {
    
    case empty
    case containSlash
    case startWithDot
    case duplicated(name: String)
    
    
    var errorDescription: String? {
        
        switch self {
        case .empty:
            return NSLocalizedString("Name can’t be empty.", comment: "")
            
        case .containSlash:
            return NSLocalizedString("You can’t use a name that contains “/”.", comment: "")
            
        case .startWithDot:
            return NSLocalizedString("You can’t use a name that begins with a dot “.”.", comment: "")
            
        case .duplicated(let name):
            return String(format: NSLocalizedString("The name “%@” is already taken.", comment: ""), name)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        return NSLocalizedString("Please choose another name.", comment: "")
    }
    
}



struct SettingFileError: LocalizedError {
    
    enum ErrorKind {
        case deletionFailed
        case importFailed
        case noSourceFile
    }
    
    let kind: ErrorKind
    let name: String
    let error: NSError?
    
    
    var errorDescription: String? {
        
        switch self.kind {
        case .deletionFailed:
            return String(format: NSLocalizedString("“%@” couldn’t be deleted.", comment: ""), self.name)
        case .importFailed:
            return String(format: NSLocalizedString("“%@” couldn’t be imported.", comment: ""), self.name)
        case .noSourceFile:
            return String(format: NSLocalizedString("No original file for “%@” was found.", comment: ""), self.name)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        return self.error?.localizedRecoverySuggestion
    }
    
}



struct ImportDuplicationError: LocalizedError, RecoverableError {
    
    let name: String
    let url: URL
    let type: SettingFileType
    let attempter: SettingFileManager
    
    
    var errorDescription: String? {
        
        switch self.type {
        case .syntaxStyle:
            return String(format: NSLocalizedString("A new style named “%@” will be installed, but a custom style with the same name already exists.", comment: ""), self.name)
            
        case .theme:
            return String(format: NSLocalizedString("A new theme named “%@” will be installed, but a custom theme with the same name already exists.", comment: ""), self.name)
        }
    }
    
    
    var recoverySuggestion: String? {
        
        switch self.type {
        case .syntaxStyle:
            return NSLocalizedString("Do you want to replace it?\nReplaced style can’t be restored.", comment: "")
            
        case .theme:
            return NSLocalizedString("Do you want to replace it?\nReplaced theme can’t be restored.", comment: "")
        }
    }
    
    
    var recoveryOptions: [String] {
        
        return [NSLocalizedString("Cancel", comment: ""),
                NSLocalizedString("Replace", comment: "")]
    }
    
    
    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        
        switch recoveryOptionIndex {
        case 0:  // == Cancel
            return false
            
        case 1: // == Replace
            do {
                try self.attempter.overwriteSetting(fileURL: self.url)
            } catch let anotherError {
                NSApp.presentError(anotherError)
                return false
            }
            return true
            
        default:
            return false
        }
    }
    
}
