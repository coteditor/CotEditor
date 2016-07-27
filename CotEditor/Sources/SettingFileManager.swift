/*
 
 SettingFileManager.swift
 
 CotEditor
 http://coteditor.com
 
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

class SettingFileManager: SettingManager {
    
    /// General notification's userInfo keys
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
    
    
    /// list of names of setting file name (without extension)
    var settingNames: [String] {
        
        preconditionFailure()
    }
    
    
    /// list of names of setting file name which are bundled (without extension)
    var bundledSettingNames: [String] {
        
        preconditionFailure()
    }
    
    
    /// update internal cache data
    func updateCache(completionHandler: (() -> Void)?) {
        
        preconditionFailure()
    }
    
    
    
    // MARK: Error Recovery Attempting Protocol
    
    /// recover error
    override func attemptRecovery(fromError error: NSError, optionIndex recoveryOptionIndex: Int) -> Bool {
        
        guard error.domain == CotEditorError.domain,
            let code = CotEditorError(rawValue: error.code) else { return false }
        
        switch code {
        case .settingImportFileDuplicated:
            switch recoveryOptionIndex {
            case 0:  // == Cancel
                break
                
            case 1: // == Replace
                guard let fileURL = error.userInfo[NSURLErrorKey] as? URL else { return false }
                do {
                    try self.overwriteSetting(fileURL: fileURL)
                } catch let anotherError as NSError {
                    NSApp.presentError(anotherError)
                    return false
                }
                return true
                
            default:
                break
            }
            
        default:
            break
        }
        
        return false
    }
    
    
    
    // MARK: Public Methods
    
    /// create setting name from a URL (don't care if it exists)
    func settingName(from fileURL: URL) -> String {
        
        return (try? fileURL.deletingPathExtension())?.lastPathComponent ?? "New Style"
    }
    
    
    /// return a valid setting file URL for the setting name or nil if not exists
    func urlForUsedSetting(name: String) -> URL? {
        
        return self.urlForUserSetting(name: name) ?? self.urlForBundledSetting(name: name)
    }
    
    
    /// return a setting file URL in the application's Resources domain (if available is YES, returns URL only if the file exists)
    func urlForBundledSetting(name: String) -> URL? {
        
        return Bundle.main.urlForResource(name, withExtension: self.filePathExtension, subdirectory: self.directoryName)
    }
    
    
    /// return a setting file URL in the user's Application Support domain or nil if not exists
    func urlForUserSetting(name: String) -> URL? {
        
        let url = self.preparedURLForUserSetting(name: name)
        
        return url.isReachable ? url : nil
    }
    
    
    /// return a setting file URL in the user's Application Support domain (don't care if it exists)
    func preparedURLForUserSetting(name: String) -> URL {
        
        return try! self.userSettingDirectoryURL.appendingPathComponent(name).appendingPathExtension(self.filePathExtension)
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
        
        let regex = try! RegularExpression(pattern: localizedCopy + "$")
        var copiedStringRange = regex.rangeOfFirstMatch(in: baseName, range: baseName.nsRange)
        if copiedStringRange.location == NSNotFound {
            let numberRegex = try! RegularExpression(pattern: localizedCopy + " [0-9]+$")
            copiedStringRange = numberRegex.rangeOfFirstMatch(in: baseName, range: baseName.nsRange)
        }
        
        let copyBase: String = {
            if copiedStringRange.location != NSNotFound {
                return (baseName as NSString).substring(to: copiedStringRange.location) + localizedCopy
            }
            return baseName + localizedCopy
        }()
        
        // increase number suffix
        var copiedName = copyBase
        var count = 2
        while self.settingNames.contains(copiedName) {
            copiedName = copyBase + " " + String(count)
            count += 1
        }
        
        return copiedName
    }
    
    
    /// validate whether the file name is valid (for a file name) and returns error if not
    func validate(settingName: String, originalName: String) throws {
        
        // just case difference is OK
        guard settingName.caseInsensitiveCompare(originalName) != .orderedSame else { return }
        
        let description: String? = {
            if settingName.isEmpty {  // empty
                return NSLocalizedString("Name can’t be empty.", comment: "")
                
            } else if settingName.contains("/") {  // Containing "/" is invalid for a file name.
                return NSLocalizedString("You can’t use a name that contains “/”.", comment: "")
                
            } else if settingName.hasPrefix(".") {  // Starting with "." is invalid for a file name.
                return NSLocalizedString("You can’t use a name that begins with a dot “.”.", comment: "")
                
            } else if let duplicatedSettingName = self.settingNames.filter({ $0.caseInsensitiveCompare(settingName) == .orderedSame }).first {  // already exists
                return String(format: NSLocalizedString("The name “%@” is already taken.", comment: ""), duplicatedSettingName)
            }
            return nil
        }()
        
        if let description = description {
            throw NSError(domain: CotEditorError.domain, code: CotEditorError.invalidName.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: description,
                                     NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please choose another name.", comment: "")])
        }
    }
    
    
    /// delete user's file for the setting name
    func removeSetting(name: String) throws {
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            
        } catch let error as NSError {
            throw NSError(domain: CotEditorError.domain, code: CotEditorError.settingDeletionFailed.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: String(format: NSLocalizedString("“%@” couldn’t be deleted.", comment: ""), name),
                                     NSLocalizedRecoverySuggestionErrorKey: error.localizedRecoverySuggestion ?? NSNull(),
                                     NSURLErrorKey: url,
                                     NSUnderlyingErrorKey: error])
        }
    }
    
    
    /// restore the setting with name
    func restoreSetting(name: String) throws {
        
        guard let url = self.urlForUserSetting(name: name) else { return }  // not exist or already removed
        
        try FileManager.default.removeItem(at: url)
    }
    
    
    /// duplicate the setting with name
    func duplicateSetting(name: String) throws {
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        let newName = self.copiedSettingName(name)
        
        guard let sourceURL = self.urlForUsedSetting(name: name) else {
            throw NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: [:])  // throw a dummy error
        }
        
        try FileManager.default.copyItem(at: sourceURL,
                                         to: self.preparedURLForUserSetting(name: newName))
        
        self.updateCache(completionHandler: nil)
    }
    
    
    /// rename the setting with name
    func renameSetting(name: String, to newName: String) throws {
        
        let sanitizedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        try self.validate(settingName: sanitizedName, originalName: name)
        
        try FileManager.default.moveItem(at: self.preparedURLForUserSetting(name: name),
                                         to: self.preparedURLForUserSetting(name: sanitizedName))
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
    func importSetting(fileURL: URL) throws {
        
        let importName = self.settingName(from: fileURL)
        
        // check duplication
        for name in self.settingNames {
            guard name.caseInsensitiveCompare(importName) == .orderedSame else { continue }
            
            guard self.urlForUserSetting(name: name) == nil else {  // duplicated
                throw NSError(domain: CotEditorError.domain, code: CotEditorError.settingImportFileDuplicated.rawValue,
                              userInfo: [NSLocalizedDescriptionKey: String(format: NSLocalizedString("A new setting named “%@” will be installed, but a custom setting with the same name already exists.", comment: ""), importName),
                                         NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Do you want to replace it?\nReplaced setting can’t be restored.", comment: ""),
                                         NSLocalizedRecoveryOptionsErrorKey: [NSLocalizedString("Cancel", comment: ""),
                                                                              NSLocalizedString("Replace", comment: "")],
                                         NSRecoveryAttempterErrorKey: self,
                                         NSURLErrorKey: fileURL])
            }
        }
        
        try self.overwriteSetting(fileURL: fileURL)
    }
    
    
    
    // MARK: Private Methods
    
    /// force import setting at passed-in URL
    private func overwriteSetting(fileURL: URL) throws {
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        let name = self.settingName(from: fileURL)
        let destURL = self.preparedURLForUserSetting(name: name)
        
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
            throw NSError(domain: CotEditorError.domain, code: CotEditorError.settingImportFailed.rawValue,
                          userInfo: [NSLocalizedDescriptionKey: String(format: NSLocalizedString("“%@” couldn’t be imported.", comment: ""), name),
                                     NSLocalizedRecoverySuggestionErrorKey: error.localizedRecoverySuggestion ?? NSNull(),
                                     NSURLErrorKey: fileURL,
                                     NSUnderlyingErrorKey: error])
        }
        
        // update internal cache
        self.updateCache(completionHandler: nil)
    }
    
}
