//
//  PatternSortViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-01-05.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

final class PatternSortViewController: NSViewController {
    
    // MARK: Private Properties
    
    @objc dynamic private var sortOptions = SortOptions()
    @objc dynamic var sampleLine: String?
    
    private weak var tabViewController: NSTabViewController?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    /// keep tabViewController
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        guard
            self.tabViewController == nil,
            let tabViewController = segue.destinationController as? NSTabViewController
            else { return }
        
        self.tabViewController = tabViewController
    }
    
    
    
    // MARK: Actions
    
    /// switch sort key setting (tab) view
    @IBAction func changeSortPattern(_ sender: NSButton) {
        
        self.tabViewController?.selectedTabViewItemIndex = sender.tag
    }
    
    
    /// perform sort
    @IBAction func ok(_ sender: Any?) {
        
        guard
            let textView = self.representedObject as? NSTextView,
            let pattern = self.sortPattern
            else { return }
        
        do {
            try pattern.validate()
        } catch {
            NSAlert(error: error).beginSheetModal(for: self.view.window!)
            NSSound.beep()
            return
        }
        
        textView.sortLines(pattern: pattern, options: self.sortOptions)
        
        self.dismiss(sender)
    }
    
    
    
    // MARK: Private Methods
    
    // SortPattern currently edited
    private var sortPattern: SortPattern? {
        
        return self.tabViewController?.tabViewItems[self.tabViewController!.selectedTabViewItemIndex]
            .viewController?.representedObject as? SortPattern
    }
    
}



final class SortPatternTabViewController: NSTabViewController {
    
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        
        super.tabView(tabView, willSelect: tabViewItem)
    
        // initialize viewController in representedObject
        guard
            let item = tabViewItem,
            let viewController = item.viewController,
            viewController.representedObject == nil
            else { return }
        
        switch tabView.indexOfTabViewItem(item) {
        case 0:
            viewController.representedObject = EntireLineSortPattern()
        case 1:
            viewController.representedObject = CSVSortPattern()
        case 2:
            viewController.representedObject = RegularExpressionSortPattern()
        default:
            preconditionFailure()
        }
    }
    
}
