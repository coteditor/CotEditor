/*
 
 ReplacementManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-03-18.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

final class ReplacementManager: SettingFileManager {
    
    // MARK: Public Properties
    
    static let shared = ReplacementManager()
    
    private(set) var settings = [String: BatchReplacement]()
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        super.init()
        
        self.loadUserSettings()
    }
    
    
    
    // MARK: Setting File Manager Methods
    
    /// directory name in both Application Support and bundled Resources
    override var directoryName: String {
        
        return "Replacements"
    }
    
    
    /// path extension for user setting file
    override var filePathExtension: String {
        
        return DocumentType.replacement.extensions[0]
    }
    
    
    /// name of setting file type
    override var settingFileType: SettingFileType {
        
        return .replacement
    }
    
    
    /// list of names of setting file name (without extension)
    override var settingNames: [String] {
        
        return self.settings.keys.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
    
    
    /// list of names of setting file name which are bundled (without extension)
    override var bundledSettingNames: [String] {
        
        return []
    }
    
    
    
    // MARK: Public Methods
    
    /// delete theme file corresponding to the theme name
    override func removeSetting(name settingName: String) throws {
        
        try super.removeSetting(name: settingName)
        
        self.updateCache()
    }
    
    
    /// save
    func save(replacement: BatchReplacement, name settingName: String, completionHandler: ((Void) -> Void)? = nil) throws {  // @escaping
        
        // create directory to save in user domain if not yet exist
        try self.prepareUserSettingDirectory()
        
        let fileURL = self.preparedURLForUserSetting(name: settingName)
        let data = try replacement.jsonData()
        
        try data.write(to: fileURL, options: .atomic)
        
        self.updateCache {
            completionHandler?()
        }
    }
    
    
    /// create a new untitled setting
    func createUntitledSetting(completionHandler: ((String) -> Void)? = nil) throws {  // @escaping
        
        let name = self.savableSettingName(for: NSLocalizedString("Untitled", comment: ""))
        let batchReplacement = BatchReplacement(replacements: [Replacement()])
        
        try self.save(replacement: batchReplacement, name: name) {
            completionHandler?(name)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// update internal cache data
    override func loadUserSettings() {
        
        // load settings if exists
        let userDirURL = self.userSettingDirectoryURL
        self.settings = (try? FileManager.default.contentsOfDirectory(at: userDirURL, includingPropertiesForKeys: nil,
                                                                      options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]))?
            .filter { $0.pathExtension == self.filePathExtension }
            .flatDictionary { (url) in
                guard let setting = try? BatchReplacement(url: url) else { return nil }
                
                let name = self.settingName(from: url)
                
                return (name, setting)
            } ?? [:]
    }
    
}
