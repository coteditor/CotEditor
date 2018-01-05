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
    
    @objc dynamic private var sortOption = SortOption()
    
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
        
        textView.sortLines(pattern: pattern, options: self.sortOption.compareOptions)
        
        self.dismiss(sender)
    }
    
    
    
    // MARK: Private Methods
    
    // SortPattern currently edited
    private var sortPattern: SortPattern? {
        
        return self.tabViewController?.tabViewItems[self.tabViewController!.selectedTabViewItemIndex]
            .viewController?.representedObject as? SortPattern
    }
    
}



final class CSVSortPatternViewController: NSViewController {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.representedObject = CSVSortPattern()
    }
    
}



final class RegexSortPatternViewController: NSViewController {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.representedObject = RegularExpressionSortPattern()
    }
    
}
