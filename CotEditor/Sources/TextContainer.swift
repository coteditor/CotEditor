//
//  TextContainer.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-06-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2020 1024jp
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

final class TextContainer: NSTextContainer {
    
    // MARK: Public Properties
    
    var isHangingIndentEnabled = false  { didSet { self.invalidateLayout() } }
    var hangingIndentWidth = 0  { didSet { self.invalidateLayout() } }
    
    
    // MARK: Private Properties
    
    private var lastLineStartIndex = 0
    private var indentWidthCache: [NSAttributedString: CGFloat] = [:]
    
    
    
    // MARK: -
    // MARK: Text Container Methods
    
    override var isSimpleRectangularTextContainer: Bool {
        
        return !self.isHangingIndentEnabled
    }
    
    
    override func lineFragmentRect(forProposedRect proposedRect: NSRect, at characterIndex: Int, writingDirection baseWritingDirection: NSWritingDirection, remaining remainingRect: UnsafeMutablePointer<NSRect>?) -> NSRect {
        
        assert(self.hangingIndentWidth >= 0)
        
        var rect = super.lineFragmentRect(forProposedRect: proposedRect, at: characterIndex, writingDirection: baseWritingDirection, remaining: remainingRect)
        
        guard
            self.isHangingIndentEnabled,
            let layoutManager = self.layoutManager as? LayoutManager,
            let storage = layoutManager.textStorage
            else { return rect }
        
        let string = storage.string as NSString
        
        // no hanging indent for new line
        if characterIndex == 0 || string.character(at: characterIndex - 1).isNewline {
            self.lastLineStartIndex = characterIndex
            return rect
        }
        
        // find line start index only really needed
        if characterIndex < self.lastLineStartIndex {
            self.lastLineStartIndex = string.lineStartIndex(at: characterIndex)
        }
        
        assert(characterIndex > 10_000 || self.lastLineStartIndex == string.lineStartIndex(at: characterIndex),
               "Wrong line start index estimation at \(characterIndex).")
        
        // get base indent
        let indentRange = string.rangeOfIndent(from: self.lastLineStartIndex, limitedBy: characterIndex)
        let baseIndent: CGFloat
        if !indentRange.isEmpty {
            let attrIndent = storage.attributedSubstring(from: indentRange)
            baseIndent = self.indentWidthCache[attrIndent] ?? attrIndent.size().width
            self.indentWidthCache[attrIndent] = baseIndent
        } else {
            baseIndent = 0
        }
        
        // calculate hanging indent
        let hangingIndent = CGFloat(self.hangingIndentWidth) * layoutManager.spaceWidth
        let indent = baseIndent + hangingIndent
        
        // remove hanging indent space from rect
        rect.size.width -= indent
        rect.origin.x += (baseWritingDirection != .rightToLeft) ? indent : 0
        
        return rect
    }
    
    
    
    // MARK: Private Methods
    
    /// invalidate layout in layoutManager
    private func invalidateLayout() {
        
        guard let layoutManager = self.layoutManager else { return }
        
        layoutManager.invalidateLayout(forCharacterRange: layoutManager.attributedString().range, actualCharacterRange: nil)
    }
    
}



// MARK: -

private extension NSString {
    
    /// The fast way to find the range of indent charaters at the beginning of the given range.
    ///
    /// - Parameters:
    ///   - startIndex: The character index where start the indent search.
    ///   - limitIndex: The upper threshold to find indent.
    /// - Returns: The range of indent charaters at the beginning of the given range.
    func rangeOfIndent(from startIndex: Int, limitedBy limitIndex: Int? = nil) -> NSRange {
        
        assert(self.lineStartIndex(at: startIndex) == startIndex)
        
        let limitIndex = limitIndex ?? self.length
        
        for index in startIndex..<limitIndex {
            switch self.character(at: index) {
            case 0x0020, 0x0009:  // SPACE, HORIONTAL TAB
                continue
            default:
                return NSRange(startIndex..<index)
            }
        }
        
        return NSRange(startIndex..<startIndex)
    }
}
