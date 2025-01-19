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
//  © 2024-2025 1024jp
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
                 #selector(changeSyntax),
                 #selector(toggleEditable):
                // -> PreviewDocument doesn't support file manipulation.
                return (self.currentDocument as? Document)?.validateUserInterfaceItem(item) ?? false
                
            case #selector(showInFinder),
                 #selector(shareDocument):
                return self.currentDocument?.validateUserInterfaceItem(item) ?? false
                
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
}
