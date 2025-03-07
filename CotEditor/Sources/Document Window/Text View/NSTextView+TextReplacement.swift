//
//  NSTextView+TextReplacement.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-01-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2014-2025 1024jp
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
import StringUtils
import TextEditing

extension NSTextView {
    
    // MARK: Public Methods
    
    /// Replaces the contents according to EditingContext.
    @discardableResult
    final func edit(with context: EditingContext, actionName: String? = nil) -> Bool {
        
        self.replace(with: context.strings, ranges: context.ranges, selectedRanges: context.selectedRanges, actionName: actionName)
    }
    
    
    /// Performs simple text replacement.
    @discardableResult
    final func replace(with string: String, range: NSRange, selectedRange: NSRange?, actionName: String? = nil) -> Bool {
        
        let selectedRanges: [NSRange]? = selectedRange.map { [$0] }
        
        return self.replace(with: [string], ranges: [range], selectedRanges: selectedRanges, actionName: actionName)
    }
    
    
    /// Performs multiple text replacements.
    @discardableResult
    final func replace(with strings: [String], ranges: [NSRange], selectedRanges: [NSRange]?, actionName: String? = nil) -> Bool {
        
        assert(Thread.isMainThread)
        assert(strings.count == ranges.count, "unbalanced number of strings and ranges for multiple replacement")
        
        guard
            self.isEditable,
            !strings.isEmpty,
            let textStorage = self.textStorage
        else { return false }
        
        // register redo for text selection
        // -> Prefer using `rangesForUserTextChange` to save also multi-insertion points.
        self.setSelectedRangesWithUndo((self.rangesForUserTextChange ?? self.selectedRanges).map(\.rangeValue))
        
        // tell textEditor about beginning of the text processing
        guard self.shouldChangeText(inRanges: ranges as [NSValue], replacementStrings: strings) else { return false }
        
        // set action name
        if let actionName {
            self.undoManager?.setActionName(actionName)
        }
        
        // manually calculate the cursor locations after the replacement for multiple insertions
        let selectedRanges: [NSRange]? = {
            // use ones when explicitly specified
            if let selectedRanges { return selectedRanges }
            
            // let NSTextView calculate by single insertion editing
            guard
                let insertionRanges = self.rangesForUserTextChange?.map(\.rangeValue),
                insertionRanges.count > 1,
                insertionRanges == ranges
            else { return nil }
            
            var offset = 0
            return zip(ranges, strings).map { (range, string) in
                let length = string.length
                let location = range.lowerBound + offset + length
                offset += length - range.length
                
                return NSRange(location: location, length: 0)
            }
        }()
        
        textStorage.beginEditing()
        // use a backward enumeration to skip adjustment of applying location
        for (string, range) in zip(strings, ranges).reversed() {
            let attrString = NSAttributedString(string: string, attributes: self.typingAttributes)
            
            textStorage.replaceCharacters(in: range, with: attrString)
        }
        textStorage.endEditing()
        
        // post didEdit notification (It's not posted automatically, since here NSTextStorage is directly edited.)
        self.didChangeText()
        
        // apply new selection ranges
        self.setSelectedRangesWithUndo(selectedRanges ?? self.selectedRanges.map(\.rangeValue))
        
        return true
    }
    
    
    /// Performs undoable selection change.
    final func setSelectedRangesWithUndo(_ ranges: [NSRange]) {
        
        if let self = self as? any MultiCursorEditing,
           let set = self.prepareForSelectionUpdate(ranges)
        {
            self.selectedRanges = set.selectedRanges
            self.insertionLocations = set.insertionLocations
            
        } else {
            self.selectedRanges = ranges as [NSValue]
        }
        
        self.undoManager?.registerUndo(withTarget: self) { target in
            MainActor.assumeIsolated {
                target.setSelectedRangesWithUndo(ranges)
            }
        }
    }
    
    
    /// Transforms all selected strings and register to undo manager.
    ///
    /// When nothing is selected, this method performs the transformation to the word where the cursor exists.
    ///
    /// - Parameter block: The text transformation.
    /// - Returns: `true` if the text is processed.
    @discardableResult final func transformSelection(to block: (String) -> String) -> Bool {
        
        guard self.isEditable else { return false }
        
        // transform the word that contains the cursor if nothing is selected
        if self.selectedRange.isEmpty {
            self.selectWord(self)
        }
        
        let selectedRanges = self.selectedRanges.map(\.rangeValue)
        var strings: [String] = []
        var appliedRanges: [NSRange] = []
        var newSelectedRanges: [NSRange] = []
        var deltaLocation = 0
        
        for range in selectedRanges where !range.isEmpty {
            let substring = (self.string as NSString).substring(with: range)
            let string = block(substring)
            let newRange = NSRange(location: range.location - deltaLocation, length: string.length)
            
            strings.append(string)
            appliedRanges.append(range)
            newSelectedRanges.append(newRange)
            deltaLocation += range.length - newRange.length
        }
        
        guard !strings.isEmpty else { return false }
        
        return self.replace(with: strings, ranges: appliedRanges, selectedRanges: newSelectedRanges)
    }
    
    
    // MARK: Actions
    
    /// Inputs a backslash (\\) to the insertion points.
    @IBAction final func inputBackSlash(_ sender: Any?) {
        
        self.insertText("\\", replacementRange: .notFound)
    }
    
    
    /// Inputs an Yen sign (¥) to the insertion points.
    @IBAction final func inputYenMark(_ sender: Any?) {
        
        self.insertText("¥", replacementRange: .notFound)
    }
}


extension String {
    
    /// Creates a String from Any but `anyString` must be either String or NSAttributedString.
    ///
    /// - Parameter anyString: String or NSAttributedString.
    init?(anyString: Any) {
        
        guard let string = switch anyString {
            case let string as String: string
            case let attributedString as NSAttributedString: attributedString.string
            default: nil
        } else { return nil }
        
        self = string
    }
}
