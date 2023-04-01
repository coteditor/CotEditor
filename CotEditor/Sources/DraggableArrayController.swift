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

import Cocoa

final class DraggableArrayController: NSArrayController, NSTableViewDataSource {
    
    // MARK: Table Data Source Protocol
    
    /// start dragging
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> (any NSPasteboardWriting)? {
        
        tableView.registerForDraggedTypes([.string])
        
        let item = NSPasteboardItem()
        item.setString(String(row), forType: .string)
        
        return item
    }
    
    
    /// validate when dragged items come to tableView
    func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        // accept only self drag-and-drop
        guard info.draggingSource as? NSTableView == tableView else { return [] }
        
        if dropOperation == .on {
            tableView.setDropRow(row, dropOperation: .above)
        }
        
        return .move
    }
    
    
    /// check acceptability of dragged items and insert them to table
    func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        // accept only self drag-and-drop
        guard info.draggingSource as? NSTableView == tableView else { return false }
        
        // obtain original rows from pasteboard
        var sourceRows = IndexSet()
        info.enumerateDraggingItems(options: .concurrent, for: tableView, classes: [NSPasteboardItem.self]) { (item, _, _) in
            guard
                let string = (item.item as? NSPasteboardItem)?.string(forType: .string),
                let row = Int(string)
            else { return }
            
            sourceRows.insert(row)
        }
        
        let draggingItems = (self.arrangedObjects as AnyObject).objects(at: sourceRows)
        
        let destinationRow = row - sourceRows.count(in: 0...row)  // real insertion point after removing items to move
        let destinationRows = IndexSet(destinationRow..<(destinationRow + draggingItems.count))
        
        // update
        NSAnimationContext.runAnimationGroup({ _ in
            // update UI
            var sourceOffset = 0
            var destinationOffset = 0
            
            tableView.beginUpdates()
            for sourceRow in sourceRows {
                if sourceRow < row {
                    tableView.moveRow(at: sourceRow + sourceOffset, to: row - 1)
                    sourceOffset -= 1
                } else {
                    tableView.moveRow(at: sourceRow, to: row + destinationOffset)
                    destinationOffset += 1
                }
            }
            tableView.endUpdates()
            
        }, completionHandler: {
            // update data
            self.remove(atArrangedObjectIndexes: sourceRows)
            self.insert(contentsOf: draggingItems, atArrangedObjectIndexes: destinationRows)
        })
        
        return true
    }
}
