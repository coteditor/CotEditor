//
//  NSTextView+MultipleReplace.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-03-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2025 1024jp
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
import StringUtils
import TextFind

extension NSTextView {
    
    /// Highlights all matches in the textView.
    ///
    /// - Parameters:
    ///   - definition: The text view where highlighting text.
    ///   - inSelection: Whether find string only in selectedRanges.
    /// - Returns: A result message.
    /// - Throws: `CancellationError`
    final func highlight(_ definition: MultipleReplace, inSelection: Bool) async throws -> String {
        
        self.isEditable = false
        defer { self.isEditable = true }
        
        let string = self.string.immutable
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        
        let progress = FindProgress(scope: 0..<definition.replacements.endIndex)
        let task = Task.detached(priority: .userInitiated) {
            try definition.find(string: string, ranges: selectedRanges, inSelection: inSelection, progress: progress)
                .sorted(using: KeyPathComparator(\.location))
        }
        
        // setup progress sheet
        let indicatorView = FindProgressView(String(localized: "Highlight All", table: "TextFind"), progress: progress, action: .find)
        let indicator = NSHostingController(rootView: indicatorView)
        indicator.rootView.dismiss = { indicator.dismiss(nil) }
        self.viewControllerForSheet?.presentAsSheet(indicator)
        
        // perform
        let ranges = try await task.value
        
        self.isEditable = true
        
        if progress.count > 0 {
            // apply to the text view
            self.updateBackgroundColor(.textHighlighterColor, ranges: ranges)
        } else {
            NSSound.beep()
        }
        
        progress.finish()
        
        let message = FindResult(action: .find, count: progress.count).message
        
        AccessibilityNotification.Announcement(message).post()
        
        return message
    }
    
    
    /// Replaces all matches in the textView.
    ///
    /// - Parameters:
    ///   - definition: The text view where highlighting text.
    ///   - inSelection: Whether find string only in selectedRanges.
    /// - Returns: A result message.
    /// - Throws: `CancellationError`
    final func replaceAll(_ definition: MultipleReplace, inSelection: Bool) async throws -> String {
        
        self.isEditable = false
        defer { self.isEditable = true }
        
        let string = self.string.immutable
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        
        let progress = FindProgress(scope: 0..<definition.replacements.endIndex)
        let task = Task.detached(priority: .userInitiated) {
            try definition.replace(string: string, ranges: selectedRanges, inSelection: inSelection, progress: progress)
        }
        
        // setup progress sheet
        let indicatorView = FindProgressView(String(localized: "Replace All", table: "TextFind"), progress: progress, action: .replace)
        let indicator = NSHostingController(rootView: indicatorView)
        indicator.rootView.dismiss = { indicator.dismiss(nil) }
        self.viewControllerForSheet?.presentAsSheet(indicator)
        
        // perform
        let result = try await task.value
        
        self.isEditable = true
        
        if progress.count > 0 {
            // apply to the text view
            self.replace(with: [result.string], ranges: [string.nsRange], selectedRanges: result.selectedRanges, actionName: String(localized: "Replace All", table: "TextFind"))
        } else {
            NSSound.beep()
        }
        
        progress.finish()
        
        let message = FindResult(action: .replace, count: progress.count).message
        
        AccessibilityNotification.Announcement(message).post()
        
        return message
    }
}
