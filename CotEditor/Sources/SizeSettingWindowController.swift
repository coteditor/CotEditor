/*
 
 SizeSettingWindowController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-03-26.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

final class SizeSettingWindowController: NSWindowController {
    
    // MARK: Private Properties
    
    @IBOutlet private var userDefaultsController: NSUserDefaultsController!
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    override var windowNibName: String? {
        
        return "SizeSettingWindow"
    }
    
    
    
    // MARK: Window Controller Methods
    
    /// setup UI
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        self.window?.center()
    }
    
    
    
    // MARK: Action Messages
    
    /// close window without save
    @IBAction func cancel(_ sender: Any?) {
        
        self.userDefaultsController.revert(sender)
        
        NSApp.stopModal(withCode: NSModalResponseCancel)
        self.window?.orderOut(sender)
    }
    
    
    /// save window size to the user defaults and close window
    @IBAction func save(_ sender: Any?) {
        
        self.userDefaultsController.save(sender)
        
        NSApp.stopModal(withCode: NSModalResponseOK)
        self.window?.orderOut(sender)
    }
    
}
