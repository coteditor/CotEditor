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

import Combine
import Cocoa

final class DocumentAnalyzer {
    
    // MARK: Public Properties
    
    @Published private(set) var result: EditorCountResult = .init()
    
    var updatesAll = false
    var statusBarRequirements: EditorInfoTypes = []
    
    
    // MARK: Private Properties
    
    private weak var document: Document?  // weak to avoid cycle retain
    
    private var needsCountWholeText = true
    private lazy var updateDebouncer = Debouncer(delay: .milliseconds(200)) { [weak self] in self?.updateEditorInfo() }
    private var countTask: Task<Void, any Error>?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
    }
    
    
    deinit {
        self.countTask?.cancel()
    }
    
    
    
    // MARK: Public Methods
    
    /// update editor info (only if really needed)
    func invalidate(onlySelection: Bool = false) {
        
        if !onlySelection {
            self.needsCountWholeText = true
        }
        
        guard !self.requiredInfoTypes.isEmpty else { return }
        
        self.updateDebouncer.schedule(delay: onlySelection ? .milliseconds(10) : nil)
    }
    
    
    
    // MARK: Private Methods
    
    /// info types needed to be calculated
    var requiredInfoTypes: EditorInfoTypes {
        
        self.updatesAll ? .all : self.statusBarRequirements
    }
    
    
    /// update editor info (only if really needed)
    private func updateEditorInfo() {
        
        guard let textView = self.document?.textView else { return }
        
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
        
        let string = textView.string.immutable
        let selectedRange = Range(textView.selectedRange, in: string) ?? string.startIndex..<string.startIndex
        let counter = EditorCounter(string: string,
                                    selectedRange: selectedRange,
                                    requiredInfo: self.requiredInfoTypes,
                                    countsWholeText: self.needsCountWholeText)
        
        self.countTask?.cancel()
        self.countTask = Task {
            var result = try counter.count()
            
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
