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

extension Notification.Name {
    
    static let ReplacementListDidUpdate = Notification.Name("ReplacementListDidUpdate")
}


final class ReplacementManager: SettingFileManager {
    
    // MARK: Public Properties
    
    static let shared = ReplacementManager()
    
    private(set) var settings = [String: BatchReplacement]()
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        super.init()
        
        self.updateCache()
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
    func save(replacement: BatchReplacement, name settingName: String, completionHandler: ((Error?) -> Void)? = nil) {  // @escaping
        
        // create directory to save in user domain if not yet exist
        do {
            try self.prepareUserSettingDirectory()
        } catch {
            completionHandler?(error)
            return
        }
        
        let fileURL = self.preparedURLForUserSetting(name: settingName)
        
        do {
            let data = try replacement.jsonData()
            
            try data.write(to: fileURL, options: .atomic)
            
        } catch {
            completionHandler?(error)
            return
        }
        
        self.updateCache {
            completionHandler?(nil)
        }
    }
    
    
    /// create a new untitled setting
    func createUntitledSetting(completionHandler: ((String, Error?) -> Void)? = nil) {  // @escaping
        
        let name = self.savableSettingName(for: NSLocalizedString("Untitled", comment: ""))
        let batchReplacement = BatchReplacement(replacements: [Replacement()])
        
        self.save(replacement: batchReplacement, name: name) { (error: Error?) in
            completionHandler?(name, error)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// update internal cache data
    override func updateCache(completionHandler: (() -> Void)? = nil) {  // @escaping
        
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            
            // load settings if exists
            let userDirURL = strongSelf.userSettingDirectoryURL
            let settings: [String: BatchReplacement] = (try? FileManager.default.contentsOfDirectory(at: userDirURL, includingPropertiesForKeys: nil,
                                                                                         options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]))?
                .filter { $0.pathExtension == strongSelf.filePathExtension }
                .flatDictionary { (url) in
                    guard
                        let name = self?.settingName(from: url),
                        let setting =  try? BatchReplacement(url: url)
                        else { return nil }
                    
                    return (name, setting)
                } ?? [:]
            
            let isListUpdated = (settings != strongSelf.settings)
            strongSelf.settings = settings
            
            DispatchQueue.main.sync {
                // post notification
                if isListUpdated {
                    NotificationCenter.default.post(name: .ReplacementListDidUpdate, object: self)
                }
                
                completionHandler?()
            }
        }
    }
    
}
