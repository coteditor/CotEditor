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

final class PatternSortViewController: NSViewController, SortPatternViewControllerDelegate {
    
    // MARK: Private Properties
    
    @objc dynamic private var sortOptions = SortOptions()
    @objc dynamic var sampleLine: String?
    @objc dynamic var sampleFontName: String?
    
    @IBOutlet private weak var sampleLineField: NSTextField?
    
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
        
        tabViewController.tabViewItems
            .compactMap { $0.viewController as? SortPatternViewController }
            .forEach { $0.delegate = self }
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
            else { return assertionFailure() }
        
        do {
            try pattern.validate()
        } catch {
            NSAlert(error: error).beginSheetModal(for: self.view.window!)
            NSSound.beep()
            return
        }
        
        guard self.endEditing() else {
            NSSound.beep()
            return
        }
        
        textView.sortLines(pattern: pattern, options: self.sortOptions)
        
        self.dismiss(sender)
    }
    
    
    
    // MARK: Sort Pattern View Controller Delegate
    
    /// sort pattern setting did update
    func didUpdate(sortPattern: SortPattern) {
        
        guard
            let sampleLine = self.sampleLine,
            let field = self.sampleLineField
            else { return }
        
        let attributedLine = NSMutableAttributedString(string: sampleLine)
        
        try? sortPattern.validate()  // invalidate regex
        
        if let range = sortPattern.range(for: sampleLine) {
            let nsRange = NSRange(range, in: sampleLine)
            attributedLine.addAttribute(.backgroundColor, value: NSColor.selectedTextBackgroundColor, range: nsRange)
        }
        
        field.attributedStringValue = attributedLine
    }
    
    
    
    // MARK: Private Methods
    
    /// SortPattern currently edited
    private var sortPattern: SortPattern? {
        
        return self.tabViewController?.tabView.selectedTabViewItem?.viewController?.representedObject as? SortPattern
    }
    
}



// MARK: -

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



// MARK: -

protocol SortPatternViewControllerDelegate: AnyObject {
    
    func didUpdate(sortPattern: SortPattern)
}


final class SortPatternViewController: NSViewController, NSTextFieldDelegate {
    
    weak var delegate: SortPatternViewControllerDelegate?
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.valueDidUpdate(self)
    }
    
    
    /// text field value did change
    func controlTextDidChange(_ obj: Notification) {
        
        self.valueDidUpdate(self)
    }
    
    
    
    /// notify value change to delegate
    @IBAction func valueDidUpdate(_ sender: Any?) {
        
        guard let pattern = self.representedObject as? SortPattern else { return assertionFailure() }
        
        self.delegate?.didUpdate(sortPattern: pattern)
    }

}



// MARK: -

extension CSVSortPattern {
    
    override func setNilValueForKey(_ key: String) {
        
        // avoid rising an exception when number field becomes empty
        switch key {
        case #keyPath(column):
            self.column = 1
        default:
            super.setNilValueForKey(key)
        }
    }
    
}
