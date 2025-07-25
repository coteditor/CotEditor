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
//  © 2015-2025 1024jp
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

#if SPARKLE
import Sparkle

@MainActor final class UpdaterManager: NSObject, SPUUpdaterDelegate {
    
    // MARK: Public Properties
    
    static let shared = UpdaterManager()
    
    
    // MARK: Private Properties
    
    private nonisolated static let feedURLString = "https://coteditor.com/appcast.xml"
    
    private lazy var controller = SPUStandardUpdaterController(updaterDelegate: self, userDriverDelegate: nil)
    private var menuItem: NSMenuItem?
    
    
    // MARK: Lifecycle
    
    private override init() {
        
        super.init()
        
        // migrate from outdated feed API (Sparkle 2.4.0, 2023-03)
        self.controller.updater.clearFeedURLFromUserDefaults()
        
        self.controller.updater.updateCheckInterval = TimeInterval(60 * 60 * 24)  // daily
    }
    
    
    /// Sets Sparkle up.
    func setup() {
        
        // insert "Check for Updates…" menu item
        
        guard let applicationMenu = NSApp.mainMenu?.item(at: 0)?.submenu else {
            return assertionFailure("Found no menu to attach the update menu item.")
        }
        
        let menuItem = NSMenuItem()
        menuItem.title = NSMenuItem.updateMenuTitle
        menuItem.image = NSImage(systemSymbolName: "arrow.trianglehead.2.counterclockwise", accessibilityDescription: nil)
        if #unavailable(macOS 26) {
            menuItem.image = nil
        }
        menuItem.action = #selector(SPUUpdater.checkForUpdates)
        menuItem.target = self.controller.updater
        
        applicationMenu.insertItem(menuItem, at: 1)
        self.menuItem = menuItem
    }
    
    
    // MARK: Sparkle Updater Delegate
    
    nonisolated func feedURLString(for updater: SPUUpdater) -> String? {
        
        Self.feedURLString
    }
    
    
    nonisolated func allowedChannels(for updater: SPUUpdater) -> Set<String> {
        
        let checksBeta = (Bundle.main.version!.isPrerelease || UserDefaults.standard[.checksUpdatesForBeta])
        
        return checksBeta ? ["prerelease"] : []
    }
    
    
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        
        self.menuItem?.badge = .updates(count: 1)
    }
}
#endif


private extension NSMenuItem {
    
    static let updateMenuTitle = String(localized: "Check for Updates…", table: "MainMenu",
                                        comment: "provided only in the non-AppStore version")
}
