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

extension NSTextView {
    
    struct LineEnumerationOptions: OptionSet {
        
        let rawValue: Int
        
        static let bySkippingExtraLine = Self(rawValue: 1 << 0)
    }
    
    
    
    /// Returns the 1-based line number at the given character index.
    ///
    /// This method has a performance advantage if the receiver's layoutManager conforms LineRangeCacheable.
    ///
    /// - Parameter location: NSRange-based character index.
    /// - Returns: The number of lines (1-based).
    final func lineNumber(at location: Int) -> Int {
        
        (self.layoutManager as? any LineRangeCacheable)?.lineNumber(at: location) ?? (self.string as NSString).lineNumber(at: location)
    }
    
    
    /// Enumerates line fragments in area with line numbers.
    ///
    /// - Parameters:
    ///   - rect: The bounding rectangle for which to process lines.
    ///   - range: The character range to process lines, or `nil` to enumerate whole in rect.
    ///   - options: The options to skip invoking `body` in some specific fragments.
    ///   - body: The closure executed for each line in the enumeration.
    ///   - lineRect: The line fragment rect.
    ///   - lineNumber: The number of logical line (1-based).
    ///   - isSelected: Whether the line is selected.
    final func enumerateLineFragments(in rect: NSRect, for range: NSRange? = nil, options: LineEnumerationOptions = [], body: (_ lineRect: NSRect, _ lineNumber: Int, _ isSelected: Bool) -> Void) {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
        else { return assertionFailure() }
        
        // get range of which line number should be drawn
        // -> Requires additionalLayout to obtain glyphRange for markedText. (2018-12 macOS 10.14 SDK)
        guard let rangeToDraw: NSRange = {
            let layoutRect = rect.offset(by: -self.textContainerOrigin)
            let rectGlyphRange = layoutManager.glyphRange(forBoundingRect: layoutRect, in: textContainer)
            let rectRange = layoutManager.characterRange(forGlyphRange: rectGlyphRange, actualGlyphRange: nil)
            
            guard let range else { return rectRange }
            
            return rectRange.intersection(range)
        }() else { return }
        
        let string = self.string as NSString
        let selectedRanges = (self.rangesForUserTextChange ?? self.selectedRanges).map(\.rangeValue)
        
        // count up lines until the interested area
        var index = rangeToDraw.lowerBound
        var lineNumber = self.lineNumber(at: index)
        
        // enumerate visible line numbers
        while index < rangeToDraw.upperBound {  // process logical lines
            let lineRange = self.lineRange(at: index)
            let lineGlyphIndex = layoutManager.glyphIndexForCharacter(at: lineRange.lowerBound)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: lineGlyphIndex, effectiveRange: nil, withoutAdditionalLayout: true)
            let isSelected = selectedRanges.contains { $0.intersects(lineRange) }
                || (lineRange.upperBound == string.length &&
                    lineRange.upperBound == selectedRanges.last?.upperBound &&
                    layoutManager.extraLineFragmentRect.isEmpty)
            
            body(lineRect, lineNumber, isSelected)
            
            index = lineRange.upperBound
            lineNumber += 1
        }
        
        guard
            !options.contains(.bySkippingExtraLine),
            (rangeToDraw.upperBound == string.length || lineNumber == 1),
            layoutManager.extraLineFragmentTextContainer != nil
        else { return }
        
        lineNumber = (lineNumber > 1) ? lineNumber : self.lineNumber(at: string.length)
        let isSelected = (selectedRanges.last?.lowerBound == string.length)
        
        body(layoutManager.extraLineFragmentRect, lineNumber, isSelected)
    }
    
    
    
    // MARK: Private Methods
    
    /// Returns the 1-based line number at the given character index.
    ///
    /// This method has a performance advantage if the receiver's layoutManager conforms LineRangeCacheable.
    ///
    /// - Parameter location: NSRange-based character index.
    /// - Returns: The number of lines (1-based).
    private func lineRange(at location: Int) -> NSRange {
        
        (self.layoutManager as? any LineRangeCacheable)?.lineRange(at: location) ?? (self.string as NSString).lineRange(at: location)
    }
}
