//
//  NSTextView+MultipleReplacement.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-03-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2022 1024jp
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
import SwiftUI

extension NSTextView {
    
    /// Highlight all matches in the textView.
    ///
    /// - Parameters:
    ///   - definition: The text view where highlighting text.
    ///   - inSelection: Whether find string only in selectedRanges.
    /// - Returns: A result message.
    /// - Throws: `CancellationError`
    @MainActor func highlight(_ definition: MultipleReplacement, inSelection: Bool) async throws -> String {
        
        self.isEditable = false
        defer { self.isEditable = true }
        
        let string = self.string.immutable
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        
        // setup progress sheet
        let progress = FindProgress(scope: 0..<definition.replacements.count)
        let indicatorView = FindProgressView("Highlight All", progress: progress, unit: .find)
        let indicator = NSHostingController(rootView: indicatorView)
        indicator.rootView.parent = indicator
        self.viewControllerForSheet?.presentAsSheet(indicator)
        
        // find in background thread
        let ranges = try await Task.detached(priority: .userInitiated) {
            try definition.find(string: string, ranges: selectedRanges, inSelection: inSelection, progress: progress)
                .sorted(\.location)
        }.value
        
        self.isEditable = true
        
        if progress.count > 0 {
            // apply to the text view
            if let layoutManager = self.layoutManager {
                let color = NSColor.textHighlighterColor
                layoutManager.groupTemporaryAttributesUpdate(in: string.nsRange) {
                    layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: string.nsRange)
                    for range in ranges {
                        layoutManager.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: range)
                    }
                }
            }
        } else {
            NSSound.beep()
        }
        
        progress.isFinished = true
        
        let message = String(localized: (progress.count == 0) ? "Not found" : "\(progress.count) found")
        
        self.requestAccessibilityAnnouncement(message)
        
        return message
    }
    
    
    /// Replace all matches in the textView.
    ///
    /// - Parameters:
    ///   - definition: The text view where highlighting text.
    ///   - inSelection: Whether find string only in selectedRanges.
    /// - Returns: A result message.
    /// - Throws: `CancellationError`
    @MainActor func replaceAll(_ definition: MultipleReplacement, inSelection: Bool) async throws -> String {
        
        self.isEditable = false
        defer { self.isEditable = true }
        
        let string = self.string.immutable
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        
        // setup progress sheet
        let progress = FindProgress(scope: 0..<(definition.replacements.count))
        let indicatorView = FindProgressView("Replace All", progress: progress, unit: .replacement)
        let indicator = NSHostingController(rootView: indicatorView)
        indicator.rootView.parent = indicator
        self.viewControllerForSheet?.presentAsSheet(indicator)
        
        // find in background thread
        let result = try await Task.detached(priority: .userInitiated) {
            try definition.replace(string: string, ranges: selectedRanges, inSelection: inSelection, progress: progress)
        }.value
        
        self.isEditable = true
        
        if progress.count > 0 {
            // apply to the text view
            self.replace(with: [result.string], ranges: [string.nsRange], selectedRanges: result.selectedRanges, actionName: "Replace All".localized)
        } else {
            NSSound.beep()
        }
        
        progress.isFinished = true
        
        let message = String(localized: (progress.count == 0) ? "Not replaced" : "\(progress.count) replaced")
        
        self.requestAccessibilityAnnouncement(message)
        
        return message
    }
}
