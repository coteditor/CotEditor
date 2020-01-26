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
//  © 2017-2020 1024jp
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
            let insertionRanges = self.rangesForUserTextChange as? [NSRange]
            else { return }
        
        let strings = [String](repeating: snippet.string, count: insertionRanges.count)
        
        let selectedRanges: [NSRange]? = {
            guard !snippet.selections.isEmpty else { return nil }
            
            return insertionRanges
                .map { range in
                    insertionRanges
                        .prefix { $0 != range }
                        .map { snippet.string.length - $0.length }
                        .reduce(range.location, +)
                }
                .flatMap { offset in snippet.selections.map { $0.shifted(offset: offset) } }
        }()
        
        self.replace(with: strings, ranges: insertionRanges, selectedRanges: selectedRanges, actionName: "Insert Snippet".localized)
    }
    
}
