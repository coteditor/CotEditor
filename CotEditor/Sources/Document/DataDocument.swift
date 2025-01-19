//
//  DataDocument.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-09-09.
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

@Observable class DataDocument: NSDocument {
    
    // MARK: Public Properties
    
    nonisolated(unsafe) var fileAttributes: FileAttributes?
    
    weak var windowController: DocumentWindowController?
    
    
    // MARK: Document Methods
    
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(showInFinder):
                return self.fileURL != nil
                
            default: break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    // MARK: Actions
    
    /// Opens the document file in the Finder.
    @IBAction func showInFinder(_ sender: Any?) {
        
        guard let fileURL else { return }
        
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
    
    
    /// Shows the sharing picker interface.
    @IBAction func shareDocument(_ sender: Any?) {
        
        guard let contentView = self.contentViewController?.view else { return assertionFailure() }
        
        // -> Get titlebar view to mimic the behavior in iWork apps... (macOS 14 on 2023-12)
        let view = contentView.window?.standardWindowButton(.closeButton)?.superview ?? contentView
        
        NSSharingServicePicker(items: [self])
            .show(relativeTo: .zero, of: view, preferredEdge: .minY)
    }
    
    
    // MARK: Private Methods
    
    /// The `ContentViewController`.
    private var contentViewController: NSViewController? {
        
        (self.windowController?.contentViewController as? NSSplitViewController)?
            .splitViewItems
            .first { $0.behavior == .default }?
            .viewController
    }
}
