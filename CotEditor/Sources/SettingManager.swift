/*
 
 SettingManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-11.
 
 ------------------------------------------------------------------------------
 
 © 2016-2018 1024jp
 
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

protocol SettingManagerProtocol: class {
    
    /// directory name in both Application Support and bundled Resources
    var directoryName: String { get }
}



class SettingManager: SettingManagerProtocol {
    
    // MARK: Abstract Properties
    
    var directoryName: String { preconditionFailure() }
    
    
    
    // MARK: Public Properties/Methods
    
    /// user setting directory URL in Application Support
    final lazy var userSettingDirectoryURL: URL = type(of: self).supportDirectoryURL.appendingPathComponent(self.directoryName)
    
    
    /// create user setting directory if not yet exist
    final func prepareUserSettingDirectory() throws {
        
        let directoryURL = self.userSettingDirectoryURL
        let isDirectory = (try? directoryURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false) ?? false
        
        guard !isDirectory else { return }
        
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
    
    
    
    // MARK: Private Property
    
    /// application's support directory in user's `Application Suuport/`
    private static let supportDirectoryURL: URL = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                                               appropriateFor: nil, create: false).appendingPathComponent("CotEditor")
    
}
