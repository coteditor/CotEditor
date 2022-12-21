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
//  © 2014-2022 1024jp
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
    
    @IBOutlet private weak var findAllButton: NSButton?
    @IBOutlet private weak var replaceButton: NSButton?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // workaround an issue that NSComboButton cannnot be localized by .strings file
        self.findAllButton?.title = NSLocalizedString("Find All", comment: "")
        
        self.replaceButton?.toolTip = "Replace the current selection with the replacement text, then find the next match.".localized
    }
    
    
    
    // MARK: Action Messages
    
    /// Perform the segmented Find Next/Previous button.
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
}
