/*
 
 IntegrationPaneController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-12-20.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

class IntegrationPaneController: NSViewController {
    
    private static let commandURL = try! Bundle.main().sharedSupportURL!.appendingPathComponent("bin/cot").standardizingPath()
    
    private static let preferredLinkURL = URL.init(fileURLWithPath: "/usr/local/bin/cot")
    
    private static let preferredLinkTargetURL: URL = {
        // cot in CotEditor.app in /Applications directory
        let applicationDirURL = try! FileManager.default().urlForDirectory(.applicationDirectory,
                                                                           in: .localDomainMask,
                                                                           appropriateFor: nil,
                                                                           create: false)
        let appName = (Bundle.main().objectForInfoDictionaryKey("CFBundleName") as! NSString) as String
        
        return try! applicationDirURL.appendingPathComponent(appName).appendingPathExtension("app")
    }()
    
    private dynamic var linkURL: URL!
    private dynamic var installed: Bool = false
    private dynamic var warning: String?
    
    
    
    
    // MARK:
    // MARK: View Controller Methods
    
    /// nib name
    override var nibName: String? {
        
        return "IntegrationPane"
    }
    
    
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
        self.linkURL = self.dynamicType.preferredLinkURL
        
        // not installed yet (= can install)
        if try! !self.linkURL.checkResourceIsReachable() { return false }
        
        // ???: `resolvingSymlinksInPath` doesn't work correctly on OS X 10.10 SDK, so I use a legacy way (2015-08).
//        let linkDestinationURL = self.linkURL.resolvingSymlinksInPath()
        let linkDestinationURL: URL = {
            let linkDestinationPath = try! FileManager.default().destinationOfSymbolicLink(atPath: self.linkURL.path!)
            return URL.init(fileURLWithPath: linkDestinationPath)
        }()
        
        // treat symlink as "installed"
        if linkDestinationURL == self.linkURL { return true }
        
        // link to bundled cot is of course valid
        if linkDestinationURL == self.dynamicType.commandURL { return true }
        
        // link to '/Applications/CotEditor.app' is always valid
        if linkDestinationURL == self.dynamicType.preferredLinkTargetURL { return true }
        
        // display warning for invalid link
        if try! linkDestinationURL.checkResourceIsReachable() {
            // link destinaiton is not running CotEditor
            self.warning = NSLocalizedString("The current 'cot' symbolic link doesn’t target the running CotEditor.", comment: "")
        } else {
            // link destination is unreachable
            self.warning = NSLocalizedString("The current 'cot' symbolic link may target on an invalid path.", comment: "")
        }
        
        return true
    }
}
