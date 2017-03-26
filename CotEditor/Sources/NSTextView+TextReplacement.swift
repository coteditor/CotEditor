/*
 
 NSTextView+TextReplacement.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-10.
 
 ------------------------------------------------------------------------------
 
 © 2014-2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension NSTextView {
    
    // MARK: Public Methods
    
    /// perform simple text replacement
    @discardableResult
    func replace(with string: String, range: NSRange, selectedRange: NSRange?, actionName: String?) -> Bool {
        
        let selectedRanges: [NSRange]? = {
            guard let selectedRange = selectedRange else { return nil }
            
            return [selectedRange]
        }()
        
        return self.replace(with: [string], ranges: [range], selectedRanges: selectedRanges, actionName: actionName)
    }
    
    
    /// perform multiple text replacements
    @discardableResult
    func replace(with strings: [String], ranges: [NSRange], selectedRanges: [NSRange]?, actionName: String?) -> Bool {
        
        assert(Thread.isMainThread)
        assert(strings.count == ranges.count, "unbalanced number of strings and ranges for multiple replacement")
        
        guard !strings.isEmpty, let textStorage = self.textStorage else { return false }
        
        // register redo for text selection
        if let undoClient = self.undoManager?.prepare(withInvocationTarget: self) as? NSTextView {
            undoClient.setSelectedRangesWithUndo(self.selectedRanges as [NSRange])
        }
        
        // tell textEditor about beginning of the text processing
        guard self.shouldChangeText(inRanges: ranges as [NSValue], replacementStrings: strings) else { return false }
        
        // set action name
        if let actionName = actionName {
            self.undoManager?.setActionName(actionName)
        }
        
        let attributes = self.typingAttributes
        
        textStorage.beginEditing()
        // use backwards enumeration to skip adjustment of applying location
        for (string, range) in zip(strings, ranges).reversed() {
            let attrString = NSAttributedString(string: string, attributes: attributes)
            
            textStorage.replaceCharacters(in: range, with: attrString)
        }
        textStorage.endEditing()
        
        // post didEdit notification (It's not posted automatically, since here NSTextStorage is directly edited.)
        self.didChangeText()
        
        // apply new selection ranges
        self.setSelectedRangesWithUndo(selectedRanges ?? self.selectedRanges as [NSRange])
        
        return true
    }
    
    
    /// undoable selection change
    @objc func setSelectedRangesWithUndo(_ ranges: [NSRange]) {
        
        self.selectedRanges = ranges as [NSValue]
        
        guard let undoClient = self.undoManager?.prepare(withInvocationTarget: self) as? NSTextView else {
            assertionFailure("failed preparing undo.")
            return
        }
        
        undoClient.setSelectedRangesWithUndo(ranges as [NSRange])
    }
    
    
    /// trim all trailing whitespace with/without keeeping editing point
    func trimTrailingWhitespace(keepingEditingPoint: Bool = false) {
        
        assert(Thread.isMainThread)
        
        guard let string = self.string else { return }
        
        let regex = try! NSRegularExpression(pattern: "[ \\t]+$", options: .anchorsMatchLines)
        let ranges = regex.matches(in: string, range: string.nsRange).map { $0.range }
        
        // exclude editing line if needed
        let replacementRanges: [NSRange] = {
            guard keepingEditingPoint else { return ranges }
            
            let cursorLocation = self.selectedRange.location
            return ranges.filter { return $0.max != cursorLocation && !$0.contains(location: cursorLocation) }
        }()
        
        let replacementStrings = [String](repeating: "", count: replacementRanges.count)
        
        self.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: nil,
                     actionName: NSLocalizedString("Trim Trailing Whitespace", comment: ""))
    }
    
}
