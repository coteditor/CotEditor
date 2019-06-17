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
//  © 2018-2019 1024jp
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
            rect.fill()
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    
    // MARK: Private Methods
    
    /// Calculate highlight rects for all insertion points.
    ///
    /// - Returns: Rects for current line highlight.
    private func calcurateLineHighLightRects() -> [NSRect] {
        
        return self.rangesForUserTextChange?
            .map { $0.rangeValue }
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
            let rect = self.boundingRect(for: range)
            else { assertionFailure(); return .zero }
        
        return NSRect(x: 0,
                      y: rect.minY,
                      width: textContainer.size.width,
                      height: rect.height)
            .insetBy(dx: textContainer.lineFragmentPadding, dy: 0)
            .integral
    }
    
}
