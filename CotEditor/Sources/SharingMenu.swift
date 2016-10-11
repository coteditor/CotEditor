/*
 
 SharingMenu.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2015-12-18.
 
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

// undefined service names
private enum SharingServiceType {
    
    case addToNotes
    case addToRemainder
    case postOnTwitter
    case composeMessage
    
    var service: NSSharingService? {
        return NSSharingService(named: self.name)
    }
    
    private var name: String {
        switch self {
        case .addToNotes: return "com.apple.Notes.SharingExtension"
        case .addToRemainder: return "com.apple.reminders.RemindersShareExtension"
        case .postOnTwitter: return NSSharingServiceNamePostOnTwitter
        case .composeMessage: return NSSharingServiceNameComposeMessage
        }
    }
}


private struct SharingServiceContainer {
    
    let service: NSSharingService
    let items: [Any]
}


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
        
        guard let document = NSDocumentController.shared().currentDocument as? Document else {
            let item = NSMenuItem(title: NSLocalizedString("No Document", comment: ""), action: nil, keyEquivalent: "")
            item.isEnabled = false
            self.addItem(item)
            return
        }
        
        // file
        if let fileURL = document.fileURL {
            self.addSharingItems(for: fileURL,
                                 subject: document.displayName,
                                 label: NSLocalizedString("File", comment: ""),
                                 excludingSercives: [.addToNotes])
            self.addItem(NSMenuItem.separator())
        }
        
        // text
        self.addSharingItems(for: document.string,
                             subject: document.displayName,
                             label: NSLocalizedString("Text", comment: ""),
                             excludingSercives: [.postOnTwitter,
                                                 .composeMessage,
                                                 .addToRemainder])
    }
    
    
    
    // MARK: Action Messages
    
    /// perform share
    @IBAction func shareFromService(_ sender: NSMenuItem?) {
        
        guard let container = sender?.representedObject as? SharingServiceContainer else { return }
        
        container.service.perform(withItems: container.items)
    }
    
    
    
    // MARK: Private Methods
    
    /// append sharing menu items
    private func addSharingItems(for item: Any, subject: String, label: String, excludingSercives excludingServiceTypes: [SharingServiceType]) {
        
        // heading (label) item
        let labelItem = NSMenuItem(title: label, action: nil, keyEquivalent: "")
        labelItem.isEnabled = false
        self.addItem(labelItem)
        
        // create services to skip
        let excludingServices = excludingServiceTypes.flatMap { type in type.service }
        
        // add menu items dynamically
        for service in NSSharingService.sharingServices(forItems: [item]) {
            guard !excludingServices.contains(service) else { continue }
            
            service.subject = subject
            
            let menuItem = NSMenuItem(title: service.title, action: #selector(shareFromService), keyEquivalent: "")
            menuItem.target = self
            menuItem.image = service.image
            menuItem.representedObject = SharingServiceContainer(service: service, items: [item])
            
            self.addItem(menuItem)
        }
    }
    
}
