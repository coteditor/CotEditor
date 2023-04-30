//
//  InconsistentLineEndingsViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2023 1024jp
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
    static let lineEnding = Self("Line Ending")
}


final class InconsistentLineEndingsViewController: NSViewController {
    
    // MARK: Private Properties
    
    private var document: Document?  { self.representedObject as? Document }
    private var lineEndings: [ValueRange<LineEnding>] = []
    private var documentLineEnding: LineEnding = .lf
    
    private var observers: Set<AnyCancellable> = []
    
    @IBOutlet private weak var messageField: NSTextField?
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK: Lifecycle
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.document?.lineEndingScanner.$inconsistentLineEndings
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                self.lineEndings = $0.sorted(using: self.tableView?.sortDescriptors ?? [])
                self.tableView?.enclosingScrollView?.isHidden = $0.isEmpty
                self.tableView?.reloadData()
                self.updateMessage()
            }
            .store(in: &self.observers)
        
        self.document?.$lineEnding
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                self.documentLineEnding = $0
                self.updateMessage()
            }
            .store(in: &self.observers)
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.observers.removeAll()
    }
    
    
    
    // MARK: Actions
    
    /// Item in the table was clicked.
    @IBAction func selectItem(_ sender: NSTableView) {
        
        self.selectItem(at: sender.clickedRow)
    }
    
    
    
    // MARK: Private Methods
    
    /// Update the result message above the table.
    @MainActor private func updateMessage() {
        
        guard let messageField = self.messageField else { return assertionFailure() }
        
        messageField.textColor = self.lineEndings.isEmpty ? .secondaryLabelColor : .labelColor
        messageField.stringValue = {
            switch self.lineEndings.count {
                case 0:  return String(localized: "No issues found.")
                case 1:  return String(localized: "Found a line ending other than \(self.documentLineEnding.name).")
                default: return String(localized: "Found \(self.lineEndings.count) line endings other than \(self.documentLineEnding.name).")
            }
        }()
    }
    
    
    /// Select correspondence range of the item in the editor.
    ///
    /// - Parameter row: The index of items to select.
    @MainActor private func selectItem(at row: Int) {
        
        guard
            let item = self.lineEndings[safe: row],
            let textView = self.document?.textView
        else { return }
        
        textView.selectedRange = item.range
        textView.centerSelectionInVisibleArea(self)
    }
}



extension InconsistentLineEndingsViewController: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let tableView = notification.object as? NSTableView else { return }
        
        self.selectItem(at: tableView.selectedRow)
    }
}



extension InconsistentLineEndingsViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        self.lineEndings.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        guard
            let lineEnding = self.lineEndings[safe: row],
            let identifier = tableColumn?.identifier
        else { return nil }
        
        switch identifier {
            case .line:
                // calculate the line number first at this point to postpone the high cost processing as much as possible
                return self.document?.lineEndingScanner.lineNumber(at: lineEnding.location).formatted()
            case .lineEnding:
                return lineEnding.value.name
            default:
                fatalError()
        }
    }
    
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        
        guard
            tableView.sortDescriptors != oldDescriptors,
            self.lineEndings.compareCount(with: 1) == .greater
        else { return }
        
        self.lineEndings.sort(using: tableView.sortDescriptors)
        tableView.reloadData()
    }
}


extension ValueRange: KeySortable where Value == LineEnding {
    
    func compare(with other: Self, key: String) -> ComparisonResult {
        
        switch key {
            case "location":
                return self.location.compare(other.location)
                
            case "lineEnding":
                return self.value.index.compare(other.value.index)
                
            default:
                fatalError()
        }
    }
}
