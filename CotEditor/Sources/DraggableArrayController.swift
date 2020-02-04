//
//  DraggableArrayController.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-08-18.
//
//  ---------------------------------------------------------------------------
//
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

private extension NSPasteboard.PasteboardType {
    
    static let rows = NSPasteboard.PasteboardType("rows")
}


final class DraggableArrayController: NSArrayController, NSTableViewDataSource {
    
    // MARK: Table Data Source Protocol
    
    /// start dragging
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        
        // register dragged type
        tableView.registerForDraggedTypes([.rows])
        pboard.declareTypes([.rows], owner: self)
        
        // select rows to drag
        tableView.selectRowIndexes(rowIndexes, byExtendingSelection: false)
        
        // store row index info to pasteboard
        guard let rows = try? NSKeyedArchiver.archivedData(withRootObject: rowIndexes, requiringSecureCoding: true) else { return false }
        
        pboard.setData(rows, forType: .rows)
        
        return true
    }
    
    
    /// validate when dragged items come to tableView
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        // accept only self drag-and-drop
        guard info.draggingSource as? NSTableView == tableView else { return [] }
        
        if dropOperation == .on {
            tableView.setDropRow(row, dropOperation: .above)
        }
        
        return .move
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        // accept only self drag-and-drop
        guard info.draggingSource as? NSTableView == tableView else { return false }
        
        // obtain original rows from paste board
        guard
            let data = info.draggingPasteboard.data(forType: .rows),
            let sourceRows = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSIndexSet.self, from: data) as IndexSet?
            else { return false }
        
        let draggingItems = (self.arrangedObjects as AnyObject).objects(at: sourceRows)
        
        let destinationRow = row - sourceRows.count(in: 0...row)  // real insertion point after removing items to move
        let destinationRows = IndexSet(destinationRow..<(destinationRow + draggingItems.count))
        
        // update
        NSAnimationContext.runAnimationGroup({ context in
            // update UI
            tableView.removeRows(at: sourceRows, withAnimation: .effectFade)
            tableView.insertRows(at: destinationRows, withAnimation: .effectGap)
            tableView.selectRowIndexes(destinationRows, byExtendingSelection: false)
        }, completionHandler: {
            // update data
            self.remove(atArrangedObjectIndexes: sourceRows)
            self.insert(contentsOf: draggingItems, atArrangedObjectIndexes: destinationRows)
        })
        
        return true
    }

}
