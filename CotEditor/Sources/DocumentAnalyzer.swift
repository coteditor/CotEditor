//
//  DocumentAnalyzer.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2014-12-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2022 1024jp
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

final class DocumentAnalyzer {
    
    // MARK: Public Properties
    
    @Published private(set) var result: EditorCountResult = .init()
    
    var updatesAll = false
    var statusBarRequirements: EditorInfoTypes = []
    
    
    // MARK: Private Properties
    
    private weak var document: Document?  // weak to avoid cycle retain
    private var requiredInfoTypes: EditorInfoTypes  { self.updatesAll ? .all : self.statusBarRequirements }
    
    private var needsCountWholeText = true
    private var task: Task<Void, any Error>?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
    }
    
    
    deinit {
        self.task?.cancel()
    }
    
    
    
    // MARK: Public Methods
    
    /// update editor info (only if really needed)
    func invalidate(onlySelection: Bool = false) {
        
        guard !self.requiredInfoTypes.isEmpty else { return }
        guard let textView = self.document?.textView else { return }
        
        if !onlySelection {
            self.needsCountWholeText = true
        }
        
        // do nothing if only cursor is moved but no need to calculate the cursor location.
        if !self.needsCountWholeText,
           self.requiredInfoTypes.isDisjoint(with: .cursors),
           textView.selectedRange.isEmpty
        {
            self.result.lines.selected = 0
            self.result.characters.selected = 0
            self.result.words.selected = 0
            return
        }
        
        let delay: UInt64 = self.needsCountWholeText ? 10 : 200  // in milliseconds
        
        self.task?.cancel()
        self.task = Task {
            try await Task.sleep(nanoseconds: delay * 1_000_000)  // debounce
            
            let string = await textView.string.immutable
            let selectedRange = await textView.selectedRange
            
            let counter = EditorCounter(string: string,
                                        selectedRange: Range(selectedRange, in: string) ?? string.startIndex..<string.startIndex,
                                        requiredInfo: self.requiredInfoTypes,
                                        countsWholeText: self.needsCountWholeText)
            
            var result = try await counter.count()
            
            if counter.countsWholeText {
                self.needsCountWholeText = false
            } else {
                result.lines.entire = self.result.lines.entire
                result.characters.entire = self.result.characters.entire
                result.words.entire = self.result.words.entire
            }
            
            self.result = result
        }
    }
}
