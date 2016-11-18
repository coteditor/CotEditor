/*
 
 UpdaterManager.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-05-01.
 
 ------------------------------------------------------------------------------
 
 © 2015-2016 1024jp
 
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

import Cocoa
import Sparkle

private enum AppCastURL {
    
    case stable
    case beta
    
    static let host = "https://coteditor.com/"
    
    
    /// URL for app cast
    var URL: String {
        
        return AppCastURL.host + self.filename
    }
    
    
    /// filename of app cast
    private var filename: String {
        
        switch self {
        case .stable:
            return "appcast.xml"
        case .beta:
            return "appcast-beta.xml"
        }
    }
}



// MARK:

final class UpdaterManager: NSObject, SUUpdaterDelegate {
    
    // MARK: Public Properties
    
    static let shared = UpdaterManager()
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        SUUpdater.shared().delegate = nil
    }
    
    
    
    // MARK: Public Methods
    
    /// setup Sparkle
    func setup() {
        
        guard let updater = SUUpdater.shared() else { return }
        
        // set delegate
        updater.delegate = self
        
        // insert "Check for Updates…" menu item
        guard let applicationMenu = MainMenu.application.menu else {
            preconditionFailure("no menu can be found to attach update menu item.")
        }
        let menuItem = NSMenuItem(title: NSLocalizedString("Check for Updates…", comment: ""),
                                  action: #selector(SUUpdater.checkForUpdates),
                                  keyEquivalent: "")
        menuItem.target = updater
        applicationMenu.insertItem(menuItem, at: 1)
        
        // lock update check interval to daily
        updater.updateCheckInterval = TimeInterval(60 * 60 * 24)
    }
    
    
    
    // MARK: Sparkle Updater Delegate
    
    /// return AppCast file URL dinamically
    func feedURLString(for updater: SUUpdater!) -> String! {
        
        // force checking beta if the currently runnning one is a beta.
        let checksBeta: Bool = AppInfo.isPrerelease ? true : Defaults[.checksUpdatesForBeta]
        
        let appCast: AppCastURL = checksBeta ? .beta : .stable
        
        return appCast.URL
    }
    
}
