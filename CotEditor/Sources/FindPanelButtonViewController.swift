/*
 
 FindPanelButtonViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-06-26.
 
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

class FindPanelButtonViewController: NSViewController {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var replaceButton: NSButton?
    
    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultKey.findNextAfterReplace.rawValue)
    }
    
    
    
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.invalidateReplaceButtonBehavior()
        
        // observe default change for the "Replace" button tooltip
        UserDefaults.standard.addObserver(self, forKeyPath: DefaultKey.findNextAfterReplace.rawValue, options: .new, context: nil)
    }
    
    
    /// observed user defaults are changed
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        
        if keyPath == DefaultKey.findNextAfterReplace.rawValue {
            self.invalidateReplaceButtonBehavior()
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// replace next matched string with given string
    @IBAction func replace(_ sender: AnyObject?) {
        
        // perform "Replace & Find" instead of "Replace"
        if UserDefaults.standard.bool(forKey: DefaultKey.findNextAfterReplace.rawValue) {
            CETextFinder.shared().replaceAndFind(sender)
        } else {
            CETextFinder.shared().replace(sender)
        }
    }
    
    
    /// perform segmented Find Next/Previous button
    @IBAction func clickSegmentedFindButton(_ sender: AnyObject?) {
        
        guard let segmentedControl = sender as? NSSegmentedControl else { return }
        
        switch segmentedControl.selectedSegment {
        case 0:
            CETextFinder.shared().findPrevious(sender)
        case 1:
            CETextFinder.shared().findNext(sender)
        default:
            break
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// toggle replace button behavior and tooltip
    private func invalidateReplaceButtonBehavior() {
        
        if UserDefaults.standard.bool(forKey: DefaultKey.findNextAfterReplace.rawValue) {
            self.replaceButton?.toolTip = NSLocalizedString("Replace the current selection with the replacement text, then find the next match.", comment: "")
        } else {
            self.replaceButton?.toolTip = NSLocalizedString("Replace the current selection with the replacement text.", comment: "")
        }
    }
    
}
