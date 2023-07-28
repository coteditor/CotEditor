//
//  EditorTextView+Indenting.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2023 1024jp
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

extension EditorTextView: Indenting {
    
    // MARK: Action Messages
    
    /// increase indent level
    @IBAction func shiftRight(_ sender: Any?) {
        
        if self.baseWritingDirection == .rightToLeft {
            guard self.outdent() else { return }
        } else {
            guard self.indent() else { return }
        }
        
        self.undoManager?.setActionName(String(localized: "Shift Right"))
    }
    
    
    /// decrease indent level
    @IBAction func shiftLeft(_ sender: Any?) {
        
        if self.baseWritingDirection == .rightToLeft {
            guard self.indent() else { return }
        } else {
            guard self.outdent() else { return }
        }
        
        self.undoManager?.setActionName(String(localized: "Shift Left"))
    }
    
    
    /// shift selection from segmented control button
    @IBAction func shift(_ sender: NSSegmentedControl) {
        
        switch sender.selectedSegment {
            case 0:
                self.shiftLeft(sender)
            case 1:
                self.shiftRight(sender)
            default:
                assertionFailure("Segmented shift button must have 2 segments only.")
        }
    }
    
    
    /// standardize indentation in selection to spaces
    @IBAction func convertIndentationToSpaces(_ sender: Any?) {
        
        self.convertIndentation(style: .space)
    }
    
    
    /// standardize indentation in selection to tabs
    @IBAction func convertIndentationToTabs(_ sender: Any?) {
        
        self.convertIndentation(style: .tab)
    }
}



// MARK: - Protocol

protocol Indenting: NSTextView {
    
    var tabWidth: Int { get }
    var isAutomaticTabExpansionEnabled: Bool { get }
}


extension Indenting {
    
    /// increase indent level
    @discardableResult
    func indent() -> Bool {
        
        guard
            self.tabWidth > 0,
            let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue)
        else { return false }
        
        // get indent target
        let string = self.string as NSString
        
        // create indent string to prepend
        let indent = self.isAutomaticTabExpansionEnabled ? String(repeating: " ", count: self.tabWidth) : "\t"
        let indentLength = indent.length
        
        // create shifted string
        let lineRanges = string.lineRanges(for: selectedRanges, includingLastEmptyLine: true)
        let newLines = lineRanges.map { indent + string.substring(with: $0) }
        
        // calculate new selection range
        let newSelectedRanges = selectedRanges.map { selectedRange -> NSRange in
            let shift = lineRanges.countPrefix { $0.location <= selectedRange.location }
            let lineCount = lineRanges.count { selectedRange.intersects($0) }
            let lengthDiff = max(lineCount - 1, 0) * indentLength
            
            return NSRange(location: selectedRange.location + shift * indentLength,
                           length: selectedRange.length + lengthDiff)
        }
        
        // apply to textView
        return self.replace(with: newLines, ranges: lineRanges, selectedRanges: newSelectedRanges)
    }
    
    
    /// decrease indent level
    @discardableResult
    func outdent() -> Bool {
        
        guard
            self.tabWidth > 0,
            let selectedRanges = self.rangesForUserTextChange?.map(\.rangeValue)
        else { return false }
        
        // get indent target
        let string = self.string as NSString
        
        // find ranges to remove
        let lineRanges = string.lineRanges(for: selectedRanges)
        let lines = lineRanges.map { string.substring(with: $0) }
        let dropCounts = lines.map { line -> Int in
            switch line.first {
                case "\t": 1
                case " ": line.prefix(self.tabWidth).countPrefix { $0 == " " }
                default: 0
            }
        }
        
        // cancel if nothing to shift
        guard dropCounts.contains(where: { $0 > 0 }) else { return false }
        
        // create shifted string
        let newLines = zip(lines, dropCounts).map { String($0.dropFirst($1)) }
        
        // calculate new selection range
        let droppedRanges: [NSRange] = zip(lineRanges, dropCounts)
            .filter { $1 > 0 }
            .map { NSRange(location: $0.location, length: $1) }
        let newSelectedRanges = selectedRanges.map { selectedRange -> NSRange in
            let offset = droppedRanges
                .prefix { $0.location < selectedRange.location }
                .map { (selectedRange.intersection($0) ?? $0).length }
                .reduce(0, +)
            let lengthDiff = droppedRanges
                .compactMap { selectedRange.intersection($0)?.length }
                .reduce(0, +)
            
            return NSRange(location: selectedRange.location - offset,
                           length: selectedRange.length - lengthDiff)
        }
        
        // apply to textView
        return self.replace(with: newLines, ranges: lineRanges, selectedRanges: newSelectedRanges)
    }
    
    
    /// standardize indentation of given ranges
    func convertIndentation(style: IndentStyle) {
        
        guard !self.string.isEmpty else { return }
        
        // process whole document if no text selected
        let ranges = self.selectedRange.isEmpty ? [self.string.nsRange] : self.selectedRanges.map(\.rangeValue)
        
        var replacementRanges: [NSRange] = []
        var replacementStrings: [String] = []
        
        for range in ranges {
            let selectedString = (self.string as NSString).substring(with: range)
            let convertedString = selectedString.standardizingIndent(to: style, tabWidth: self.tabWidth)
            
            guard convertedString != selectedString else { continue }  // no need to convert
            
            replacementRanges.append(range)
            replacementStrings.append(convertedString)
        }
        
        self.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: nil,
                     actionName: String(localized: "Convert Indentation"))
    }
}
