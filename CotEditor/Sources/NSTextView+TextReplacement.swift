/*
 
 NSTextView+TextReplacement.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-10.
 
 ------------------------------------------------------------------------------
 
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension NSTextView {
    
    // MARK: Public Methods
    
    /// treat programmatic text insertion
    func insert(string: String) {
        
        let replacementRange = self.selectedRange()
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.setSelectedRange(NSRange(location: replacementRange.location, length: string.utf16.count))
        
        self.undoManager?.setActionName(NSLocalizedString("Insert Text", comment: ""))
        
        self.didChangeText()
    }
    
    
    /// insert given string just after current selection and select inserted range
    func insertAfterSelection(string: String) {
        
        let replacementRange = NSRange(location: self.selectedRange().max, length: 0)
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.setSelectedRange(NSRange(location: replacementRange.location, length: string.utf16.count))
        
        self.undoManager?.setActionName(NSLocalizedString("Insert Text", comment: ""))
        
        self.didChangeText()
    }
    
    
    /// swap whole current string with given string and select inserted range
    func replaceAllString(with string: String) {
        
        let replacementRange = self.string?.nsRange ?? NSRange()
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.setSelectedRange(NSRange(location: replacementRange.location, length: string.utf16.count))
        
        self.undoManager?.setActionName(NSLocalizedString("Replace Text", comment: ""))
        
        self.didChangeText()
    }
    
    /// append string at the end of the whole string and select inserted range
    func append(string: String) {
        
        let replacementRange = NSRange(location: self.string?.utf16.count ?? 0, length: 0)
        
        guard self.shouldChangeText(in: replacementRange, replacementString: string) else { return }
        
        self.replaceCharacters(in: replacementRange, with: string)
        self.setSelectedRange(NSRange(location: replacementRange.location, length: string.utf16.count))
        
        self.undoManager?.setActionName(NSLocalizedString("Insert Text", comment: ""))
        
        self.didChangeText()
    }
    
    
    /// perform simple text replacement
    @discardableResult
    func replace(with string: String?, range: NSRange, selectedRange: NSRange?, actionName: String?) -> Bool {
        
        guard let string = string else { return false }
        
        let selectedRanges: [NSRange]? = {
            guard let selectedRange = selectedRange else { return nil }
            
            return [selectedRange]
        }()
        
        return self.replace(with: [string], ranges: [range], selectedRanges: selectedRanges, actionName: actionName)
    }
    
    
    /// perform multiple text replacements
    @discardableResult
    func replace(with strings: [String], ranges: [NSRange], selectedRanges: [NSRange]?, actionName: String?) -> Bool {
        
        assert(strings.count == ranges.count, "unbalanced number of strings and ranges for multiple replacement")
        
        guard !strings.isEmpty, let textStorage = self.textStorage else { return false }
        
        // register redo for text selection
        self.undoManager?.prepare(withInvocationTarget: self).setSelectedRangesWithUndo(self.selectedRanges)
        
        // tell textEditor about beginning of the text processing
        guard self.shouldChangeText(inRanges: ranges, replacementStrings: strings) else { return false }
        
        // set action name
        if let actionName = actionName {
            self.undoManager?.setActionName(actionName)
        }
        
        let attributes = self.typingAttributes
        
        textStorage.beginEditing()
        // use backwards enumeration to skip adjustment of applying location
        for (string, range) in zip(strings, ranges).reversed() {
            let attrString = AttributedString(string: string, attributes: attributes)
            
            textStorage.replaceCharacters(in: range, with: attrString)
        }
        textStorage.endEditing()
        
        // post didEdit notification (It's not posted automatically, since here NSTextStorage is directly edited.)
        self.didChangeText()
        
        // apply new selection ranges
        if let selectedRanges = selectedRanges {
            self.setSelectedRangesWithUndo(selectedRanges)
        } else {
            self.setSelectedRangesWithUndo(self.selectedRanges)
        }
        
        return true
    }
    
    
    /// undoable selection change
    @objc(setSelectedRangesWithUndo:)
    func setSelectedRangesWithUndo(_ ranges: [NSValue]) {
        
        self.selectedRanges = ranges
        self.undoManager?.prepare(withInvocationTarget: self).setSelectedRangesWithUndo(ranges)
    }
    
    
    /// trim all trailing whitespace with/without keeeping editing point
    func trimTrailingWhitespace(keepingEditingPoint: Bool = false) {
        
        guard let string = self.string else { return }
        
        var replacementStrings = [String]()
        var replacementRanges = [NSRange]()
        
        var cursorLocation = NSNotFound
        if keepingEditingPoint && self.selectedRange().length == 0 {
            cursorLocation = self.selectedRange().location
        }
        
        let regex = try! RegularExpression(pattern: "[ \\t]+$", options: .anchorsMatchLines)
        regex.enumerateMatches(in: string, range: string.nsRange) { (result: TextCheckingResult?, flags: RegularExpression.MatchingFlags, stop) in
            
            guard let range = result?.range, range.max != cursorLocation && NSLocationInRange(cursorLocation, range) else { return }
            
            replacementRanges.append(range)
            replacementStrings.append("")
        }
        
        self.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: nil,
                     actionName: NSLocalizedString("Trim Trailing Whitespace", comment: ""))
    }
    
}
