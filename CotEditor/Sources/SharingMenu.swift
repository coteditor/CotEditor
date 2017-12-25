/*
 
 SharingMenu.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-12-18.
 
 ------------------------------------------------------------------------------
 
 © 2015-2017 1024jp
 
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

final class SharingMenu: NSMenu, NSMenuDelegate {
    
    // MARK: Protocol
    
    /// set delegate to itself
    override func awakeFromNib() {
        
        self.delegate = self
    }
    
    
    
    // MARK: Menu Delegate
    
    /// create share menu dynamically
    func menuWillOpen(_ menu: NSMenu) {
        
        self.removeAllItems()
        
        guard
            let document = NSDocumentController.shared.currentDocument,
            let fileURL = document.fileURL
            else {
                let item = NSMenuItem(title: NSLocalizedString("No Document", comment: ""), action: nil, keyEquivalent: "")
                item.isEnabled = false
                self.addItem(item)
                return
            }
        
        // add menu items dynamically
        for service in NSSharingService.sharingServices(forItems: [fileURL]) {
            service.subject = document.displayName
            service.delegate = document
            
            let menuItem = NSMenuItem(title: service.menuItemTitle, action: #selector(NSDocument.shareFromService), keyEquivalent: "")
            menuItem.target = document
            menuItem.image = service.image
            menuItem.representedObject = service
            
            self.addItem(menuItem)
        }
    }
    
}


extension NSDocument {
    
    // MARK: Action Messages
    
    /// perform share
    @IBAction func shareFromService(_ sender: NSMenuItem?) {
        
        guard
            let service = sender?.representedObject as? NSSharingService,
            let item = self.fileURL
            else { return }
        
        service.perform(withItems: [item])
    }
    
}
