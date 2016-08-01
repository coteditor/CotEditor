/*
 
 DocumentWindowController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2004-12-13.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2013-2016 1024jp
 
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

final class DocumentWindowController: NSWindowController, NSWindowDelegate {
    
    // MARK: Private Properties
    
    @IBOutlet private var toolbarController: ToolbarController?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKey.windowAlpha)
    }
    
    
    
    // MARK: KVO
    
    /// apply user defaults change
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        
        if keyPath == DefaultKey.windowAlpha {
            if let window = self.window as? AlphaWindow {
                window.backgroundAlpha = UserDefaults.standard.cgFloat(forKey: DefaultKey.windowAlpha)
            }
        }
    }
    
    
    
    // MARK: Window Controller Methods
    
    /// prepare window
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        // -> It's set as false by default if the window controller was invoked from a storyboard.
        self.shouldCascadeWindows = true
        
        let window = self.window as! AlphaWindow
        let defaults = UserDefaults.standard
        
        // set window size
        let contentSize = NSSize(width: defaults.cgFloat(forKey: DefaultKey.windowWidth),
                                 height: defaults.cgFloat(forKey: DefaultKey.windowHeight))
        window.setContentSize(contentSize)
        
        // setup background
        window.backgroundAlpha = defaults.cgFloat(forKey: DefaultKey.windowAlpha)
        
        // observe opacity setting change
        defaults.addObserver(self, forKeyPath: DefaultKey.windowAlpha, context: nil)
    }
    
    
    /// apply passed-in document instance to window
    override var document: AnyObject? {
        didSet {
            guard let document = document as? Document else { return }
            
            self.toolbarController!.document = document
            self.contentViewController!.representedObject = document
            
            // apply document state to UI
            document.applyContentToWindow()
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// pass editor instance to document
    var editor: EditorWrapper? {
        
        return (self.contentViewController as? WindowContentViewController)?.editor
    }
    
    
    /// show incompatible char list
    func showIncompatibleCharList() {
        
        guard let contentViewController = self.contentViewController as? WindowContentViewController else { return }
        
        contentViewController.showSidebarPane(index: .incompatibleCharacters)
    }
    
}
