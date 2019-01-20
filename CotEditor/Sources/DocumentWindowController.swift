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
//  © 2013-2019 1024jp
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
    
    private var windowAlphaObserver: UserDefaultsObservation?
    
    @IBOutlet private var toolbarController: ToolbarController?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    deinit {
        self.windowAlphaObserver?.invalidate()
    }
    
    
    
    // MARK: Window Controller Methods
    
    /// prepare window
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        // -> It's set as false by default if the window controller was invoked from a storyboard.
        self.shouldCascadeWindows = true
        // -> Do not use "document" for autosave name because homehow windows forget the size with that name (2018-09)
        self.windowFrameAutosaveName = "Document Window"
        
        // set background alpha
        (self.window as! DocumentWindow).backgroundAlpha = UserDefaults.standard[.windowAlpha]
        
        // observe opacity setting change
        self.windowAlphaObserver = UserDefaults.standard.observe(key: .windowAlpha, options: [.new]) { [unowned self] change in
            (self.window as? DocumentWindow)?.backgroundAlpha = change.new!
        }
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
