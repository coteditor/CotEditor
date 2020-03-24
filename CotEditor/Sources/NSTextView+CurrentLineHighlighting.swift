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

import AppKit

protocol CurrentLineHighlighting: NSTextView {
    
    var needsUpdateLineHighlight: Bool { get set }
    var lineHighLightRects: [NSRect] { get set }
    var lineHighLightColor: NSColor? { get }
}



extension CurrentLineHighlighting {
    
    // MARK: Public Methods
    
    /// draw current line highlight
    func drawCurrentLine(in dirtyRect: NSRect) {
        
        if self.needsUpdateLineHighlight {
            self.lineHighLightRects = self.calcurateLineHighLightRects()
            self.needsUpdateLineHighlight = false
        }
        
        guard let color = self.lineHighLightColor else { return }
        
        NSGraphicsContext.saveGraphicsState()
        
        color.setFill()
        for rect in self.lineHighLightRects where rect.intersects(dirtyRect) {
            self.centerScanRect(rect).fill()
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    
    // MARK: Private Methods
    
    /// Calculate highlight rects for all insertion points.
    ///
    /// - Returns: Rects for current line highlight.
    private func calcurateLineHighLightRects() -> [NSRect] {
        
        return self.rangesForUserTextChange?
            .map(\.rangeValue)
            .map { (self.string as NSString).lineContentsRange(for: $0) }
            .unique
            .map { self.lineRect(for: $0) }
            ?? []
    }
    
    
    /// Return rect for the line that contains the given range.
    ///
    /// - Parameter range: The range to obtain line rect.
    /// - Returns: Line rect in view coordinate.
    private func lineRect(for range: NSRange) -> NSRect {
        
        guard
            let textContainer = self.textContainer,
            let layoutManager = self.layoutManager
            else { assertionFailure(); return .zero }
        
        let rect = layoutManager.lineFragmentsRect(for: range)
        
        return NSRect(x: 0,
                      y: rect.minY,
                      width: textContainer.size.width,
                      height: rect.height)
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
        let lowerRect = self.lineFragmentRect(forGlyphAt: safeLowerIndex, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
        
        guard !effectiveRange.contains(glyphRange.upperBound) else { return lowerRect }
        
        let upperRect = self.lineFragmentRect(forGlyphAt: glyphRange.upperBound - 1, effectiveRange: nil, withoutAdditionalLayout: true)
        
        return lowerRect.union(upperRect)
    }
    
}
