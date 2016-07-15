/*
 
 SplitViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2006-03-26.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
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

class SplitViewController: NSSplitViewController {
    
    // MARK: Public Properties
    
    private(set) weak var focusedSubviewController: EditorViewController?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: Split View Controller Methods
    
    /// setup view
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.splitView.isVertical = UserDefaults.standard.bool(forKey: CEDefaultSplitViewVerticalKey)
        self.invalidateOpenSplitEditorButtons()
        
        // observe focus change
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidBecomeFirstResponder), name: .CETextViewDidBecomeFirstResponder, object: nil)
    }
    
    
    /// update close split view button state after remove
    override func removeSplitViewItem(_ splitViewItem: NSSplitViewItem) {
        
        super.removeSplitViewItem(splitViewItem)
        
        self.invalidateCloseSplitEditorButtons()
    }
    
    
    /// apply current state to related menu items
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        
        guard let action = menuItem.action else { return false }
        
        switch action {
        case #selector(toggleSplitOrientation):
            let title = self.splitView.isVertical ? "Stack Editors Horizontally" : "Stack Editors Vertically"
            menuItem.title = NSLocalizedString(title, comment: "")
            return self.splitViewItems.count > 1
            
        case #selector(focusNextSplitTextView), #selector(focusPrevSplitTextView):
            return self.splitViewItems.count > 1
            
        default: break
        }
        
        return true
    }
    
    
    
    // MARK: Notifications
    
    /// editor's focus did change
    func textViewDidBecomeFirstResponder(_ notification: Notification) {
        
        guard let textView = notification.object as? CETextView else { return }
        
        for viewController in self.childViewControllers as! [EditorViewController] {
            if viewController.textView == textView {
                self.focusedSubviewController = viewController
                break
            }
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// add subview for given viewController at desired position
    func addSubview(for editorViewController: EditorViewController, relativeTo otherEditorViewController: EditorViewController?) {
        
        let splitViewItem = NSSplitViewItem(viewController: editorViewController)
        
        if let otherEditorViewController = otherEditorViewController {
            if let baseIndex = self.childViewControllers.index(of: otherEditorViewController) {
                self.insertSplitViewItem(splitViewItem, at: baseIndex + 1)
            }
        } else {
            self.addSplitViewItem(splitViewItem)
        }
        
        self.invalidateCloseSplitEditorButtons()
    }
    
    
    /// find viewController for given subview
    func viewController(for subview: NSView) -> EditorViewController? {
        
        for viewController in self.childViewControllers {
            if let viewController = viewController as? EditorViewController where viewController.view == subview {
                return viewController
            }
        }
        return nil
    }
    
    
    
    // MARK: Action Messages
    
    /// toggle divider orientation
    @IBAction func toggleSplitOrientation(_ sender: AnyObject?) {
        
        self.splitView.isVertical = !self.splitView.isVertical
        
        self.invalidateOpenSplitEditorButtons()
    }
    
    
    /// move focus to next text view
    @IBAction func focusNextSplitTextView(_ sender: AnyObject?) {
        
        self.focusSplitTextView(onNext: true)
    }
    
    
    /// move focus to previous text view
    @IBAction func focusPrevSplitTextView(_ sender: AnyObject?) {
        
        self.focusSplitTextView(onNext: false)
    }
    
    
    // MARK: Private Methods
    
    /// move focus to next/previous text view
    private func focusSplitTextView(onNext: Bool) {
        
        let count = self.splitViewItems.count
        
        guard count > 1 else { return }
        
        var index = self.childViewControllers.index(of: self.focusedSubviewController!) ?? 0
        index += onNext ? 1 : -1
        
        if index < 0 {
            index = count - 1
        } else if index >= count {
            index = 0
        }
        
        guard let nextEditorViewController = self.childViewControllers[index] as? EditorViewController else { return }
        
        self.view.window?.makeFirstResponder(nextEditorViewController.textView)
    }
    
    
    /// update "Split Editor" button state
    private func invalidateOpenSplitEditorButtons() {
        
        let isVertical = self.splitView.isVertical
        
        for viewController in self.childViewControllers as! [EditorViewController] {
            viewController.navigationBarController?.isSplitOrientationVertical = isVertical
        }
    }
    
    
    /// update "Close Split Editor" button state
    private func invalidateCloseSplitEditorButtons() {
        
        let isEnabled = self.splitViewItems.count > 1
        
        for viewController in self.childViewControllers as! [EditorViewController] {
            viewController.navigationBarController?.isCloseSplitButtonEnabled = isEnabled
        }
    }
    
}
