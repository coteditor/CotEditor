//
//  FileBrowserViewController+QuickLook.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-09-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import QuickLookUI

extension FileBrowserViewController {
    
    override func keyDown(with event: NSEvent) {
        
        if event.modifierFlags.isDisjoint(with: .deviceIndependentFlagsMask),
           event.charactersIgnoringModifiers == " "
        {
            // open the Quick Look panel by pressing the Space key
            self.quickLook(with: event)
            
        } else {
            super.keyDown(with: event)
        }
    }
    
    
    override func quickLook(with event: NSEvent) {
        
        self.quickLookPreviewItems(nil)
    }
    
    
    override func quickLookPreviewItems(_ sender: Any?) {
        
        guard let panel = QLPreviewPanel.shared() else { return }
        
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
        }
    }
    
    
    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        
        true
    }
    
    
    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        
        MainActor.assumeIsolated {
            panel.delegate = self
            panel.dataSource = self
        }
    }
    
    
    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        
        MainActor.assumeIsolated {
            panel.dataSource = nil
            panel.delegate = nil
        }
    }
}


// MARK: Preview Panel Data Source

extension FileBrowserViewController: @preconcurrency QLPreviewPanelDataSource {
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        
        self.outlineView.selectedRowIndexes.count
    }
    
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        
        let row = self.outlineView.selectedRowIndexes.sorted()[index]
        
        guard let node = self.outlineView.item(atRow: row) as? FileNode else { return nil }
        
        return node.fileURL as NSURL
    }
}


// MARK: Preview Panel Delegate

// redundant declaration of NSWindowDelegate to suppress the wrong no-effect @preconcurrency attribute warning for QLPreviewPanelDelegate
extension FileBrowserViewController: NSWindowDelegate { }


extension FileBrowserViewController: @preconcurrency QLPreviewPanelDelegate {
    
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        
        true
    }
    
    
    func previewPanel(_ panel: QLPreviewPanel!, sourceFrameOnScreenFor item: (any QLPreviewItem)!) -> NSRect {
        
        guard
            let fileURL = item as? URL,
            let node = self.document.fileNode?.node(at: fileURL),
            let cellView = self.outlineView.view(atColumn: 0, row: self.outlineView.row(forItem: node),
                                                 makeIfNecessary: false) as? NSTableCellView,
            let iconView = cellView.imageView,
            let window = self.outlineView.window
        else { return .zero }
        
        return window.convertToScreen(iconView.convert(iconView.bounds, to: nil))
    }
}
