//
//  CommandLineToolManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2024 1024jp
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
import URLUtils

final class CommandLineToolManager: Sendable {
    
    enum Status {
        
        case none
        case validTarget
        case differentTarget
        case invalidTarget
        
        var installed: Bool { self != .none }
    }
    
    
    // MARK: Public Methods
    
    static let shared = CommandLineToolManager(bundle: .main)
    
    
    // MARK: Public Properties
    
    let linkURL: URL
    
    private let bundledCommandURL: URL
    private let preferredLinkURL: URL
    private let preferredApplicationURL: URL  // path to .app in /Applications directory
    
    
    // MARK: Public Methods
    
    private init(bundle: Bundle) {
        
        self.bundledCommandURL = bundle.cotURL!
        self.preferredLinkURL = URL(filePath: "/usr/local/bin/cot")
        self.preferredApplicationURL = URL.applicationDirectory
            .appendingPathComponent(bundle.bundleName, conformingTo: .application)
        
        // check only preferred link location
        self.linkURL = self.preferredLinkURL
    }
    
    
    /// Checks the destination of symlink and return whether `cot` command is exists at '/usr/local/bin/'.
    ///
    /// - Returns: The result status.
    func validateSymlink() -> Status {
        
        if !self.linkURL.isReachable { return .none }
        
        let url = self.linkURL.resolvingSymlinksInPath()
        
        guard url.isReachable else { return .invalidTarget }
        
        if url == self.linkURL ||
            url == self.bundledCommandURL ||
            url == Bundle(url: self.preferredApplicationURL)?.cotURL
        { return .validTarget }
        
        return .differentTarget
    }
}


private extension Bundle {
    
    var cotURL: URL? {
        
        self.sharedSupportURL?.appending(components: "bin", "cot").standardizedFileURL
    }
}
