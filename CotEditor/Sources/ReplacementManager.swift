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
    
    private(set) var settings = [BatchReplacement]()
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override private init() {
        
        super.init()
        
        // cache user settings asynchronously but wait until the process will be done
        let semaphore = DispatchSemaphore(value: 0)
        self.updateCache {
            semaphore.signal()
        }
        while semaphore.wait(timeout: .now()) == .timedOut {
            RunLoop.current.run(mode: .defaultRunLoopMode, before: .distantFuture)
        }
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
        
        return self.settings
            .map { $0.name }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
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
    func save(replacement: BatchReplacement, completionHandler: ((Error?) -> Void)? = nil) {  // @escaping
        
        // create directory to save in user domain if not yet exist
        do {
            try self.prepareUserSettingDirectory()
        } catch {
            completionHandler?(error)
            return
        }
        
        let fileURL = self.preparedURLForUserSetting(name: replacement.name)
        
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
    
    
    /// create a new untitled theme
    func createUntitledSetting(completionHandler: ((String, Error?) -> Void)? = nil) {  // @escaping
        
        var newName = NSLocalizedString("Untitled", comment: "")
        
        // append "Copy n" if "Untitled" already exists
        if self.urlForUserSetting(name: newName) != nil {
            newName = self.copiedSettingName(newName)
        }
        
        let replacement = BatchReplacement(name: newName)
        
        self.save(replacement: replacement) { (error: Error?) in
            completionHandler?(newName, error)
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// update internal cache data
    override func updateCache(completionHandler: (() -> Void)? = nil) {  // @escaping
        
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            
            // load settings if exists
            let userDirURL = strongSelf.userSettingDirectoryURL
            let settings: [BatchReplacement] = (try? FileManager.default.contentsOfDirectory(at: userDirURL, includingPropertiesForKeys: nil,
                                                                                         options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]))?
                .filter { $0.pathExtension == strongSelf.filePathExtension }
                .flatMap { try? BatchReplacement(url: $0) } ?? []
            
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
