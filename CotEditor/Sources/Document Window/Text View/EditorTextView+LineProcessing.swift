//
//  EditorTextView+LineProcessing.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-10.
//
//  ---------------------------------------------------------------------------
//
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
import SwiftUI
import Defaults
import LineSort

extension EditorTextView {
    
    // MARK: Action Messages
    
    /// Moves selected line up.
    @IBAction func moveLineUp(_ sender: Any?) {
        
        guard
            let ranges = self.rangesForUserTextChange?.map(\.rangeValue),
            let context = self.string.moveLineUp(in: ranges)
        else { return NSSound.beep() }
        
        self.edit(with: context, actionName: String(localized: "Move Line", table: "MainMenu"))
        self.scrollRangeToVisible(self.selectedRange)
    }
    
    
    /// Moves selected line down.
    @IBAction func moveLineDown(_ sender: Any?) {
        
        guard
            let ranges = self.rangesForUserTextChange?.map(\.rangeValue),
            let context = self.string.moveLineDown(in: ranges)
        else { return NSSound.beep() }
        
        self.edit(with: context, actionName: String(localized: "Move Line", table: "MainMenu"))
        self.scrollRangeToVisible(self.selectedRange)
    }
    
    
    /// Sorts selected lines (only in the first selection) ascending.
    @IBAction func sortLinesAscending(_ sender: Any?) {
        
        // process whole document if no text selected
        let range = self.selectedRange.isEmpty ? self.string.range : self.selectedRange
        
        guard let context = self.string.sortLinesAscending(in: range) else { return }
        
        self.edit(with: context, actionName: String(localized: "Sort Lines", table: "MainMenu"))
    }
    
    
    /// Reverses selected lines (only in the first selection).
    @IBAction func reverseLines(_ sender: Any?) {
        
        // process whole document if no text selected
        let range = self.selectedRange.isEmpty ? self.string.range : self.selectedRange
        
        guard let context = self.string.reverseLines(in: range) else { return }
        
        self.edit(with: context, actionName: String(localized: "Reverse Lines", table: "MainMenu"))
    }
    
    
    /// Shuffles selected lines (only in the first selection).
    @IBAction func shuffleLines(_ sender: Any?) {
        
        // process whole document if no text selected
        let range = self.selectedRange.isEmpty ? self.string.range : self.selectedRange
        
        guard let context = self.string.shuffleLines(in: range) else { return }
        
        self.edit(with: context, actionName: String(localized: "Shuffle Lines", table: "MainMenu"))
    }
    
    
    /// Deletes duplicate lines in selection.
    @IBAction func deleteDuplicateLine(_ sender: Any?) {
        
        guard let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue) else { return }
        
        // process whole document if no text selected
        let ranges = self.selectedRange.isEmpty ? [self.string.range] : selectedRanges
        
        guard let context = self.string.deleteDuplicateLine(in: ranges) else { return }
        
        self.edit(with: context, actionName: String(localized: "Delete Duplicate Lines", table: "MainMenu"))
    }
    
    
    /// Duplicates selected lines below.
    @IBAction func duplicateLine(_ sender: Any?) {
        
        guard let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue) else { return }
        
        guard let context = self.string.duplicateLine(in: selectedRanges, lineEnding: self.lineEnding.rawValue) else { return }
        
        self.edit(with: context, actionName: String(localized: "Duplicate Line", table: "MainMenu"))
    }
    
    
    /// Removes selected lines.
    @IBAction func deleteLine(_ sender: Any?) {
        
        guard let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue) else { return }
        
        guard let context = self.string.deleteLine(in: selectedRanges) else { return }
        
        self.edit(with: context, actionName: String(localized: "Delete Line", table: "MainMenu"))
    }
    
    
    /// Joins the lines in the selections when the selections contain more than one line break; otherwise join the line where the cursor exists to the subsequent line.
    @IBAction func joinLines(_ sender: Any?) {
        
        guard let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue) else { return }
        
        let context = if selectedRanges.contains(where: { !$0.isEmpty }) {
            self.string.joinLines(in: selectedRanges)
        } else {
            self.string.joinLines(after: selectedRanges)
        }
        
        self.edit(with: context, actionName: String(localized: "Join Lines", table: "MainMenu"))
    }
    
    
    /// Trims all trailing whitespace.
    @IBAction func trimTrailingWhitespace(_ sender: Any?) {
        
        let trimsWhitespaceOnlyLines = UserDefaults.standard[.trimsWhitespaceOnlyLines]
        
        self.trimTrailingWhitespace(ignoringEmptyLines: !trimsWhitespaceOnlyLines)
    }
    
    
    /// Shows the pattern sort sheet.
    @IBAction func patternSort(_ sender: Any?) {
        
        guard self.isEditable else { return NSSound.beep() }
        
        // sample the first line
        let location = self.selectedRange.isEmpty
            ? self.string.startIndex
            : String.Index(utf16Offset: self.selectedRange.location, in: self.string)
        let lineRange = self.string.lineContentsRange(at: location)
        let sampleLine = String(self.string[lineRange])
        let fontName = self.font?.fontName
        
        let view = PatternSortView(sampleLine: sampleLine, sampleFontName: fontName) { [weak self] (pattern, options) in
            self?.sortLines(pattern: pattern, options: options)
        }
        let viewController = NSHostingController(rootView: view)
        viewController.rootView.parent = viewController
        
        self.viewControllerForSheet?.presentAsSheet(viewController)
    }
    
    
    // MARK: Private Methods
    
    /// Sorts lines in the text.
    ///
    /// - Parameters:
    ///   - pattern: The sort pattern.
    ///   - options: The sort options.
    private func sortLines(pattern: some SortPattern, options: SortOptions) {
        
        // process whole document if no text selected
        let range = self.selectedRange.isEmpty ? self.string.range : self.selectedRange
        
        let string = self.string as NSString
        let lineRange = string.lineContentsRange(for: range)
        
        guard !lineRange.isEmpty else { return }
        
        let newString = pattern.sort(string.substring(with: lineRange), options: options)
        
        self.replace(with: newString, range: lineRange, selectedRange: lineRange,
                     actionName: String(localized: "Sort Lines", table: "MainMenu"))
    }
}


extension NSTextView {
    
    /// Trims all trailing whitespace with/without keeping editing point.
    final func trimTrailingWhitespace(ignoringEmptyLines: Bool, keepingEditingPoint: Bool = false) {
        
        let editingRanges = (self.rangesForUserTextChange ?? self.selectedRanges).map(\.rangeValue)
        
        guard let context = self.string.trimTrailingWhitespace(ignoringEmptyLines: ignoringEmptyLines, keepingEditingPoint: keepingEditingPoint, in: editingRanges) else { return }
        
        self.edit(with: context, actionName: String(localized: "Trim Trailing Whitespace", table: "MainMenu"))
    }
}
