/*
 
 DraggableArrayController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-08-18.
 
 ------------------------------------------------------------------------------
 
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

/// type identifiers for dragging operation
private enum PboardType {
    static let rows = "rows"
    static let objects = "objects"
}


final class DraggableArrayController: NSArrayController, NSTableViewDataSource {
    
    // MARK: Table Data Source Protocol
    
    /// start dragging
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        
        // register dragged type
        tableView.register(forDraggedTypes: [PboardType.rows, PboardType.objects])
        pboard.declareTypes([PboardType.rows, PboardType.objects], owner: self)
        
        // select rows to drag
        tableView.selectRowIndexes(rowIndexes, byExtendingSelection: false)
        
        // store row index info to pasteboard
        let rows = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.setData(rows, forType: PboardType.rows)
        
        // store objects to drag to pasteboard
        let objects = self.arrangedObjects.objects(at: rowIndexes)
        pboard.setPropertyList(objects, forType: PboardType.objects)
        
        return true
    }
    
    
    /// validate when dragged items come to tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        
        // accept only self drag-and-drop
        guard info.draggingSource() as? NSTableView == tableView else { return [] }
        
        if dropOperation == .on {
            tableView.setDropRow(row, dropOperation: .above)
        }
        
        return .move
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        
        // accept only self drag-and-drop
        guard info.draggingSource() as? NSTableView == tableView else { return false }
        
        // obtain original rows from paste board
        guard let data = info.draggingPasteboard().data(forType: PboardType.rows),
              let sourceRows = NSKeyedUnarchiver.unarchiveObject(with: data) as? IndexSet else { return false }
        
        let draggingItems = info.draggingPasteboard().propertyList(forType: PboardType.objects) as! [AnyObject]
        let destinationRow = row - sourceRows.count(in: Range(0...row))  // real insertion point after removing items to move
        let destinationRows = IndexSet(destinationRow..<(destinationRow + draggingItems.count))
        
        // update data
        self.remove(atArrangedObjectIndexes: sourceRows)
        self.insert(contentsOf: draggingItems, atArrangedObjectIndexes: destinationRows)
        
        // select dropped items
        tableView.selectRowIndexes(destinationRows, byExtendingSelection: false)
        
        return true
    }

}
