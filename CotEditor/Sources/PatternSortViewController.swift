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
//  © 2018-2022 1024jp
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
    
    private let sampleLine: String
    @objc private let sampleFontName: String?
    private let completionHandler: (_ pattern: any SortPattern, _ options: SortOptions) -> Void
    
    @objc private dynamic var sortOptions = SortOptions()
    
    @IBOutlet private weak var sampleLineField: NSTextField?
    
    private weak var tabViewController: NSTabViewController?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    /// Initialize view from a storyboard with given values.
    ///
    /// - Parameters:
    ///   - coder: The coder to instantiate the view from a storyboard.
    ///   - sampleLine: A line of target text to display as sample.
    ///   - fontName: The name of the editor font.
    ///   - completionHandler: The callback method to perform when the command was accepted.
    init?(coder: NSCoder, sampleLine: String, fontName: String? = nil, completionHandler: @escaping (_ pattern: any SortPattern, _ options: SortOptions) -> Void) {
        
        self.sampleLine = sampleLine
        self.sampleFontName = fontName
        self.completionHandler = completionHandler
        
        super.init(coder: coder)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// keep tabViewController
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        guard
            self.tabViewController == nil,
            let tabViewController = segue.destinationController as? NSTabViewController
        else { return }
        
        self.tabViewController = tabViewController
        
        tabViewController.tabViewItems
            .compactMap { $0.viewController as? SortPatternViewController }
            .forEach { $0.delegate = self }
    }
    
    
    
    // MARK: Action Messages
    
    /// switch sort key setting (tab) view
    @IBAction func changeSortPattern(_ sender: NSButton) {
        
        self.tabViewController?.selectedTabViewItemIndex = sender.tag
    }
    
    
    /// perform sort
    @IBAction func apply(_ sender: Any?) {
        
        guard self.endEditing() else { return NSSound.beep() }
        
        guard let pattern = self.sortPattern else { return assertionFailure() }
        do {
            try pattern.validate()
        } catch {
            NSAlert(error: error).beginSheetModal(for: self.view.window!)
            return NSSound.beep()
        }
        
        if let pattern = pattern as? RegularExpressionSortPattern {
            UserDefaults.standard[.regexPatternSortHistory].appendUnique(pattern.searchPattern, maximum: 10)
        }
        
        self.completionHandler(pattern, self.sortOptions)
        
        self.dismiss(sender)
    }
    
    
    
    // MARK: Sort Pattern View Controller Delegate
    
    /// sort pattern setting did update
    func didUpdate(sortPattern: any SortPattern) {
        
        guard let field = self.sampleLineField else { return }
        
        let attributedLine = NSMutableAttributedString(string: self.sampleLine)
        
        try? sortPattern.validate()  // invalidate regex
        
        if let range = sortPattern.range(for: self.sampleLine) {
            let nsRange = NSRange(range, in: self.sampleLine)
            attributedLine.addAttribute(.backgroundColor, value: NSColor.selectedTextBackgroundColor, range: nsRange)
        }
        
        field.attributedStringValue = attributedLine
    }
    
    
    
    // MARK: Private Methods
    
    /// SortPattern currently edited
    private var sortPattern: (any SortPattern)? {
        
        self.tabViewController?.tabView.selectedTabViewItem?.viewController?.representedObject as? any SortPattern
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
        
        viewController.representedObject = {
            switch tabView.indexOfTabViewItem(item) {
                case 0: return EntireLineSortPattern()
                case 1: return CSVSortPattern()
                case 2: return RegularExpressionSortPattern()
                default: preconditionFailure()
            }
        }()
    }
    
}



// MARK: -

protocol SortPatternViewControllerDelegate: AnyObject {
    
    func didUpdate(sortPattern: any SortPattern)
}


class SortPatternViewController: NSViewController, NSTextFieldDelegate {
    
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



final class RegularExpressionSortPatternViewController: SortPatternViewController, NSMenuDelegate {
    
    private let formatter = RegularExpressionFormatter()
    
    
    /// Insert a regular expression pattern to the field
    @IBAction func insertPattern(_ sender: NSMenuItem) {
        
        guard
            let regexPattern = sender.representedObject as? String,
            let sortPattern = self.representedObject as? RegularExpressionSortPattern
        else { return assertionFailure() }
        
        sortPattern.searchPattern = regexPattern
        self.valueDidUpdate(sender)
    }
    
    
    @IBAction func clearRecents(_ sender: Any?) {
        
        UserDefaults.standard[.regexPatternSortHistory].removeAll()
    }
    
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        
        menu.items.removeAll()
        menu.addItem(.init())  // dummy item
        menu.addItem(HeadingMenuItem(title: "Recents".localized))
        
        guard !UserDefaults.standard[.regexPatternSortHistory].isEmpty else { return }
        
        menu.items += UserDefaults.standard[.regexPatternSortHistory]
            .map {
                let item = NSMenuItem()
                item.attributedTitle = self.formatter.attributedString(for: $0)
                item.representedObject = $0
                item.action = #selector(insertPattern)
                item.target = self
                return item
            }
            .reversed()
        menu.addItem(.separator())
        menu.addItem(withTitle: "Clear Recents".localized, action: #selector(clearRecents), keyEquivalent: "")
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
