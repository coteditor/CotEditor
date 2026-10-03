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
//  © 2018-2026 1024jp
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
import LineEnding
import StringUtils
import TextFind

extension NSTextView {
    
    /// Highlights all matches in the textView.
    ///
    /// - Parameters:
    ///   - definition: The text view where highlighting text.
    ///   - inSelection: Whether find string only in selectedRanges.
    /// - Returns: A result message.
    /// - Throws: `CancellationError`.
    final func highlight(_ definition: MultipleReplace, inSelection: Bool) async throws -> String {
        
        let wasEditable = self.isEditable
        self.isEditable = false
        defer { self.isEditable = wasEditable }
        
        let string = self.string.immutable
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        let progress = FindProgress(scope: 0..<definition.replacements.endIndex)
        async let foundRanges = { @concurrent () async throws(CancellationError) -> [NSRange] in
            try definition.find(string: string, ranges: selectedRanges, inSelection: inSelection, progress: progress)
                .sorted(using: KeyPathComparator(\.location))
        }()
        
        // present progress view
        self.window?.beginSheet {
            FindProgressView(.init("Highlight All", table: "TextFind"), progress: progress, action: .find)
                .scenePadding()
        }
        
        // perform
        let ranges = try await foundRanges
        
        self.isEditable = wasEditable
        
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
    /// - Throws: `CancellationError`.
    @discardableResult final func replaceAll(_ definition: MultipleReplace, inSelection: Bool) async throws -> String {
        
        let wasEditable = self.isEditable
        self.isEditable = false
        defer { self.isEditable = wasEditable }
        
        let editorTextView = self as? EditorTextView
        let lineEnding = editorTextView?.lineEnding
        let string = self.string.immutable
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        let progress = FindProgress(scope: 0..<definition.replacements.endIndex)
        async let replacementResult = { @concurrent () async throws(CancellationError) -> MultipleReplace.Result in
            try definition.replace(string: string, ranges: selectedRanges, inSelection: inSelection, lineEnding: lineEnding, progress: progress)
        }()
        
        // present progress view
        self.window?.beginSheet {
            FindProgressView(.init("Replace All", table: "TextFind"), progress: progress, action: .replace)
                .scenePadding()
        }
        
        // perform
        let result = try await replacementResult
        
        self.isEditable = wasEditable
        
        if progress.count > 0 {
            // inserted text is already normalized; preserve line endings outside the matches
            let wasApproved = editorTextView?.isApprovedTextChange ?? false
            editorTextView?.isApprovedTextChange = true
            defer { editorTextView?.isApprovedTextChange = wasApproved }
            
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
