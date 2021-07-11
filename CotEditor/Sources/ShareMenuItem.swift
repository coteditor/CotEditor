//
//  ShareMenuItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2021-07-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2021 1024jp
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

final class ShareMenuItem: NSMenuItem {
    
    // MARK: Public Properties
    
    var sharingItems: [Any]?  { didSet { self.updateSubmenu() } }
    
    
    
    // MARK: -
    // MARK: Menu Item Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.title = "Share".localized
        self.submenu = NSMenu(title: "Share".localized)
    }
    
    
    
    // MARK: Private Methods
    
    private struct SharingServiceContainer {
        
        var service: NSSharingService
        var items: [Any]
    }
    
    
    private func updateSubmenu() {
        
        guard let items = self.sharingItems else { return }
        
        self.submenu?.items = NSSharingService.sharingServices(forItems: items).map { service in
            let item = NSMenuItem(title: service.menuItemTitle, action: #selector(openSharingService), keyEquivalent: "")
            item.image = service.image
            item.representedObject = SharingServiceContainer(service: service, items: items)
            item.target = self
            
            return item
        }
    }
    
    
    @objc private func openSharingService(sender: NSMenuItem) {
        
        guard let container = sender.representedObject as? SharingServiceContainer else { return assertionFailure() }
        
        container.service.perform(withItems: container.items)
    }
    
}
