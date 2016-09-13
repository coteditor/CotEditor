/*
 
 SyntaxEditTableViewDelegate.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2014-09-08.
 
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

final class SyntaxEditTableViewDelegate: NSObject, NSTableViewDelegate {
    
    // MARK: Private Properties
    
    @IBOutlet private weak var arrayController: NSArrayController?
    
    
    
    // MARK:
    // MARK: Delegate
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        /// selection did change
        guard let tableView = notification.object as? NSTableView else { return }
        
        let row = tableView.selectedRow
        
        // the last row is selected
        guard row + 1 == tableView.numberOfRows else { return }
        
        tableView.scrollRowToVisible(row)
        
        guard let rowView = tableView.rowView(atRow: row, makeIfNecessary: false) else { return }
        
        // find the leftmost text field column
        var column = -1
        for index in 0 ..< rowView.numberOfColumns {
            if (rowView.view(atColumn: column) as? NSTableCellView)?.textField != nil {
                column = index
                break
            }
        }
        guard column < 0 else { return }  // no text field found
        
        // proceed on the next run loop
        //   -> Since the string of the selected cell cannot be read at this point.
        DispatchQueue.main.async {
            // start editing automatically if the leftmost cell of the added row is blank
            if (rowView.view(atColumn: column) as? NSTableCellView)?.textField?.stringValue == "" {
                tableView.editColumn(column, row: row, with: nil, select: true)
            }
        }
    }
    
    
    /// set action on swiping theme name
    @available(macOS 10.11, *)
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableRowActionEdge) -> [NSTableViewRowAction] {
        
        guard edge == .trailing else { return [] }
        guard let arrayController = self.arrayController else { return [] }
        
        // delete
        return [NSTableViewRowAction(style: .destructive,
                                     title: NSLocalizedString("Delete", comment: "table view action title"),
                                     handler: { (action: NSTableViewRowAction, row: Int) in
                                        NSAnimationContext.runAnimationGroup({ context in
                                            // update UI
                                            tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideLeft)
                                            }, completionHandler: {
                                                // update data
                                                arrayController.remove(atArrangedObjectIndex: row)
                                        })
        })]
    }
    
    
    
    // MARK: Action Messages
    
    @IBAction func didCheckboxClicked(_ sender: Any?) {
        
        // To perform this action,
        // checkbox (NSButton) and column (NSTableColumn) must have the same identifier as the style dict key
        
        guard let checkbox = sender as? NSButton,
              let identifier = checkbox.identifier else { return }
        
        // find tableView
        let superview = sequence(first: checkbox, next: { $0.superview }).first { (view: NSView) -> Bool in view is NSTableView }
        
        guard let tableView = superview as? NSTableView, tableView.numberOfSelectedRows > 1 else { return }
        
        let columnIndex = tableView.column(withIdentifier: identifier)
        let isChecked = checkbox.state == NSOnState
        
        tableView.enumerateAvailableRowViews { (rowView: NSTableRowView, row: Int) in
            guard rowView.isSelected else { return }
            
            if let view = rowView.view(atColumn: columnIndex) as? NSTableCellView {
                (view.objectValue as AnyObject?)?.setValue(NSNumber(value: isChecked), forKey: identifier)
            }
        }
    }
    
}
