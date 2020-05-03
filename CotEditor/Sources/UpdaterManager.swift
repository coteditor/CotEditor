//
//  UpdaterManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-05-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2020 1024jp
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
import AppKit.NSMenuItem
import Sparkle

private enum AppCastURL {
    
    case stable
    case beta
    
    private static let host = "https://coteditor.com/"
    
    
    /// URL for app cast
    var url: String {
        
        return Self.host + self.filename
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



// MARK: -

final class UpdaterManager: NSObject, SPUUpdaterDelegate {
    
    // MARK: Public Properties
    
    static let shared = UpdaterManager()
    
    
    // MARK: Private Properties
    
    private lazy var controller = SPUStandardUpdaterController(updaterDelegate: self, userDriverDelegate: nil)
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private override init() {
        
        super.init()
    }
    
    
    
    // MARK: Public Methods
    
    /// setup Sparkle
    func setup() {
        
        guard let updater = self.controller.updater else {
            return assertionFailure("No SPUUpdater instance could be obtained.")
        }
        
        // insert "Check for Updates…" menu item
        guard let applicationMenu = MainMenu.application.menu else {
            preconditionFailure("No menu could be found to attach update menu item.")
        }
        let menuItem = NSMenuItem(title: "Check for Updates…".localized,
                                  action: #selector(SPUUpdater.checkForUpdates),
                                  keyEquivalent: "")
        menuItem.target = updater
        applicationMenu.insertItem(menuItem, at: 1)
        
        // lock update check interval to daily
        updater.updateCheckInterval = TimeInterval(60 * 60 * 24)
    }
    
    
    
    // MARK: Sparkle Updater Delegate
    
    /// return AppCast file URL dinamically
    func feedURLString(for updater: SPUUpdater) -> String? {
        
        // force into checking beta if the currently runnning one is a beta.
        let checksBeta = (Bundle.main.isPrerelease || UserDefaults.standard[.checksUpdatesForBeta])
        let appCast: AppCastURL = checksBeta ? .beta : .stable
        
        return appCast.url
    }
    
}
