//
//  DirectoryDocument+Actions.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2026 1024jp
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
import Defaults

// -> Pass all possible actions manually since NSDocument has no next responder (2024-05, macOS 14)
extension DirectoryDocument {
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(saveAs):
                // prevent file document from being moved out of the folder
                return false
                
            case #selector(save(_:)),
                 #selector(saveTo(_:)),
                 #selector(duplicate(_:)),
                 #selector(revertToSaved),
                 #selector(browseVersions),
                 #selector(lock(_:)),
                 #selector(unlock(_:)),
                 #selector(runPageLayout),
                 #selector(printDocument),
                 #selector(changeEncoding),
                 #selector(changeLineEnding),
                 #selector(toggleEditable):
                // -> PreviewDocument doesn't support file manipulation.
                return (self.currentDocument as? Document)?.validateUserInterfaceItem(item) ?? false
                
            case #selector(changeSyntax):
                guard let document = self.currentDocument as? Document else {
                    if let item = item as? NSMenuItem, let name = item.representedObject as? String {
                        item.state = .off
                        item.isHidden = (item.tag != SyntaxMenuTag.recentItem.rawValue &&
                                         UserDefaults.standard[.hiddenSyntaxes].contains(name))
                    }
                    return false
                }
                
                return document.validateUserInterfaceItem(item)
                
            case #selector(showInFinder),
                 #selector(copyPath),
                 #selector(shareDocument):
                return self.currentDocument?.validateUserInterfaceItem(item) ?? false
                
            case #selector(navigateDocumentHistory(_:)):
                (item as! NSToolbarItemGroup).subitems.forEach { $0.isEnabled = self.validateUserInterfaceItem($0) }
                return true
                
            case #selector(navigatePreviousDocumentHistory):
                return self.documentHistory.canNavigate(forward: false)
                
            case #selector(navigateForwardDocumentHistory):
                return self.documentHistory.canNavigate(forward: true)
                
            default:
                return super.validateUserInterfaceItem(item)
        }
    }
    
    
    override func save(_ sender: Any?) {
        
        self.currentDocument?.save(sender)
    }
    
    
    override func saveTo(_ sender: Any?) {
        
        self.currentDocument?.saveTo(sender)
    }
    
    
    override func duplicate(_ sender: Any?) {
        
        self.currentDocument?.duplicate(sender)
    }
    
    
    override func revertToSaved(_ sender: Any?) {
        
        self.currentDocument?.revertToSaved(sender)
    }
    
    
    override func browseVersions(_ sender: Any?) {
        
        self.currentDocument?.browseVersions(sender)
    }
    
    
    override func lock(_ sender: Any?) {
        
        assertionFailure()
        self.currentDocument?.lock(sender)
    }
    
    
    override func unlock(_ sender: Any?) {
        
        assertionFailure()
        self.currentDocument?.unlock(sender)
    }
    
    
    override func runPageLayout(_ sender: Any?) {
        
        self.currentDocument?.runPageLayout(sender)
    }
    
    
    override func printDocument(_ sender: Any?) {
        
        self.currentDocument?.printDocument(sender)
    }
    
    
    // MARK: DataDocument Actions
    
    @objc func showInFinder(_ sender: Any?) {
        
        self.currentDocument?.showInFinder(sender)
    }
    
    
    @objc func copyPath(_ sender: Any?) {
        
        self.currentDocument?.copyPath(sender)
    }
    
    
    @objc func shareDocument(_ sender: NSMenuItem) {
        
        self.currentDocument?.shareDocument(sender)
    }
    
    
    // MARK: Document Actions
    
    @objc func changeEncoding(_ sender: NSMenuItem) {
        
        (self.currentDocument as? Document)?.changeEncoding(sender)
    }
    
    
    @objc func changeLineEnding(_ sender: NSMenuItem) {
        
        (self.currentDocument as? Document)?.changeLineEnding(sender)
    }
    
    
    @objc func changeSyntax(_ sender: NSMenuItem) {
        
        (self.currentDocument as? Document)?.changeSyntax(sender)
    }
    
    
    @objc func toggleEditable(_ sender: Any?) {
        
        (self.currentDocument as? Document)?.toggleEditable(sender)
    }
    
    
    // MARK: Directory Document Actions
    
    /// Validates the document history toolbar group.
    @objc func navigateDocumentHistory(_ sender: NSToolbarItemGroup) {
        
        assertionFailure("This is a dummy action designed to be used just for the segmentation selection validation.")
    }
    
    
    /// Navigates to the previous document history item.
    @objc func navigatePreviousDocumentHistory(_ sender: Any?) {
        
        // workaround an AppKit issue where clicking the disabled forward segment can invoke
        // the first subitem's action (2026-05, macOS 26.5).
        if let sender = sender as? NSToolbarItem,
           let historyGroup = sender.toolbar?.items
            .compactMap({ $0 as? NSToolbarItemGroup })
            .first(where: { $0.subitems.contains(sender) }),
           historyGroup.selectedIndex != 0
        { return }
        
        guard let historyItem = self.documentHistory.nextItem(forward: false) else { return }
        
        Task {
            await self.openDocumentHistoryItem(historyItem)
        }
    }
    
    
    /// Navigates to the forward document history item.
    @objc func navigateForwardDocumentHistory(_ sender: Any?) {
        
        guard let historyItem = self.documentHistory.nextItem(forward: true) else { return }
        
        Task {
            await self.openDocumentHistoryItem(historyItem)
        }
    }
    
    
    /// Jumps to a document in the document history.
    @objc func jumpDocumentHistory(_ sender: NSMenuItem) {
        
        guard
            let index = sender.representedObject as? Int,
            let historyItem = self.documentHistory.item(at: index)
        else { return }
        
        Task {
            await self.openDocumentHistoryItem(historyItem)
        }
    }
}
