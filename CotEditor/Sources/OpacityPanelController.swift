/*
 
 OpacityPanelController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-03-12.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
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

final class OpacityPanelController: NSWindowController {
    
    // MARK: Public Properties
    
    static let shared = OpacityPanelController()
    
    
    // MARK: Private Properties
    
    private dynamic var opacity: CGFloat = 0 {
        didSet {
            // apply to the frontmost document window
            if let window = NSApp.mainWindow as? AlphaWindow {
                window.backgroundAlpha = opacity
            }
        }
    }
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override var windowNibName: String? {
        
        return "OpacityPanel"
    }
    
    
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        // observe main window change
        NotificationCenter.default.addObserver(self, selector: #selector(mainWindowDidChange), name: .NSWindowDidBecomeMain, object: nil)
        
        // apply current window value
        let notification = Notification(name: .NSWindowDidBecomeMain, object: NSApp.mainWindow)
        self.mainWindowDidChange(notification)
    }
    
    
    
    
    // MARK: Notification
    
    /// notification about main window change
    func mainWindowDidChange(_ notification: Notification) {
        if let window = notification.object as? AlphaWindow {
            self.opacity = window.backgroundAlpha
        }
    }
    
}
