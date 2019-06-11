//
//  IntegrationPaneController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-12-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2019 1024jp
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

import Cocoa

final class IntegrationPaneController: NSViewController {
    
    // MARK: Private Properties
    
    private static let commandURL = Bundle.main.sharedSupportURL!.appendingPathComponent("bin/cot").standardizedFileURL
    
    private static let preferredLinkURL = URL(fileURLWithPath: "/usr/local/bin/cot")
    
    private static let preferredLinkTargetURL: URL = {
        // cot in CotEditor.app in /Applications directory
        let applicationDirURL = try! FileManager.default.url(for: .applicationDirectory,
                                                             in: .localDomainMask,
                                                             appropriateFor: nil,
                                                             create: false)
        let appName = Bundle.main.bundleName
        
        return applicationDirURL.appendingPathComponent(appName).appendingPathExtension("app")
    }()
    
    @objc private dynamic var linkURL: URL!
    @objc private dynamic var installed = false
    @objc private dynamic var warning: String?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// update warnings before view appears
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.installed = self.validateSymLink()
    }
    
    
    
    // MARK: Private Methods
    
    /// check the destination of symlink and return whether 'cot' command is exists at '/usr/local/bin/'
    private func validateSymLink() -> Bool {
        
        // reset once
        self.warning = nil
        
        // check only preferred link location
        self.linkURL = Self.preferredLinkURL
        
        // not installed yet (= can install)
        if !self.linkURL.isReachable { return false }
        
        let linkDestinationURL = self.linkURL.resolvingSymlinksInPath()
        
        // treat symlink as "installed"
        if linkDestinationURL == self.linkURL { return true }
        
        // link to bundled cot is, of course, valid
        if linkDestinationURL == Self.commandURL { return true }
        
        // link to '/Applications/CotEditor.app' is always valid
        if linkDestinationURL == Self.preferredLinkTargetURL { return true }
        
        // display warning for invalid link
        if linkDestinationURL.isReachable {
            // link destination is not running CotEditor
            self.warning = "The current 'cot' symbolic link doesn’t target the running CotEditor.".localized
        } else {
            // link destination is unreachable
            self.warning = "The current 'cot' symbolic link may target an invalid path.".localized
        }
        
        return true
    }
    
}
