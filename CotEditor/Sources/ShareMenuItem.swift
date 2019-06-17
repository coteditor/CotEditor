//
//  ShareMenuItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-12-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2018 1024jp
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

final class ShareMenuItem: NSMenuItem, NSMenuDelegate {
    
    // MARK: Lifecycle
    
    init() {
        
        super.init(title: "Share".localized, action: nil, keyEquivalent: "")
        
        self.submenu = NSMenu()
        self.submenu?.delegate = self
    }
    
    
    required init(coder decoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Menu Delegate
    
    /// create share menu dynamically
    func menuWillOpen(_ menu: NSMenu) {
        
        menu.removeAllItems()
        
        guard let document = NSDocumentController.shared.currentDocument else {
            let item = NSMenuItem(title: "No Document".localized, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            return
        }
        
        // add menu items dynamically
        for service in NSSharingService.sharingServices(forItems: [document]) {
            service.subject = document.displayName
            
            let menuItem = NSMenuItem(title: service.menuItemTitle, action: #selector(NSDocument.share), keyEquivalent: "")
            menuItem.target = document
            menuItem.image = service.image
            menuItem.representedObject = service
            
            menu.addItem(menuItem)
        }
    }
    
}



extension NSDocument: NSSharingServiceDelegate {
    
    // MARK: Actions
    
    /// perform share
    @IBAction func share(_ sender: NSMenuItem) {
        
        guard let service = sender.representedObject as? NSSharingService else { return assertionFailure() }
        
        service.delegate = self
        service.perform(withItems: [self])
    }
    
    
    
    // MARK: Sharing Service Delegate
    
    public func sharingService(_ sharingService: NSSharingService, sourceWindowForShareItems items: [Any], sharingContentScope: UnsafeMutablePointer<NSSharingService.SharingContentScope>) -> NSWindow? {
        
        return self.windowForSheet
    }
    
}
