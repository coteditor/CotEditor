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
//  © 2019-2026 1024jp
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
import StringUtils

final class TextContainer: NSTextContainer {
    
    // MARK: Public Properties
    
    var spaceWidth: Double = 0  { didSet { self.invalidateLayout() } }
    var tabWidth = 4  { didSet { self.invalidateLayout() } }
    var isHangingIndentEnabled = false  { didSet { self.invalidateLayout() } }
    var hangingIndentWidth = 0  { didSet { self.invalidateLayout() } }
    
    
    // MARK: Text Container Methods
    
    override var isSimpleRectangularTextContainer: Bool {
        
        // -> According to the reference, this property should return `false` when `.isHangingIndentEnabled`
        //    is `true` because of non-uniform line fragment width.
        //    Yet, only returning `true` enables the non-contiguous layout, and practically, in fact,
        //    TextKit handles the hanging indent properly even when this flag is true.
        //    It is therefore significantly advantageous for performance, such as when pasting large text.
        //    This flag may be really critical if the layout cannot be determined without laying all glyphs out
        //    from the top until the index where to draw.
        //    However, by the hanging indent, line fragments can be calculated only from the logical line
        //    where they belong to and thus are not affected by the previous context.
        //    (2020-03, macOS 10.15)
        return true
    }
    
    
    override func lineFragmentRect(forProposedRect proposedRect: NSRect, at characterIndex: Int, writingDirection baseWritingDirection: NSWritingDirection, remaining remainingRect: UnsafeMutablePointer<NSRect>?) -> NSRect {
        
        assert(self.hangingIndentWidth >= 0)
        
        var rect = super.lineFragmentRect(forProposedRect: proposedRect, at: characterIndex, writingDirection: baseWritingDirection, remaining: remainingRect)
        
        guard
            self.isHangingIndentEnabled,
            self.tabWidth > 0,
            characterIndex > 0,
            let layoutManager = self.layoutManager as? LayoutManager
        else { return rect }
        
        let string = layoutManager.attributedString().string as NSString
        
        // no hanging indent for new line
        switch string.character(at: characterIndex - 1) {
            case 0xA, 0xD, 0x85, 0x2028, 0x2029:  // newlines
                return rect
            default:
                break
        }
        
        // count base indent in columns
        // -> Calculate the width from the columns instead of measuring the indent string,
        //    since the indent consists only of spaces and tabs.
        //    This holds even with proportional fonts as long as the tab interval is a multiple of the space width.
        //    Count columns as integers to avoid floating-point errors around tab stops.
        let lineStartIndex = layoutManager.lineEndingScanner.lineStartIndex(at: characterIndex)
        var indentColumns = 0
        for index in lineStartIndex..<characterIndex {
            let character = string.character(at: index)
            
            guard character == 0x0020 || character == 0x0009 else { break }  // SPACE || HORIZONTAL TAB
            
            indentColumns += (character == 0x0009) ? self.tabWidth - (indentColumns % self.tabWidth) : 1
            
            // stop scanning an extremely long indent that will be given up anyway
            guard Double(indentColumns + self.hangingIndentWidth + 2) * self.spaceWidth < rect.width else { break }
        }
        
        let indent = Double(indentColumns + self.hangingIndentWidth) * self.spaceWidth
        
        // intentionally give up overflown hanging indent
        guard indent + 2 * self.spaceWidth < rect.width else { return rect }
        
        // remove hanging indent space from rect
        rect.size.width -= indent
        rect.origin.x += (baseWritingDirection != .rightToLeft) ? indent : 0
        
        return rect
    }
    
    
    // MARK: Private Methods
    
    /// Lets layoutManager invalidate the entire layout.
    private func invalidateLayout() {
        
        guard let layoutManager = self.layoutManager else { return }
        
        // avoid invalidating the empty range because it clears the extra line fragment
        guard layoutManager.attributedString().length > 0 else { return }
        
        layoutManager.invalidateLayout(forCharacterRange: layoutManager.attributedString().range, actualCharacterRange: nil)
    }
}
