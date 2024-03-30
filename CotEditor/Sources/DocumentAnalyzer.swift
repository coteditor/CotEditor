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
//  © 2014-2024 1024jp
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

extension NSValue: @unchecked Sendable { }


final class DocumentAnalyzer {
    
    // MARK: Public Properties
    
    @Published private(set) var result: EditorCounter.Result = .init()
    
    var updatesAll = false  { didSet { Task { await self.updateTypes() } } }
    var statusBarRequirements: EditorCounter.Types = []  { didSet { Task { await self.updateTypes() } } }
    
    
    // MARK: Private Properties
    
    private let counter = EditorCounter()
    private weak var document: Document?  // weak to avoid cycle retain
    
    private var contentTask: Task<Void, any Error>?
    private var selectionTask: Task<Void, any Error>?
    
    
    
    // MARK: Lifecycle
    
    required init(document: Document) {
        
        self.document = document
    }
    
    
    
    // MARK: Public Methods
    
    /// Cancels all remaining tasks.
    func cancel() {
        
        self.contentTask?.cancel()
        self.selectionTask?.cancel()
    }
    
    
    /// Updates content counts.
    func invalidateContent() {
        
        self.contentTask?.cancel()
        self.contentTask = Task {
            guard await !self.counter.types.isDisjoint(with: .count) else { return }
            
            try await Task.sleep(for: .milliseconds(20), tolerance: .milliseconds(20))  // debounce
            
            guard let string = await self.document?.textView?.string.immutable else { return }
            
            try await self.counter.count(string: string)
            self.result = await self.counter.result
        }
    }
    
    
    /// Updates selection-related values.
    func invalidateSelection() {
        
        self.selectionTask?.cancel()
        self.selectionTask = Task {
            guard await !self.counter.types.isEmpty else { return }
            
            try await Task.sleep(for: .milliseconds(200), tolerance: .milliseconds(40))  // debounce
            
            guard let textView = await self.document?.textView else { return }
            
            let string = await textView.string.immutable
            let selectedRanges = await textView.selectedRanges
                .compactMap { Range($0.rangeValue, in: string) }
            
            try await self.counter.move(selectedRanges: selectedRanges, string: string)
            self.result = await self.counter.result
        }
    }
    
    
    // MARK: Private Methods
    
    /// Update types to count.
    private func updateTypes() async {
        
        let oldValue = await self.counter.types
        let newValue = self.updatesAll ? .all : self.statusBarRequirements
        
        await self.counter.update(types: newValue)
        
        if oldValue.intersection(.count) == newValue.intersection(.count) {
            self.invalidateContent()
        }
        self.invalidateSelection()
    }
}
