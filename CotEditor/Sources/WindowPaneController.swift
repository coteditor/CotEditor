/*
 
 WindowPaneController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-18.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

final class WindowPaneController: NSViewController {
    
    // MARK: Private Properties
    
    private dynamic var editorOpaque: Bool = (UserDefaults.standard[.windowAlpha] == 1.0)
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override var nibName: String? {
        
        return "WindowPane"
    }
    
    
    
    // MARK: Action Messages
    
    /// opaque setting did update
    @IBAction func changeEditorOpaque(_ sender: NSControl?) {
        
        guard let sender = sender else { return }
        
        self.editorOpaque = (sender.doubleValue == 1.0)
    }
    
    
    /// open sample window for window size setting
    @IBAction func openSizeSampleWindow(_ sender: Any?) {
        
        let sampleWindowController = SizeSettingWindowController()
        
        // display modal
        sampleWindowController.showWindow(sender)
        NSApp.runModal(for: sampleWindowController.window!)
        
        // make preferences window the key window after closing sample window
        self.view.window?.makeKeyAndOrderFront(self)
    }
    
}
