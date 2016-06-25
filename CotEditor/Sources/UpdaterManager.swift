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
 
 http://www.apache.org/licenses/LICENSE-2.0
 
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
    
    
    /// URL for app cast
    var URL: String {
        let host = "https://coteditor.com/"
        
        switch self {
        case .stable:
            return host + "appcast.xml"
        case .beta:
            return host + "appcast-beta.xml"
        }
    }
}



// MARK:

class UpdaterManager: NSObject, SUUpdaterDelegate {
    
    // MARK: Public Properties
    
    static let shared = UpdaterManager()
    
    /// Is the running app a pre-release version?
    let isPrerelease: Bool = {
        
        let version = AppInfo.shortVersion
        let digitSet = CharacterSet(charactersIn: "0123456789.")
        
        // pre-releases contain non-digit letter
        return (version.rangeOfCharacter(from: digitSet.inverted) != nil)
    }()
    
    
    
    // MARK:
    // MARK: Public Methods
    
    /// setup Sparkle
    func setup() {
        
        guard let updater = SUUpdater.shared() else { return }
        
        // set delegate
        updater.delegate = self
        
        // insert "Check for Updates…" menu item
        let menuItem = NSMenuItem(title: NSLocalizedString("Check for Updates…", comment: ""), action: #selector(SUUpdater.checkForUpdates(_:)), keyEquivalent: "")
        menuItem.target = updater
        
        if let applicationMenu = NSApp.mainMenu?.item(at: MainMenuIndex.application.rawValue)?.submenu {
            applicationMenu.insertItem(menuItem, at: 1)
        }
        
        // lock update check interval to daily
        updater.updateCheckInterval = 60 * 60 * 24
    }
    
    
    
    // MARK: Sparkle Updater Delegate
    
    /// return AppCast file URL dinamically
    func feedURLString(for updater: SUUpdater!) -> String! {
        
        // force checking beta if the currently runnning one is a beta.
        var checksBeta = false
        if self.isPrerelease {
            checksBeta = true
        } else {
            checksBeta = UserDefaults.standard().bool(forKey: CEDefaultChecksUpdatesForBetaKey)
        }
        
        let appCast: AppCastURL = checksBeta ? .beta : .stable
        
        return appCast.URL
    }
    
}
