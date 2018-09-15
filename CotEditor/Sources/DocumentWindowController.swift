//
//  DocumentWindowController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2013-2018 1024jp
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

import Cocoa

final class DocumentWindowController: NSWindowController {
    
    // MARK: Private Properties
    
    @IBOutlet private var toolbarController: ToolbarController?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKeys.windowAlpha.rawValue)
    }
    
    
    
    // MARK: KVO
    
    /// apply user defaults change
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        switch keyPath {
        case DefaultKeys.windowAlpha.rawValue?:
            (self.window as? DocumentWindow)?.backgroundAlpha = UserDefaults.standard[.windowAlpha]
            
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    
    
    // MARK: Window Controller Methods
    
    /// prepare window
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        // -> It's set as false by default if the window controller was invoked from a storyboard.
        self.shouldCascadeWindows = true
        self.windowFrameAutosaveName = "document"
        
        // set background alpha
        (self.window as! DocumentWindow).backgroundAlpha = UserDefaults.standard[.windowAlpha]
        
        // observe opacity setting change
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKeys.windowAlpha.rawValue, context: nil)
    }
    
    
    /// apply passed-in document instance to window
    override var document: AnyObject? {
        
        didSet {
            guard let document = document as? Document else { return }
            
            self.toolbarController!.document = document
            self.contentViewController!.representedObject = document
            
            // -> In case when the window was created as a restored window (the right side ones in the browsing mode)
            if document.isInViewingMode, let window = self.window as? DocumentWindow {
                window.backgroundAlpha = 1.0
            }
        }
    }
    
}



extension DocumentWindowController: NSWindowDelegate { }
