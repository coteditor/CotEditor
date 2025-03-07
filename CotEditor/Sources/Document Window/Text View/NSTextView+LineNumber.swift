//
//  NSTextView+LineNumber.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-10-20.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2024 1024jp
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
import LineEnding

extension NSTextView {
    
    struct LineEnumerationOptions: OptionSet {
        
        let rawValue: Int
        
        static let bySkippingExtraLine = Self(rawValue: 1 << 0)
        static let onlySelectionBoundary = Self(rawValue: 1 << 1)
    }
    
    
    /// Returns the 1-based line number at the given character index.
    ///
    /// This method has a performance advantage if the receiver has any LineRangeCalculating.
    ///
    /// - Parameter location: NSRange-based character index.
    /// - Returns: The number of lines (1-based).
    final func lineNumber(at location: Int) -> Int {
        
        self.lineRangeCalculating?.lineNumber(at: location) ?? (self.string as NSString).lineNumber(at: location)
    }
    
    
    /// Enumerates line fragments in area with line numbers.
    ///
    /// - Note: This API requires TextKit 1.
    ///
    /// - Parameters:
    ///   - range: The character range to process lines.
    ///   - options: The options to skip invoking `body` in some specific fragments.
    ///   - body: The closure executed for each line in the enumeration.
    ///   - lineRect: The line fragment rect.
    ///   - lineNumber: The number of logical line (1-based).
    ///   - isSelected: Whether the line is selected.
    final func enumerateLineFragments(in range: NSRange, options: LineEnumerationOptions = [], body: (_ lineRect: NSRect, _ lineNumber: Int, _ isSelected: Bool) -> Void) {
        
        guard let layoutManager = self.layoutManager else { return assertionFailure() }
        
        let length = (self.string as NSString).length
        let selectedRanges = (self.rangesForUserTextChange ?? self.selectedRanges).map(\.rangeValue)
        
        // count up lines until the interested area
        var index = range.lowerBound
        var lineNumber = self.lineNumber(at: index)
        
        // enumerate visible line numbers
        while index < range.upperBound {  // process logical lines
            let lineRange = self.lineRange(at: index)
            let lineGlyphIndex = layoutManager.glyphIndexForCharacter(at: lineRange.lowerBound)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: lineGlyphIndex, effectiveRange: nil, withoutAdditionalLayout: true)
            let isSelected: Bool = selectedRanges.contains {
                if options.contains(.onlySelectionBoundary) {
                    lineRange.contains($0.lowerBound)
                    || (!$0.isEmpty && lineRange.lowerBound < $0.upperBound && $0.upperBound <= lineRange.upperBound)
                } else {
                    lineRange.intersects($0)
                }
            } || (lineRange.upperBound == length &&
                  selectedRanges.last?.lowerBound == length &&
                  layoutManager.extraLineFragmentRect.isEmpty)
            
            body(lineRect, lineNumber, isSelected)
            
            index = lineRange.upperBound
            lineNumber += 1
        }
        
        guard
            !options.contains(.bySkippingExtraLine),
            range.upperBound == length || lineNumber == 1,
            !layoutManager.extraLineFragmentRect.isEmpty
        else { return }
        
        lineNumber = (lineNumber > 1) ? lineNumber : self.lineNumber(at: length)
        let isSelected = (selectedRanges.last?.lowerBound == length)
        
        body(layoutManager.extraLineFragmentRect, lineNumber, isSelected)
    }
    
    
    // MARK: Private Methods
    
    /// The object calculating line range.
    ///
    /// - Note: This API requires TextKit 1.
    private var lineRangeCalculating: (any LineRangeCalculating)? {
        
        (self.layoutManager as? LayoutManager)?.lineEndingScanner
    }
    
    
    /// Returns the 1-based line number at the given character index.
    ///
    /// This method has a performance advantage if the receiver has any LineRangeCalculating.
    ///
    /// - Note: This API requires TextKit 1.
    ///
    /// - Parameter location: NSRange-based character index.
    /// - Returns: The number of lines (1-based).
    private func lineRange(at location: Int) -> NSRange {
        
        self.lineRangeCalculating?.lineRange(at: location) ?? (self.string as NSString).lineRange(at: location)
    }
}
