//
//  FindPanelButtonViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2020 1024jp
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

final class FindPanelButtonViewController: NSViewController {
    
    // MARK: Private Properties
    
    private var findNextAfterReplaceObserver: UserDefaultsObservation?
    
    @IBOutlet private weak var replaceButton: NSButton?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// setup UI
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.invalidateReplaceButtonBehavior()
        
        // observe default change for the "Replace" button tooltip
        self.findNextAfterReplaceObserver?.invalidate()
        self.findNextAfterReplaceObserver = UserDefaults.standard.observe(key: .findNextAfterReplace) { [unowned self] _ in
            self.invalidateReplaceButtonBehavior()
        }
    }
    
    
    
    // MARK: Action Messages
    
    /// replace next matched string with given string
    @IBAction func replace(_ sender: Any?) {
        
        // perform "Replace & Find" instead of "Replace"
        if UserDefaults.standard[.findNextAfterReplace] {
            TextFinder.shared.replaceAndFind(sender)
        } else {
            TextFinder.shared.replace(sender)
        }
    }
    
    
    /// perform segmented Find Next/Previous button
    @IBAction func clickSegmentedFindButton(_ sender: NSSegmentedControl) {
        
        switch sender.selectedSegment {
            case 0:
                TextFinder.shared.findPrevious(sender)
            case 1:
                TextFinder.shared.findNext(sender)
            default:
                assertionFailure("Number of the find button segments must be 2.")
        }
    }
    
    
    
    // MARK: Private Methods
    
    /// toggle replace button behavior and tooltip
    private func invalidateReplaceButtonBehavior() {
        
        self.replaceButton?.toolTip = {
            if UserDefaults.standard[.findNextAfterReplace] {
                return "Replace the current selection with the replacement text, then find the next match.".localized
            } else {
                return "Replace the current selection with the replacement text.".localized
            }
        }()
    }
    
}
