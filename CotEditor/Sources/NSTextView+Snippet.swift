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
//  © 2017-2022 1024jp
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

extension NSTextView {
    
    func insert(snippet: Snippet) {
        
        guard
            !snippet.string.isEmpty,
            let insertionRanges = self.rangesForUserTextChange?.map(\.rangeValue)
            else { return }
        
        // insert indent to every newline
        let snippets: [Snippet] = insertionRanges.map { (range) in
            guard let indentRange = self.string.rangeOfIndent(at: range.location) else { return snippet }
            
            let indent = (self.string as NSString).substring(with: indentRange)
            
            return snippet.indented(with: indent)
        }
        
        let strings = snippets.map(\.string)
        let selectedRanges: [NSRange]? = snippet.selections.isEmpty
            ? nil
            : zip(snippets, insertionRanges)
                .flatMap { (snippet, range) -> [NSRange] in
                    let offset = insertionRanges
                        .prefix { $0 != range }
                        .map { snippet.string.length - $0.length }
                        .reduce(range.location, +)
                    
                    return snippet.selections.map { $0.shifted(by: offset) }
                }
        
        self.replace(with: strings, ranges: insertionRanges, selectedRanges: selectedRanges, actionName: "Insert Snippet".localized)
    }
    
}
