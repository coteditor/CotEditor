//
//  SettingManaging.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2018 1024jp
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

protocol SettingManaging: AnyObject {
    
    /// directory name in both Application Support and bundled Resources
    static var directoryName: String { get }
}



extension SettingManaging {
    
    /// user setting directory URL in Application Support
    var userSettingDirectoryURL: URL {
        
        supportDirectoryURL.appendingPathComponent(Self.directoryName)
    }
    
    
    /// create user setting directory if not yet exist
    func prepareUserSettingDirectory() throws {
        
        try FileManager.default.createDirectory(at: self.userSettingDirectoryURL, withIntermediateDirectories: true)
    }
}



// MARK: Private Property

/// application's support directory in user's `Application Suuport/`
private let supportDirectoryURL: URL = try! FileManager.default
    .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    .appendingPathComponent("CotEditor")
