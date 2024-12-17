//
//  FindPanelController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-12-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2024 1024jp
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

final class FindPanelController: NSWindowController, NSWindowDelegate {
    
    // MARK: Public Properties
    
    static let shared = FindPanelController()
    
    
    // MARK: Lifecycle
    
    convenience init() {
        
        let window = NSPanel(contentViewController: FindPanelContentViewController())
        window.styleMask = [.titled, .closable, .resizable, .utilityWindow]
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.autorecalculatesKeyViewLoop = true
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.title = String(localized: "Find & Replace", table: "TextFind", comment: "window title")
        
        self.init(window: window)
        
        window.delegate = self
        
        self.windowFrameAutosaveName = "Find Panel"
    }
    
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        
        if sender.isVisible {
            frameSize
        } else {
            // avoid restoring window height
            NSSize(width: frameSize.width, height: sender.frame.height)
        }
    }
    
    
    @IBAction override func showWindow(_ sender: Any?) {
        
        super.showWindow(sender)
        
        // select text in find text field
        if self.window?.firstResponder == self.window?.initialFirstResponder {
            // forcibly reset firstResponder to invoke becomeFirstResponder in FindPanelTextView every time
            // -> `becomeFirstResponder` will not be called on `makeFirstResponder:` if it given object is already set as first responder.
            self.window?.makeFirstResponder(nil)
        }
        self.window?.makeFirstResponder(self.window?.initialFirstResponder)
    }
}
