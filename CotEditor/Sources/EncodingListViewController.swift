//
//  EncodingListViewController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-03-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
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

final class EncodingListViewController: NSViewController, NSTableViewDelegate {
    
    // MARK: Private Properties
    
    @objc private dynamic var encodings: [CFStringEncoding] = [] {
        
        didSet {
            // validate restorebility
            self.canRestore = (encodings != UserDefaults.standard.registeredValue(for: .encodingList))
        }
    }
    @objc private dynamic var canRestore = false  // availability of "Restore Default" button
    
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private weak var deleteSeparatorButton: NSButton?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override func viewWillAppear() {
        
        super.viewWillAppear()
        
        self.encodings = UserDefaults.standard[.encodingList]
    }
    
    
    
    // MARK: Table View Delegate
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        guard let textField = (rowView.view(atColumn: 0) as? NSTableCellView)?.textField else { return }
        
        let encoding = self.encodings[row]
        
        switch encoding {
            case kCFStringEncodingInvalidId:
                textField.stringValue = .separator
            
            case .utf8:
                textField.attributedStringValue = [encoding.attributedName(),
                                                   encoding.attributedName(withUTF8BOM: true)].joined(separator: "\n")
            
            default:
                textField.attributedStringValue = encoding.attributedName()
        }
    }
    
    
    /// update UI just after selected rows are changed
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        // update availability of "Delete Separator" button
        self.deleteSeparatorButton?.isEnabled = self.tableView!.selectedRowIndexes
            .contains { self.encodings[$0] == kCFStringEncodingInvalidId }
    }
    
    
    
    // MARK: Action Messages
    
    /// "OK" button was clicked
    @IBAction func save(_ sender: Any?) {
        
        // write back current encoding list userDefaults
        UserDefaults.standard[.encodingList] = self.encodings
        
        self.dismiss(sender)
    }
    
    
    /// restore encoding setting to default
    @IBAction func revertDefaultEncodings(_ sender: Any?) {
        
        self.encodings = UserDefaults.standard.registeredValue(for: .encodingList)
    }
    
    
    /// add separator below the selection
    @IBAction func addSeparator(_ sender: Any?) {
        
        let index = self.tableView!.selectedRow + 1
        
        self.addSeparator(at: index)
    }
    
    
    /// remove separator
    @IBAction func deleteSeparator(_ sender: Any?) {
        
        let indexes = self.tableView!.selectedRowIndexes
        
        self.deleteSeparators(at: indexes)
    }
    
    
    
    // MARK: Private Methods
    
    /// add separator to desired row
    private func addSeparator(at rowIndex: Int) {
        
        guard let tableView = self.tableView else { return assertionFailure() }
        
        let indexes = IndexSet(integer: rowIndex)
        
        NSAnimationContext.runAnimationGroup({ _ in
            // update UI
            tableView.insertRows(at: indexes, withAnimation: .effectGap)
        }, completionHandler: { [weak self] in
            // update data
            self?.encodings.insert(kCFStringEncodingInvalidId, at: rowIndex)
            
            tableView.selectRowIndexes(indexes, byExtendingSelection: false)
        })
    }
    
    
    /// remove separators at desired rows
    private func deleteSeparators(at rowIndexes: IndexSet) {
        
        // pick only separators up
        let toDeleteIndexes = rowIndexes.filteredIndexSet { self.encodings[$0] == kCFStringEncodingInvalidId }
        
        guard !toDeleteIndexes.isEmpty else { return }
        guard let tableView = self.tableView else { return assertionFailure() }
        
        NSAnimationContext.runAnimationGroup({ _ in
            // update UI
            tableView.removeRows(at: toDeleteIndexes, withAnimation: [.slideUp, .effectFade])
        }, completionHandler: { [weak self] in
            // update data
            self?.encodings.remove(in: toDeleteIndexes)
        })
    }
    
}



// MARK: - Private Extensions

private extension CFStringEncoding {
    
    static let utf8: CFStringEncoding = CFStringBuiltInEncodings.UTF8.rawValue
    
    
    /// Return encoding name with style.
    ///
    /// This funciton is designed __only for__ the encoding list table.
    ///
    /// - Parameter withUTF8BOM: True when needing to attach " with BOM" to the name if the encoding is .utf8.
    /// - Returns: A styled encoding name.
    func attributedName(withUTF8BOM: Bool = false) -> NSAttributedString {
        
        assert(!withUTF8BOM || self == .utf8)
        
        // styled encoding name
        let encoding = String.Encoding(cfEncoding: self)
        let fileEncoding = FileEncoding(encoding: encoding, withUTF8BOM: withUTF8BOM)
        let attrEncodingName = NSAttributedString(string: fileEncoding.localizedName)
        
        let ianaName = (CFStringConvertEncodingToIANACharSetName(self) as String?) ?? "-"
        let attrIanaName = NSAttributedString(string: " : " + ianaName,
                                              attributes: [.foregroundColor: NSColor.secondaryLabelColor])
        
        return attrEncodingName + attrIanaName
    }
    
}
