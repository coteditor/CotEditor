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
//  © 2020 1024jp
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

final class CommandLineToolManager {
    
    enum Status {
        
        case none
        case validTarget
        case differentTarget
        case invalidTarget
    }
    
    
    // MARK: Public Methods
    
    static let shared = CommandLineToolManager(bundle: .main)
    
    
    // MARK: Public Properties
    
    private(set) var linkURL: URL
    
    private let commandURL: URL
    private let preferredLinkURL: URL
    private let preferredLinkTargetURL: URL  // path to .app in /Applications directory
    
    
    
    // MARK: -
    // MARK: Public Methods
    
    init(bundle: Bundle) {
        
        self.commandURL = bundle.sharedSupportURL!.appendingPathComponent("bin/cot").standardizedFileURL
        self.preferredLinkURL = URL(fileURLWithPath: "/usr/local/bin/cot")
        self.preferredLinkTargetURL = try! FileManager.default
            .url(for: .applicationDirectory, in: .localDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(bundle.bundleName, conformingTo: .application)
        
        // check only preferred link location
        self.linkURL = self.preferredLinkURL
    }
    
    
    /// check the destination of symlink and return whether 'cot' command is exists at '/usr/local/bin/'
    func validateSymLink() -> Status {
        
        // not installed yet (= can install)
        if !self.linkURL.isReachable { return .none }
        
        let linkDestinationURL = self.linkURL.resolvingSymlinksInPath()
        
        // treat symlink as "installed"
        if linkDestinationURL == self.linkURL { return .validTarget }
        
        // link to bundled cot is, of course, valid
        if linkDestinationURL == self.commandURL { return .validTarget }
        
        // link to '/Applications/CotEditor.app' is always valid
        if linkDestinationURL == self.preferredLinkTargetURL { return .validTarget }
        
        // link destination is not running CotEditor
        if linkDestinationURL.isReachable {
            return .differentTarget
        }
        
        // link destination is unreachable
        return .invalidTarget
    }
    
}


extension CommandLineToolManager.Status {
    
    var installed: Bool { self != .none }
    
    
    var message: String? {
        
        switch self {
            case .none, .validTarget:
                return nil
            case .differentTarget:
                return "The current 'cot' symbolic link doesn’t target the running CotEditor.".localized
            case .invalidTarget:
                return "The current 'cot' symbolic link may target an invalid path.".localized
        }
    }
    
}
