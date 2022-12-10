//
//  DefinitionTableViewDelegate.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-09-08.
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

final class DefinitionTableViewDelegate: NSObject, NSTableViewDelegate {
    
    // MARK: Delegate
    
    /// selection did change
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let tableView = notification.object as? NSTableView, tableView.numberOfRows > 0 else { return }
        
        let row = tableView.selectedRow
        
        // start editing automatically if the leftmost cell of the added row is blank
        guard
            row + 1 == tableView.numberOfRows,  // the last row is selected
            let rowView = tableView.rowView(atRow: row, makeIfNecessary: true),
            let (column, textField) = (0 ..< rowView.numberOfColumns).lazy  // find the leftmost text field column
                .compactMap({ (column) -> (Int, NSTextField)? in
                    guard let textField = (rowView.view(atColumn: column) as? NSTableCellView)?.textField else { return nil }
                    return (column, textField)
                }).first,
            textField.stringValue.isEmpty
        else { return }
        
        tableView.scrollRowToVisible(row)
        tableView.editColumn(column, row: row, with: nil, select: true)
    }
    
    
    
    // MARK: Action Messages
    
    /// update all selected checkboxes in the same column
    @IBAction func didCheckboxClicked(_ checkbox: NSButton) {
        
        // find tableView
        let superview = sequence(first: checkbox, next: \.superview).first { $0 is NSTableView }
        
        guard
            let tableView = superview as? NSTableView,
            tableView.numberOfSelectedRows > 1,
            tableView.selectedRowIndexes.contains(tableView.row(for: checkbox))
        else { return }
        
        let columnIndex = tableView.column(for: checkbox)
        
        guard columnIndex != -1 else { return }
        
        let identifier = tableView.tableColumns[columnIndex].identifier
        let isChecked = checkbox.state == .on
        
        tableView.enumerateAvailableRowViews { (rowView, _) in
            guard
                rowView.isSelected,
                let view = rowView.view(atColumn: columnIndex) as? NSTableCellView
            else { return }
            
            (view.objectValue as AnyObject?)?.setValue(NSNumber(value: isChecked), forKey: identifier.rawValue)
        }
    }
    
}
