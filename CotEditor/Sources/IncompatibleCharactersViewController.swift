//
//  IncompatibleCharsViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-12-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2023 1024jp
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

import AppKit
import Combine

/// Table column identifiers
private extension NSUserInterfaceItemIdentifier {
    
    static let line = Self("Line")
    static let character = Self("Character")
    static let converted = Self("Converted")
}


final class IncompatibleCharactersViewController: NSViewController {
    
    // MARK: Private Properties
    
    private var document: Document?  { self.representedObject as? Document }
    private var scanner: IncompatibleCharacterScanner?  { self.document?.incompatibleCharacterScanner }
    private var incompatibleCharacters: [IncompatibleCharacter] = []
    
    private var scannerObservers: Set<AnyCancellable> = []
    
    private var fixedHeightConstraint: NSLayoutConstraint?
    private var flexibleHeightConstraint: NSLayoutConstraint?
    private var currentTableHeight: CGFloat = 100
    
    @objc private dynamic var message: String?
    
    @IBOutlet private weak var messageField: NSTextField?
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK: -
    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set accessibility
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel("Incompatible Characters".localized)
    }
    
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        let isCollapsed = self.scanner?.incompatibleCharacters.isEmpty ?? true
        self.collapseView(isCollapsed, animate: false)
        
        self.scanner?.shouldScan = true
        self.scanner?.invalidate()
        self.updateMessage(isScanning: false)
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.scanner?.shouldScan = false
        
        if !self.incompatibleCharacters.isEmpty {
            self.document?.textStorage.clearAllMarkup()
        }
    }
    
    
    override var representedObject: Any? {
        
        willSet {
            self.scannerObservers.removeAll()
            
            guard newValue is Document else {
                assertionFailure("representedObject of \(self.className) must be an instance of \(Document.self)")
                return
            }
        }
        
        didSet {
            guard let scanner = self.scanner else { return }
            
            scanner.shouldScan = self.isViewShown
            scanner.invalidate()
            
            scanner.$incompatibleCharacters
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.didUpdateIncompatibleCharacters($0) }
                .store(in: &self.scannerObservers)
            scanner.$isScanning
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.updateMessage(isScanning: $0) }
                .store(in: &self.scannerObservers)
        }
    }
    
    
    
    // MARK: Actions
    
    /// Item in the table was clicked.
    @IBAction func selectItem(_ sender: NSTableView) {
        
        self.selectItem(at: sender.clickedRow)
    }
    
    
    
    // MARK: Private Methods
    
    @MainActor private func didUpdateIncompatibleCharacters(_ incompatibleCharacters: [IncompatibleCharacter]) {
        
        guard let textStorage = self.document?.textStorage else { return }
        
        if !self.incompatibleCharacters.isEmpty {
            textStorage.clearAllMarkup()
        }
        
        if self.isViewShown, incompatibleCharacters.isEmpty != self.incompatibleCharacters.isEmpty {
            self.collapseView(incompatibleCharacters.isEmpty, animate: true)
        }
        
        self.incompatibleCharacters = incompatibleCharacters.sorted(using: self.tableView?.sortDescriptors ?? [])
        self.tableView?.reloadData()
        
        self.updateMessage(isScanning: false)
        textStorage.markup(ranges: incompatibleCharacters.map(\.range))
    }
    
    
    /// Open / close the view by adjusting the height of the table.
    ///
    /// - Parameters:
    ///   - isCollapsed: The flag indicating whether open or close.
    ///   - animate: The flag indicating whether to animate the change.
    @MainActor private func collapseView(_ isCollapsed: Bool, animate: Bool) {
        
        guard let scrollView = self.tableView?.enclosingScrollView else { return assertionFailure() }
        
        if !scrollView.isHidden {
            self.currentTableHeight = scrollView.frame.height
        }
        
        let fixedConstraint = self.fixedHeightConstraint ?? scrollView.heightAnchor.constraint(equalToConstant: 30)
        self.fixedHeightConstraint = fixedConstraint
        let flexibleConstraint = self.flexibleHeightConstraint ?? scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        self.flexibleHeightConstraint = flexibleConstraint
        
        let visualHeight = isCollapsed ? 30 : self.currentTableHeight
        
        flexibleConstraint.isActive = false
        fixedConstraint.constant = scrollView.frame.height
        fixedConstraint.isActive = true
        
        scrollView.isHidden = isCollapsed
        NSAnimationContext.runAnimationGroup { (context) in
            if !animate {
                context.duration = 0
            }
            fixedConstraint.animator().constant = visualHeight
            
        } completionHandler: { [weak self] in
            if !isCollapsed {
                fixedConstraint.isActive = false
                flexibleConstraint.isActive = true
            }
            scrollView.frame.size.height = visualHeight
            self?.view.needsLayout = true
        }
    }
    
    
    /// Update the state message on the table.
    @MainActor private func updateMessage(isScanning: Bool) {
        
        self.messageField?.textColor = self.incompatibleCharacters.isEmpty ? .secondaryLabelColor : .labelColor
        self.messageField?.stringValue = {
            switch self.incompatibleCharacters.count {
                case _ where isScanning: return "Scanning incompatible characters…".localized
                case 0:  return "No issues found.".localized
                case 1:  return "Found an incompatible character.".localized
                default: return String(localized: "Found \(self.incompatibleCharacters.count) incompatible characters.")
            }
        }()
    }
    
    
    /// Select correspondence range of the item in the editor.
    ///
    /// - Parameter row: The index of items to select.
    @MainActor private func selectItem(at row: Int) {
        
        guard
            let item = self.incompatibleCharacters[safe: row],
            let textView = self.document?.textView
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
}



extension IncompatibleCharactersViewController: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let tableView = notification.object as? NSTableView else { return }
        
        self.selectItem(at: tableView.selectedRow)
    }
}



extension IncompatibleCharactersViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        self.incompatibleCharacters.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        guard
            let incompatibleCharacter = self.incompatibleCharacters[safe: row],
            let identifier = tableColumn?.identifier
        else { return nil }
        
        switch identifier {
            case .line:
                return self.document?.lineEndingScanner.lineNumber(at: incompatibleCharacter.location).formatted()
            case .character:
                return String(incompatibleCharacter.character)
            case .converted:
                return incompatibleCharacter.convertedCharacter
            default:
                fatalError()
        }
    }
    
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        
        guard
            tableView.sortDescriptors != oldDescriptors,
            self.incompatibleCharacters.compareCount(with: 1) == .greater
        else { return }
        
        self.incompatibleCharacters.sort(using: tableView.sortDescriptors)
        tableView.reloadData()
    }
}



extension IncompatibleCharacter: KeySortable {
    
    func compare(with other: Self, key: String) -> ComparisonResult {
        
        switch key {
            case "location":
                return self.location.compare(other.location)
                
            case "character":
                return String(self.character).localizedStandardCompare(String(other.character))
                
            case "convertedCharacter":
                switch (self.convertedCharacter, other.convertedCharacter) {
                    case let (.some(converted0), .some(converted1)):
                        return converted0.localizedStandardCompare(converted1)
                    case (.some, .none):
                        return .orderedAscending
                    case (.none, .some):
                        return .orderedDescending
                    case (.none, .none):
                        return .orderedSame
                }
                
            default:
                fatalError()
        }
    }
}


private extension NSTextStorage {
    
    /// change background color of pased-in ranges
    func markup(ranges: [NSRange]) {
        
        guard !ranges.isEmpty else { return }
        
        for manager in self.layoutManagers {
            guard let color = manager.firstTextView?.textColor?.withAlphaComponent(0.2) else { continue }
            
            for range in ranges {
                manager.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: range)
            }
        }
    }
    
    
    /// clear all background highlight (including text finder's highlights)
    func clearAllMarkup() {
        
        let range = self.string.nsRange
        
        for manager in self.layoutManagers {
            manager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: range)
        }
    }
}
