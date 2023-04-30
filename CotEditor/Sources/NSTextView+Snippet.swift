//
//  NSTextView+Snippet.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-12-29.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2023 1024jp
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

extension EditorTextView: SnippetInsertable {
    
    @IBAction func insertSnippet(_ sender: NSMenuItem) {
        
        guard let snippet = sender.representedObject as? Snippet else { return assertionFailure() }
        
        self.insert(snippet: snippet)
    }
}


extension NSTextView {
    
    /// Insert the given snippet to the insertion points.
    ///
    /// - Parameter snippet: The snippet to insert.
    func insert(snippet: Snippet) {
        
        guard let ranges = self.rangesForUserTextChange?.map(\.rangeValue) else { return }
        
        let (strings, selectedRanges) = snippet.insertions(for: self.string, ranges: ranges)
        
        self.replace(with: strings, ranges: ranges, selectedRanges: selectedRanges, actionName: String(localized: "Insert Snippet"))
        self.centerSelectionInVisibleArea(self)
    }
}
