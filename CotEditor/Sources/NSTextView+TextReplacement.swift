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

import Cocoa

extension NSTextView {
    
    // MARK: Public Methods
    
    /// perform simple text replacement
    @discardableResult
    func replace(with string: String, range: NSRange, selectedRange: NSRange?, actionName: String? = nil) -> Bool {
        
        let selectedRanges: [NSRange]? = selectedRange.flatMap { [$0] }
        
        return self.replace(with: [string], ranges: [range], selectedRanges: selectedRanges, actionName: actionName)
    }
    
    
    /// perform multiple text replacements
    @discardableResult
    func replace(with strings: [String], ranges: [NSRange], selectedRanges: [NSRange]?, actionName: String? = nil) -> Bool {
        
        assert(Thread.isMainThread)
        assert(strings.count == ranges.count, "unbalanced number of strings and ranges for multiple replacement")
        
        guard !strings.isEmpty, let textStorage = self.textStorage else { return false }
        
        // register redo for text selection
        // -> Prefer using `rangesForUserTextChange` to save also multi-insertion points.
        self.setSelectedRangesWithUndo(self.rangesForUserTextChange ?? self.selectedRanges)
        
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
            
            // let NSTextView culculate by single insertion editing
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
    
    
    /// set undoable selection change
    func setSelectedRangesWithUndo(_ ranges: [NSValue]) {
        
        if let self = self as? MultiCursorEditing,
           let set = self.prepareForSelectionUpdate(ranges.map(\.rangeValue))
        {
            self.selectedRanges = set.selectedRanges
            self.insertionLocations = set.insertionLocations
            
        } else {
            self.selectedRanges = ranges
        }
        
        self.undoManager?.registerUndo(withTarget: self) { target in
            target.setSelectedRangesWithUndo(ranges)
        }
    }
    
    
    /// set undoable selection change
    func setSelectedRangesWithUndo(_ ranges: [NSRange]) {
        
        self.setSelectedRangesWithUndo(ranges as [NSValue])
    }
    
    
    /// trim all trailing whitespace with/without keeping editing point
    func trimTrailingWhitespace(ignoresEmptyLines: Bool, keepingEditingPoint: Bool = false) {
        
        assert(Thread.isMainThread)
        
        let ranges = self.string.rangesOfTrailingWhitespace(ignoresEmptyLines: ignoresEmptyLines)
        let editingRanges = (self.rangesForUserTextChange ?? self.selectedRanges).map(\.rangeValue)
        
        // exclude editing lines if needed
        let replacementRanges: [NSRange] = keepingEditingPoint
            ? ranges.filter { range in editingRanges.allSatisfy { !$0.touches(range) } }
            : ranges
        
        guard !replacementRanges.isEmpty else { return }
        
        let replacementStrings = [String](repeating: "", count: replacementRanges.count)
        
        // calculate selectedRanges after deletion
        let removedIndexes = replacementRanges
            .compactMap { Range($0) }
            .reduce(into: IndexSet()) { $0.insert(integersIn: $1) }
        let selectedRanges: [NSRange] = editingRanges.map { range in
            let location = range.location - removedIndexes.count { $0 < range.location }
            let length = range.length - removedIndexes.count { range.contains($0) }
            
            return NSRange(location: location, length: length)
        }
        
        self.replace(with: replacementStrings, ranges: replacementRanges, selectedRanges: selectedRanges,
                     actionName: "Trim Trailing Whitespace".localized)
    }
}



extension String {
    
    /// Create a String from Any but `anyString` must be either String or NSAttributedString.
    ///
    /// - Parameter anyString: String or NSAttributedString.
    init(anyString: Any) {
        
        switch anyString {
            case let string as String:
                self = string
            case let attributedString as NSAttributedString:
                self = attributedString.string
            default:
                preconditionFailure()
        }
    }
}


extension String {
    
    func rangesOfTrailingWhitespace(ignoresEmptyLines: Bool) -> [NSRange] {
        
        let pattern = ignoresEmptyLines ? "(?<!^|[ \\t])[ \\t]++$" : "[ \\t]++$"
        let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        
        return regex.matches(in: self, range: self.nsRange).map(\.range)
    }
}
