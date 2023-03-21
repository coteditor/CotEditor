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
//  © 2015-2022 1024jp
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

final class UpdaterManager: NSObject, SPUUpdaterDelegate {
    
    // MARK: Public Properties
    
    static let shared = UpdaterManager()
    
    
    // MARK: Private Properties
    
    private static let feedURLString = "https://coteditor.com/appcast.xml"
    
    private lazy var controller = SPUStandardUpdaterController(updaterDelegate: self, userDriverDelegate: nil)
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private override init() {
        
        super.init()
    }
    
    
    /// setup Sparkle
    @MainActor func setup() {
        
        // insert "Check for Updates…" menu item
        guard let applicationMenu = MainMenu.application.menu else {
            preconditionFailure("No menu could be found to attach update menu item.")
        }
        let menuItem = NSMenuItem(title: "Check for Updates…".localized,
                                  action: #selector(SPUUpdater.checkForUpdates),
                                  keyEquivalent: "")
        menuItem.target = self.controller.updater
        applicationMenu.insertItem(menuItem, at: 1)
        
        // migrate from outdated feed API (Sparkle 2.4.0, 2023-03)
        self.controller.updater.clearFeedURLFromUserDefaults()
        
        self.controller.updater.updateCheckInterval = TimeInterval(60 * 60 * 24)  // daily
    }
    
    
    
    // MARK: Sparkle Updater Delegate
    
    func feedURLString(for updater: SPUUpdater) -> String? {
        
        Self.feedURLString
    }
    
    
    func allowedChannels(for updater: SPUUpdater) -> Set<String> {
        
        let checksBeta = (Bundle.main.isPrerelease || UserDefaults.standard[.checksUpdatesForBeta])
        
        return checksBeta ? ["prerelease"] : []
    }
}
