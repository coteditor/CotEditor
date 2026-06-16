//
//  NSWorkspace.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-06-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

import AppKit

extension NSWorkspace {
    
    /// Opens the given files with the first available application other than this app.
    ///
    /// - Parameter fileURLs: The file URLs to open.
    func openWithOtherApplication(_ fileURLs: [URL]) {
        
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let configuration = NSWorkspace.OpenConfiguration()
        
        for fileURL in fileURLs {
            guard
                let appURL = self.urlsForApplications(toOpen: fileURL)
                    .first(where: { Bundle(url: $0)?.bundleIdentifier != bundleIdentifier })
            else { continue }
            
            self.open([fileURL], withApplicationAt: appURL, configuration: configuration)
        }
    }
}
