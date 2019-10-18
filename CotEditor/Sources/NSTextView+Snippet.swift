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
//  © 2017-2019 1024jp
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
        
        guard !snippet.string.isEmpty else { return }
        
        let ranges = (self.rangesForUserTextChange ?? self.selectedRanges).map { $0.rangeValue }
        let strings = [String](repeating: snippet.string, count: ranges.count)
        
        let selectedRanges: [NSRange]? = {
            guard let selection = snippet.selection else { return nil }
            
            let snippetLength = (snippet.string as NSString).length
            return ranges.map { range in
                let offset = ranges
                    .prefix { $0 != range }
                    .map { snippetLength - $0.length }
                    .reduce(range.location, +)

                return selection.shifted(offset: offset)
            }
        }()
        
        self.replace(with: strings, ranges: ranges, selectedRanges: selectedRanges, actionName: "Insert Snippet".localized)
    }
    
}
