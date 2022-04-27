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
//  © 2018-2022 1024jp
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
    
    enum Line {
        
        case new(_ isSelected: Bool)
        case wrapped
    }
    
    
    struct LineEnumerationOptions: OptionSet {
        
        let rawValue: Int
        
        static let bySkippingWrappedLine = Self(rawValue: 1 << 0)
        static let bySkippingExtraLine = Self(rawValue: 1 << 1)
    }
    
    
    
    /// The 1-based line number at the given character index.
    ///
    /// This method has a performance advantage if the receiver's layoutManager confroms LineRangeCacheable.
    ///
    /// - Parameter location: NSRange-based character index.
    /// - Returns: The number of lines (1-based).
    func lineNumber(at location: Int) -> Int {
        
        return (self.layoutManager as? any LineRangeCacheable)?.lineNumber(at: location) ?? (self.string as NSString).lineNumber(at: location)
    }
    
    
    /// Enumerate line fragments in area with line numbers.
    ///
    /// - Parameters:
    ///   - rect: The bounding rectangle for which to process lines.
    ///   - range: The character range to procecc lines, or `nil` to enumerate whole in rect.
    ///   - options: The options to skip invoking `body` in some specific fragments.
    ///   - body: The closure executed for each line in the enumeration.
    ///   - lineRect: The line fragment rect.
    ///   - line: The information of the line.
    ///   - lineNumber: The number of logical line (1-based).
    func enumerateLineFragments(in rect: NSRect, for range: NSRange? = nil, options: LineEnumerationOptions = [], body: (_ lineRect: NSRect, _ line: Line, _ lineNumber: Int) -> Void) {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { return assertionFailure() }
        
        // get glyph range of which line number should be drawn
        // -> Requires additionalLayout to obtain glyphRange for markedText. (2018-12 macOS 10.14 SDK)
        guard let glyphRangeToDraw: NSRange = {
            let layoutRect = rect.offset(by: -self.textContainerOrigin)
            let rectGlyphRange = layoutManager.glyphRange(forBoundingRect: layoutRect, in: textContainer)
            
            guard let range = range else { return rectGlyphRange }
            
            return layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil).intersection(rectGlyphRange)
        }() else { return }
        
        let string = self.string as NSString
        let selectedRanges = (self.rangesForUserTextChange ?? self.selectedRanges).map(\.rangeValue)
        
        // count up lines until the interested area
        let firstIndex = layoutManager.characterIndexForGlyph(at: glyphRangeToDraw.lowerBound)
        var lineNumber = self.lineNumber(at: firstIndex)
        
        // enumerate visible line numbers
        var glyphIndex = glyphRangeToDraw.lowerBound
        while glyphIndex < glyphRangeToDraw.upperBound {  // process logical lines
            let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let lineRange = self.lineRange(at: characterIndex)
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let isSelected = selectedRanges.contains { $0.intersects(lineRange) }
                || (lineRange.upperBound == string.length &&
                    lineRange.upperBound == selectedRanges.last?.upperBound &&
                    layoutManager.extraLineFragmentRect.isEmpty)
            glyphIndex = lineGlyphRange.upperBound
            
            var wrappedLineGlyphIndex = max(lineGlyphRange.lowerBound, glyphRangeToDraw.lowerBound)
            while wrappedLineGlyphIndex < min(glyphIndex, glyphRangeToDraw.upperBound) {  // process visually wrapped lines
                var fragmentGlyphRange = NSRange.notFound
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: wrappedLineGlyphIndex, effectiveRange: &fragmentGlyphRange, withoutAdditionalLayout: true)
                let isWrapped = fragmentGlyphRange.lowerBound > lineGlyphRange.lowerBound
                
                if options.contains(.bySkippingWrappedLine), isWrapped { break }
                
                let line: Line = isWrapped ? .wrapped : .new(isSelected)
                
                body(lineRect, line, lineNumber)
                
                wrappedLineGlyphIndex = fragmentGlyphRange.upperBound
            }
            lineNumber += 1
        }
        
        guard
            !options.contains(.bySkippingExtraLine),
            (!layoutManager.isValidGlyphIndex(glyphRangeToDraw.upperBound) || lineNumber == 1),
            layoutManager.extraLineFragmentTextContainer != nil
            else { return }
        
        let lastLineNumber = (lineNumber > 1) ? lineNumber : self.lineNumber(at: string.length)
        let isSelected = (selectedRanges.last?.lowerBound == string.length)
        
        body(layoutManager.extraLineFragmentRect, .new(isSelected), lastLineNumber)
    }
    
    
    
    // MARK: Private Methods
    
    /// The 1-based line number at the given character index.
    ///
    /// This method has a performance advantage if the receiver's layoutManager confroms LineRangeCacheable.
    ///
    /// - Parameter location: NSRange-based character index.
    /// - Returns: The number of lines (1-based).
    private func lineRange(at location: Int) -> NSRange {
        
        return (self.layoutManager as? any LineRangeCacheable)?.lineRange(at: location) ?? (self.string as NSString).lineRange(at: location)
    }
    
}
