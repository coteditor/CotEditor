/*
 
 EncodingListViewController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-03-26.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

private let RowsPboardType = "CERowsPboardType"


extension Array {
    
    /// remove elements with IndexSet
    mutating func remove(in indexes: IndexSet) {
        
        for index in indexes.reversed() {
            self.remove(at: index)
        }
    }
    
    
    /// subset
    func elements(at indexes: IndexSet) -> [Element] {
        
        return indexes.flatMap({ index in
            guard index < self.count else { return nil }
            return self[index]
        })
    }
    
}




// MARK:

class EncodingListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    private var encodings: [NSNumber] {
        didSet {
            // validate restorebility
            self.canRestore = (encodings != self.defaultEncodings)
        }
    }
    private let defaultEncodings: [NSNumber]
    private dynamic var canRestore: Bool  // enability of "Restore Default" button
    
    @IBOutlet private weak var tableView: NSTableView?
    @IBOutlet private weak var deleteSeparatorButton: NSButton?
    
    
    
    // MARK:
    // MARK: Creation
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        self.defaultEncodings = NSUserDefaultsController.shared().initialValues?[CEDefaultEncodingListKey] as! [NSNumber]
        self.encodings = UserDefaults.standard().array(forKey: CEDefaultEncodingListKey) as! [NSNumber]
        self.canRestore = (self.encodings != self.defaultEncodings)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: View Controller Methods
    
    override var nibName: String? {
        
        return "EncodingListView"
    }
    
    
    
    // MARK: Table Data Source Protocol
    
    /// return number of rows in table
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return self.encodings.count
    }
    
    
    /// return content of each cell
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        
        let cfEncoding = CFStringEncoding.init(self.encodings[row].uint32Value)
        
        // separator
        if cfEncoding == kCFStringEncodingInvalidId {
            return CESeparatorString
        }
        
        // styled encoding name
        let encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
        let encodingName = NSString.localizedName(of: encoding)
        let ianaName = (CFStringConvertEncodingToIANACharSetName(cfEncoding) ?? "-") as String
        
        let attrString = NSMutableAttributedString(string: encodingName)
        attrString.append(AttributedString(string: " : " + ianaName,
                                           attributes: [NSForegroundColorAttributeName: NSColor.disabledControlTextColor()]))
        
        return attrString
    }
    
    
    /// start dragging
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        
        // register dragged type
        tableView.register(forDraggedTypes: [RowsPboardType])
        pboard.declareTypes([RowsPboardType], owner: self)
        
        // select rows to drag
        tableView.selectRowIndexes(rowIndexes, byExtendingSelection: false)
        
        // set dragged items to pasteboard
        let plist = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.setData(plist, forType: RowsPboardType)
        
        return true
    }
    
    
    /// validate when dragged items come to tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        
        // accept only self drag-and-drop
        guard info.draggingSource() as? NSTableView == tableView else { return [] }
        
        // avoid drop-on
        if dropOperation == .on {
            let newRow = min(row + 1, tableView.numberOfRows - 1)
            tableView.setDropRow(newRow, dropOperation: .above)
        }
        
        return .move
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        
        // accept only self drag-and-drop
        guard info.draggingSource() as? NSTableView == tableView else { return false }
        
        // obtain original rows from paste board
        guard let data = info.draggingPasteboard().data(forType: RowsPboardType),
              let sourceRows = NSKeyedUnarchiver.unarchiveObject(with: data) as? IndexSet else { return false }
        
        let draggingItems = self.encodings.elements(at: sourceRows)
        let destinationRow = row - sourceRows.count(in: Range(0...row))  // real insertion point after removing items to move
        let destinationRows = IndexSet(destinationRow..<(destinationRow + draggingItems.count))
        
        // update data
        self.encodings.remove(in: sourceRows)
        self.encodings.insert(contentsOf: draggingItems, at: destinationRow)
        
        // update UI
        tableView.beginUpdates()
        tableView.removeRows(at: sourceRows, withAnimation: .effectFade)
        tableView.insertRows(at: destinationRows, withAnimation: .effectGap)
        tableView.selectRowIndexes(destinationRows, byExtendingSelection: false)
        tableView.endUpdates()
        
        return true
    }
    
    
    
    // MARK: Table View Delegate
    
    /// update UI just before selected rows are changed
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        // update enability of "Delete Separator" button
        for index in self.tableView!.selectedRowIndexes.sorted() {
            let encoding = self.encodings[index].uint32Value
            
            if encoding == kCFStringEncodingInvalidId {
                self.deleteSeparatorButton?.isEnabled = true
                return
            }
        }
        
        self.deleteSeparatorButton?.isEnabled = false
    }
    
    
    @available(OSX 10.11, *)
    /// set action on swiping theme name
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        
        guard edge == .trailing else { return [] }
        
        let encoding = self.encodings[row].uint32Value
        
        // only separater can be removed
        guard encoding == kCFStringEncodingInvalidId else { return [] }
        
        // delete
        return [NSTableViewRowAction(style: .destructive,
                                     title: NSLocalizedString("Delete", comment: "table view action title"),
                                     handler: { [unowned self] (action: NSTableViewRowAction, row: Int) in
                                        tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideLeft)
                                        self.encodings.remove(at: row)
            })]
    }
    
    
    
    // MARK: Action Messages
    
    /// "OK" button was clicked
    @IBAction func save(_ sender: AnyObject?) {
        
        // write back current encoding list userDefaults
        UserDefaults.standard().set(self.encodings, forKey: CEDefaultEncodingListKey)
        
        self.dismiss(sender)
    }
    
    
    /// restore encoding setting to default
    @IBAction func revertDefaultEncodings(_ sender: AnyObject?) {
        
        self.encodings = self.defaultEncodings
        self.tableView?.reloadData()
    }
    
    
    /// add separator below the selection
    @IBAction func addSeparator(_ sender: AnyObject?) {
        
        let index = self.tableView!.selectedRow + 1
        
        self.addSeparator(at: index)
    }
    
    
    /// remove separator
    @IBAction func deleteSeparator(_ sender: AnyObject?) {
        
        let indexes = self.tableView!.selectedRowIndexes
        
        self.deleteSeparators(at: indexes)
    }
    
    
    
    // MARK: Private Methods
    
    /// add separator to desired row
    private func addSeparator(at rowIndex: Int) {
        
        // update data
        self.encodings.insert(NSNumber(value: kCFStringEncodingInvalidId), at: rowIndex)
        
        // update UI
        if let tableView = self.tableView {
            let indexes = IndexSet(integer: rowIndex)
            tableView.insertRows(at: indexes, withAnimation: .effectGap)
            tableView.selectRowIndexes(indexes, byExtendingSelection: false)
        }
    }
    
    
    /// remove separators at desired rows
    private func deleteSeparators(at rowIndexes: IndexSet) {
        
        guard !rowIndexes.isEmpty else { return }
        
        var toDeleteIndexes = IndexSet()
        
        // pick only separators up
        for index in toDeleteIndexes.sorted() {
            let encoding = self.encodings[index].uint32Value
            
            if encoding == kCFStringEncodingInvalidId {
                toDeleteIndexes.insert(index)
            }
        }
        
        guard !toDeleteIndexes.isEmpty else { return }
        
        // update UI
        if let tableView = self.tableView {
            tableView.selectRowIndexes(toDeleteIndexes, byExtendingSelection: false)
            tableView.removeRows(at: toDeleteIndexes, withAnimation: .slideUp)
        }
        
        // update data
        for index in toDeleteIndexes.sorted() {
            self.encodings.remove(at: index)
        }
    }
    
}
