//
//  OutlineNavigator.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import Observation
import Combine
import Syntax

@MainActor @Observable final class OutlineNavigator {
    
    // MARK: Public Properties
    
    weak var textView: NSTextView?  { didSet { self.observeTextView() } }
    
    var items: [OutlineItem]?
    var selection: OutlineItem.ID?
    var isOutlinePickerPresented = false
    
    private(set) var isVerticalOrientation: Bool = false
    
    
    // MARK: Private Properties
    
    private var selectedRange: NSRange = .notFound
    private var viewObservers: Set<AnyCancellable> = []
    
    
    // MARK: Public Methods
    
    /// Can select the previous item in outline menu?
    var canSelectPreviousItem: Bool {
        
        self.items?.previousItem(for: self.selectedRange) != nil
    }
    
    
    /// Can select the next item in outline menu?
    var canSelectNextItem: Bool {
        
        self.items?.nextItem(for: self.selectedRange) != nil
    }
    
    
    /// Selects the previous outline item in editor.
    func selectPreviousItem() {
        
        guard let item = self.items?.previousItem(for: self.selectedRange) else { return }
        
        self.textView?.select(range: item.range)
    }
    
    
    /// Selects the next outline item in editor.
    func selectNextItem() {
        
        guard let item = self.items?.nextItem(for: self.selectedRange) else { return }
        
        self.textView?.select(range: item.range)
    }
    
    
    // MARK: Private Methods
    
    /// Observers text view update.
    private func observeTextView() {
        
        guard let textView = self.textView else { return assertionFailure() }
        
        self.selectedRange = textView.selectedRange
        self.viewObservers = [
            textView.publisher(for: \.layoutOrientation, options: .initial)
                .sink { [weak self] in self?.isVerticalOrientation = $0 == .vertical },
            
            NotificationCenter.default.publisher(for: NSTextView.didChangeSelectionNotification, object: textView)
                .map { $0.object as! NSTextView }
                .filter { !$0.hasMarkedText() }
            // avoid updating outline item selection before finishing outline parse
            // -> Otherwise, a wrong item can be selected because of using the outdated outline ranges.
            //    You can ignore text selection change at this time point as the outline selection will be updated when the parse finished.
                .filter { $0.textStorage?.editedMask.contains(.editedCharacters) == false }
                .debounce(for: .seconds(0.05), scheduler: RunLoop.main)
                .sink { [weak self] in self?.select(range: $0.selectedRange) },
        ]
    }
    
    
    /// Updates selection range related properties.
    ///
    /// - Parameter range: The new text selection range.
    private func select(range: NSRange) {
        
        self.selectedRange = range
        self.selection = self.items?.last { item in
            if item.isSeparator {
                false
            } else {
                item.range.location <= range.location
            }
        }?.id
    }
}
