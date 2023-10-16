//
//  NSTableView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-07-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2023 1024jp
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

extension NSTableView {
    
    /// The row view where the user clicked.
    final var clickedRowView: NSTableRowView? {
        
        guard self.clickedRow >= 0 else { return nil }
        
        return self.rowView(atRow: self.clickedRow, makeIfNecessary: false)
    }
}
