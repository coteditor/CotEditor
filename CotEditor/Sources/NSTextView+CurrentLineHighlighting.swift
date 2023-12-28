//
//  NSTextView+CurrentLineHighlighting.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-08-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2023 1024jp
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

@MainActor protocol CurrentLineHighlighting: NSTextView {
    
    var needsUpdateLineHighlight: Bool { get set }
    var lineHighlightRects: [NSRect] { get set }
    var lineHighlightColor: NSColor? { get }
}



extension CurrentLineHighlighting {
    
    // MARK: Public Methods
    
    /// Draws the highlight for the lines where the insertion points locate.
    ///
    /// - Parameter dirtyRect: The A rectangle defining the portion of the view that requires redrawing.
    func drawCurrentLine(in dirtyRect: NSRect) {
        
        // calculate rects but only when needed
        // to avoid unneeded high-cost calculation for a latter part of a large document
        if self.needsUpdateLineHighlight, let dirtyRange = self.range(for: dirtyRect) {
            let lineRanges = self.selectedLineRanges()
            
            if lineRanges.contains(where: { $0.intersects(dirtyRange) }) {
                self.lineHighlightRects = lineRanges.map(self.lineRect(for:))
                self.needsUpdateLineHighlight = false
            } else {
                // remove outdated rects anyway
                self.lineHighlightRects.removeAll()
            }
        }
        
        let fontSize = self.font?.pointSize ?? NSFont.systemFontSize
        let radius = fontSize / 4
        let paths = self.lineHighlightRects
            .filter { $0.intersects(dirtyRect) }
            .map { self.centerScanRect($0) }
            .map { NSBezierPath(roundedRect: $0, xRadius: radius, yRadius: radius) }
        
        guard
            !paths.isEmpty,
            let color = self.lineHighlightColor
        else { return }
        
        NSGraphicsContext.saveGraphicsState()
        color.setFill()
        for path in paths {
            path.fill()
        }
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    
    // MARK: Private Methods
    
    /// Returns the character ranges for the lines where the insertion points locate.
    ///
    /// - Returns: Ranges for the current line highlight.
    private func selectedLineRanges() -> [NSRange] {
        
        guard let editingRanges = self.rangesForUserTextChange else { return [] }
        
        return editingRanges
            .map(\.rangeValue)
            .map { (self.string as NSString).lineRange(for: $0) }
            .reduce(into: [NSRange]()) { (ranges, range) in
                if range.isEmpty && range.location == self.string.length {
                    ranges.append(range)
                } else if ranges.last?.touches(range) == true {
                    ranges[ranges.endIndex - 1].formUnion(range)
                } else {
                    ranges.append(range)
                }
            }
    }
    
    
    /// Returns rect for the line that contains the given range.
    ///
    /// - Parameter range: The range to obtain line rect.
    /// - Returns: Line rect in view coordinate.
    private func lineRect(for range: NSRange) -> NSRect {
        
        guard
            let textContainer = self.textContainer,
            let layoutManager = self.layoutManager
        else { assertionFailure(); return .zero }
        
        return layoutManager.lineFragmentsRect(for: range)
            .insetBy(dx: textContainer.lineFragmentPadding, dy: 0)
            .offset(by: self.textContainerOrigin)
    }
}



private extension NSLayoutManager {
    
    func lineFragmentsRect(for range: NSRange) -> NSRect {
        
        guard
            self.attributedString().length > 0,
            self.extraLineFragmentTextContainer == nil || range.lowerBound < self.attributedString().length
        else { return self.extraLineFragmentRect }
        
        let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let safeLowerIndex = self.isValidGlyphIndex(glyphRange.lowerBound) ? glyphRange.lowerBound : glyphRange.lowerBound - 1
        var effectiveRange: NSRange = .notFound
        let lowerRect = self.lineFragmentRect(forGlyphAt: safeLowerIndex, effectiveRange: &effectiveRange)
        
        guard !effectiveRange.contains(glyphRange.upperBound) else { return lowerRect }
        
        let upperRect = self.lineFragmentRect(forGlyphAt: glyphRange.upperBound - 1, effectiveRange: nil)
        
        return lowerRect.union(upperRect)
    }
}
