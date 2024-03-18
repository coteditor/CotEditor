//
//  Bundle+AppInfo.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-10-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2023 1024jp
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

extension Bundle {
    
    /// The application name.
    final var bundleName: String {
        
        self.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
    }
    
    
    /// The human-friendly version expression (semantic versioning).
    final var shortVersion: String {
        
        self.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    
    
    /// The build number.
    final var bundleVersion: String {
        
        self.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    }
    
    /// The human-readable copyright.
    final var copyright: String {
        
        self.object(forInfoDictionaryKey: "NSHumanReadableCopyright" as String) as! String
    }
    
    
    /// The help book name.
    final var helpBookName: String? {
        
        self.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String
    }
    
    
    /// Is the running app a pre-release version?
    final var isPrerelease: Bool {
        
        // -> Pre-release versions contain non-digit letter.
        self.shortVersion.contains(/[^0-9.]/)
    }
}
