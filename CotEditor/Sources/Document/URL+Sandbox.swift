//
//  URL+Sandbox.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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
import AppKit

extension URL {
    
    /// Requests sandbox access for the receiver to the user by presenting an open panel when needed.
    ///
    /// If the URL is already readable, the method returns immediately without showing any UI.
    ///
    /// - Throws: `CancellationError` if the user cancels the Open panel without granting access.
    @MainActor func grantAccess() throws(CancellationError) {
        
        guard
            (try? self.checkResourceIsReachable()) == true,
            !FileManager.default.isReadableFile(atPath: self.path)
        else { return }
        
        let openPanel = NSOpenPanel()
        openPanel.directoryURL = self
        openPanel.message = String(localized: "GrantAccessPanel.message",
                                   defaultValue: "Open the original location to grant CotEditor access.",
                                   comment: "message in the Open dialog to grant the access permission to open an alias location.")
        
        let delegate = GrantAccessDelegate(validURL: self)
        openPanel.delegate = delegate
        
        guard openPanel.runModal() == .OK else {
            throw CancellationError()
        }
    }
}


private final class GrantAccessDelegate: NSObject, NSOpenSavePanelDelegate {
    
    private let validURL: URL
    
    
    init(validURL: URL) {
        
        self.validURL = validURL
    }
    
    
    // MARK: Open Save Panel Delegate
    
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
    
        url == self.validURL
    }
}
