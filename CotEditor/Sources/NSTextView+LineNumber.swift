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
//  © 2018-2020 1024jp
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
        
        case new(_ lineNumber: Int, _ isSelected: Bool)
        case wrapped
    }
    
    
    /// The 1-based line number at the given character index.
    ///
    /// This method has a performance advantage if the receiver's layoutManager confroms LineRangeCacheable.
    ///
    /// - Parameter location: NSRange-based character index.
    /// - Returns: The number of lines (1-based).
    func lineNumber(at location: Int) -> Int {
        
        return (self.layoutManager as? LineRangeCacheable)?.lineNumber(at: location) ?? (self.string as NSString).lineNumber(at: location)
    }
    
    
    /// Enumerate line fragments in area with line numbers.
    ///
    /// - Parameters:
    ///   - rect: The bounding rectangle for which to process lines.
    ///   - includingExtraLine: If `true`, `body` enumerate also the extra line fragment if any.
    ///   - body: The closure executed for each line in the enumeration.
    ///   - line: The information of the line.
    ///   - lineRect: The line fragment rect.
    func enumerateLineFragments(in rect: NSRect, includingExtraLine: Bool = true, body: (_ line: Line, _ lineRect: NSRect) -> Void) {
        
        guard
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { return assertionFailure() }
        
        let string = self.string as NSString
        let selectedRanges = (self.rangesForUserTextChange ?? self.selectedRanges).map { $0.rangeValue }
        
        // get glyph range of which line number should be drawn
        // -> Requires additionalLayout to obtain glyphRange for markedText. (2018-12 macOS 10.14 SDK)
        let layoutRect = rect.offset(by: -self.textContainerOrigin)
        let glyphRangeToDraw = layoutManager.glyphRange(forBoundingRect: layoutRect, in: textContainer)
        
        // count up lines until the interested area
        let firstIndex = layoutManager.characterIndexForGlyph(at: glyphRangeToDraw.location)
        var lineNumber = self.lineNumber(at: firstIndex)
        
        // enumerate visible line numbers
        var glyphIndex = glyphRangeToDraw.location
        while glyphIndex < glyphRangeToDraw.upperBound {  // process logical lines
            let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let lineRange = self.lineRange(at: characterIndex)
            let lineGlyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
            let isSelected = selectedRanges.contains { $0.intersection(lineRange) != nil }
                || (lineRange.upperBound == string.length && layoutManager.extraLineFragmentRect.isEmpty)
            glyphIndex = lineGlyphRange.upperBound
            
            var wrappedLineGlyphIndex = max(lineGlyphRange.location, glyphRangeToDraw.lowerBound)
            while wrappedLineGlyphIndex < min(glyphIndex, glyphRangeToDraw.upperBound) {  // process visually wrapped lines
                var range = NSRange.notFound
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: wrappedLineGlyphIndex, effectiveRange: &range, withoutAdditionalLayout: true)
                let line: Line = (range.location == lineGlyphRange.location) ? .new(lineNumber, isSelected) : .wrapped
                
                body(line, lineRect)
                
                wrappedLineGlyphIndex = range.upperBound
            }
            lineNumber += 1
        }
        
        guard includingExtraLine else { return }
        
        let extraLineRect = layoutManager.extraLineFragmentRect
        
        guard
            !extraLineRect.isEmpty,
            (layoutRect.minY...layoutRect.maxY).overlaps(extraLineRect.minY...extraLineRect.maxY)
            else { return }
        
        let lastLineNumber = (lineNumber > 1) ? lineNumber : self.lineNumber(at: string.length)
        let isSelected = (selectedRanges.last?.location == string.length)
        
        body(.new(lastLineNumber, isSelected), extraLineRect)
    }
    
    
    
    // MARK: Private Methods
    
    /// The 1-based line number at the given character index.
    ///
    /// This method has a performance advantage if the receiver's layoutManager confroms LineRangeCacheable.
    ///
    /// - Parameter location: NSRange-based character index.
    /// - Returns: The number of lines (1-based).
    private func lineRange(at location: Int) -> NSRange {
        
        return (self.layoutManager as? LineRangeCacheable)?.lineRange(at: location) ?? (self.string as NSString).lineRange(at: location)
    }
    
}
