/*
 
 PreferencesWindowController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-04-18.
 
 ------------------------------------------------------------------------------
 
 © 2014-2017 1024jp
 
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

final class PreferencesWindowController: NSWindowController {
    
    // MARK: Public Properties
    
    static let shared = PreferencesWindowController()
    
    
    // MARK: Private Properties
    
    private let viewControllers: [NSViewController] = [
        GeneralPaneController(),
        WindowPaneController(),
        AppearancePaneController(),
        EditPaneController(),
        FormatPaneController(),
        NSStoryboard(name: "FileDropPane", bundle: nil).instantiateInitialController() as! FileDropPaneController,
        KeyBindingsPaneController(),
        PrintPaneController(),
        IntegrationPaneController(),
        ]
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override var windowNibName: String? {
        
        return "PreferencesWindow"
    }
    
    
    
    // MARK: Window Controller Methods
    
    /// set initial pane
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        guard let leftmostItem = self.window?.toolbar?.items.first else { return }
        
        self.window?.toolbar?.selectedItemIdentifier = leftmostItem.itemIdentifier
        self.switchView(leftmostItem)
        self.window?.center()
    }
    
    
    
    // MARK: Action Messages
    
    /// switch panes from toolbar
    @IBAction func switchView(_ toolbarItem: NSToolbarItem) {
        
        guard let window = self.window else { return }
        
        // detect clicked icon and select the view to switch
        let newView = self.viewControllers[toolbarItem.tag].view
        
        // remove current view from the main view
        window.contentView?.subviews.forEach { view in
            view.removeFromSuperviewWithoutNeedingDisplay()
        }
        
        // resize window to fit to new view
        var frame = window.frameRect(forContentRect: newView.frame)
        frame.origin = window.frame.origin
        frame.origin.y += window.frame.height - frame.height
        window.setFrame(frame, display: false, animate: true)
        
        // set window title
        window.title = toolbarItem.paletteLabel
        
        // add new view to the main view
        window.contentView?.addSubview(newView)
    }
    
}
