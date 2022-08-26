//
//  OpacityViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-01-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2022 1024jp
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

final class OpacityViewController: NSViewController {
    
    @objc dynamic weak var window: NSWindow?
}


/// - Attention: Only for the slider for editor opacity slider.
final class WorkaroundOpacitySlider: NSSlider {
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        
        super.viewWillMove(toWindow: newWindow)
        
        // workaround for the issue
        // that Cocoa Bindings in the view-based menu item for a toolbar item will be lost
        // when the toolbar item is collapsed.
        // (2022-01, macOS 12)
        if newWindow != nil,
           self.infoForBinding(.value) == nil,
           let documentWindow = NSApp.orderedDocuments.first?.windowControllers.first?.window as? DocumentWindow
        {
            self.bind(.value, to: documentWindow, withKeyPath: #keyPath(DocumentWindow.backgroundAlpha))
        }
    }
    
}
