/*
 
 MainViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-05.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
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

final class MainViewController: NSSplitViewController {
    
    // MARK: Public Properties
    
    @IBOutlet private(set) var editor: EditorWrapper?
    
    
    // MARK: Private Properties
    
    @IBOutlet private weak var statusBarItem: NSSplitViewItem?
    
    
    
    // MARK:
    // MARK: Split View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // setup status bar
        self.isStatusBarShown = Defaults[.showStatusBar]
    }
    
    
    /// deliver document to child view controllers
    override var representedObject: Any? {
        
        didSet {
            guard let document = representedObject as? Document else { return }
            
            (self.statusBarItem?.viewController as? StatusBarController)?.documentAnalyzer = document.analyzer
            self.editor?.document = document
        }
    }
    
    
    /// keys to be restored from the last session
    override class func restorableStateKeyPaths() -> [String] {
        
        return [#keyPath(isStatusBarShown),
                #keyPath(editor.showsNavigationBar),
                #keyPath(editor.showsLineNumber),
                #keyPath(editor.showsPageGuide),
                #keyPath(editor.showsInvisibles),
                #keyPath(editor.verticalLayoutOrientation)]
    }
    
    
    /// avoid showing draggable cursor
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        
        var effectiveRect = proposedEffectiveRect
        effectiveRect.size = .zero
        
        return effectiveRect
    }
    
    
    /// validate menu items
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        guard let action = menuItem.action else { return false }
        
        switch action {
        case #selector(toggleStatusBar):
            let title = self.isStatusBarShown ? "Hide Status Bar" : "Show Status Bar"
            menuItem.title = NSLocalizedString(title, comment: "")
            
        default: break
        }
        
        return true
    }
    
    
    // MARK: Action Messages
    
    /// toggle visibility of status bar with fancy animation
    @IBAction func toggleStatusBar(_ sender: AnyObject?) {
        
        self.statusBarItem?.animator().isCollapsed = self.isStatusBarShown
    }
    
    
    
    // MARK: Private Methods
    
    /// Whether status bar is visible
    @objc private dynamic var isStatusBarShown: Bool {
        
        get {
            return !(self.statusBarItem?.isCollapsed ?? true)
        }
        set {
            self.statusBarItem?.isCollapsed = !newValue
        }
    }
    
}
