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
//  © 2014-2018 1024jp
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
    
    @objc private dynamic var encodings: [CFStringEncoding] {
        didSet {
            // validate restorebility
            self.canRestore = (encodings != self.defaultEncodings)
        }
    }
    private let defaultEncodings: [CFStringEncoding]
    @objc private dynamic var canRestore: Bool  // enability of "Restore Default" button
    
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private weak var deleteSeparatorButton: NSButton?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        
        self.defaultEncodings = (NSUserDefaultsController.shared.initialValues?[DefaultKeys.encodingList.rawValue] as! [UInt]).map { UInt32($0) }
        self.encodings = UserDefaults.standard[.encodingList]
        self.canRestore = (self.encodings != self.defaultEncodings)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override var nibName: NSNib.Name? {
        
        return NSNib.Name("EncodingListView")
    }
    
    
    
    // MARK: Table View Delegate
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        guard let textField = (rowView.view(atColumn: 0) as? NSTableCellView)?.textField else { return }
        
        let cfEncoding = CFStringEncoding(self.encodings[row])
        
        // separator
        if cfEncoding == kCFStringEncodingInvalidId {
            textField.stringValue = String.separator
            return
        }
        
        // styled encoding name
        let encoding = String.Encoding(cfEncoding: cfEncoding)
        let encodingName = String.localizedName(of: encoding)
        let attrEncodingName = NSAttributedString(string: encodingName)
        
        let ianaName = (CFStringConvertEncodingToIANACharSetName(cfEncoding) as String?) ?? "-"
        let attrIanaName = NSAttributedString(string: " : " + ianaName,
                                              attributes: [.foregroundColor: NSColor.disabledControlTextColor])
        
        textField.attributedStringValue = attrEncodingName + attrIanaName
    }
    
    
    /// update UI just after selected rows are changed
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        // update enability of "Delete Separator" button
        self.deleteSeparatorButton?.isEnabled = self.tableView!.selectedRowIndexes.contains { index in
            self.encodings[index] == kCFStringEncodingInvalidId
        }
    }
    
    
    /// set action on swiping row
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        
        guard edge == .trailing else { return [] }
        
        // only separater can be removed
        guard self.encodings[row] == kCFStringEncodingInvalidId else { return [] }
        
        // delete
        return [NSTableViewRowAction(style: .destructive,
                                     title: "Delete".localized(comment: "table view action title"),
                                     handler: { (action: NSTableViewRowAction, row: Int) in
                                        NSAnimationContext.runAnimationGroup({ context in
                                            // update UI
                                            tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideLeft)
                                            }, completionHandler: { [weak self] in
                                                // update data
                                                self?.encodings.remove(at: row)
                                        })
            })]
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
        
        self.encodings = self.defaultEncodings
        self.tableView?.reloadData()
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
        
        NSAnimationContext.runAnimationGroup({ context in
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
        let toDeleteIndexes = rowIndexes.filteredIndexSet { index in
            self.encodings[index] == kCFStringEncodingInvalidId
        }
        
        guard !toDeleteIndexes.isEmpty else { return }
        guard let tableView = self.tableView else { return assertionFailure() }
        
        NSAnimationContext.runAnimationGroup({ context in
            // update UI
            tableView.removeRows(at: toDeleteIndexes, withAnimation: [.slideUp, .effectFade])
        }, completionHandler: { [weak self] in
            // update data
            self?.encodings.remove(in: toDeleteIndexes)
        })
    }
    
}
