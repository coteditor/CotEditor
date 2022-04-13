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
//  © 2022 1024jp
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
import Combine

/// Table column identifiers
private extension NSUserInterfaceItemIdentifier {
    
    static let line = Self("Line")
    static let lineEnding = Self("Line Ending")
}


final class InconsistentLineEndingsViewController: NSViewController {
    
    // MARK: Private Properties
    
    private var document: Document?  { self.representedObject as? Document }
    private var lineEndings: [LineEndingLocation] = []
    
    private var observers: Set<AnyCancellable> = []
    
    @objc private dynamic var documentLineEnding: String?
    
    @IBOutlet private var numberFormatter: NumberFormatter?
    @IBOutlet private weak var tableView: NSTableView?
    
    
    
    // MARK: Lifecycle
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.document?.lineEndingScanner.$inconsistentLineEndings
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [unowned self] in
                self.lineEndings = $0
                self.tableView?.reloadData()
            }
            .store(in: &self.observers)
        
        self.document?.$lineEnding
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [unowned self] in self.documentLineEnding = $0.name }
            .store(in: &self.observers)
    }
    
    
    override func viewDidDisappear() {
        
        super.viewDidDisappear()
        
        self.observers.removeAll()
    }
    
}



extension InconsistentLineEndingsViewController: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard
            let tableView = notification.object as? NSTableView,
            let selectedLineEnding = self.lineEndings[safe: tableView.selectedRow],
            let textView = self.document?.textView
        else { return }
        
        textView.selectedRange = selectedLineEnding.range
        textView.scrollRangeToVisible(textView.selectedRange)
        textView.showFindIndicator(for: textView.selectedRange)
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
                return self.document?.string.lineNumber(at: lineEnding.location)
            case .lineEnding:
                return lineEnding.lineEnding.name
            default:
                fatalError()
        }
    }
    
}
