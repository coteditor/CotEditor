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

import Combine
import Cocoa

final class TextContainer: NSTextContainer {
    
    // MARK: Public Properties
    
    var isHangingIndentEnabled = false  { didSet { self.invalidateLayout() } }
    var hangingIndentWidth = 0  { didSet { self.invalidateLayout() } }
    
    
    // MARK: Private Properties
    
    private var indentWidthCache: [String: CGFloat] = [:]
    private var indentAttributes: [NSAttributedString.Key: Any] = [:]
    private var typingAttributesObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Text Container Methods
    
    override weak var textView: NSTextView? {
        
        didSet {
            self.typingAttributesObserver = textView?.publisher(for: \.typingAttributes, options: .initial)
                .sink { [weak self] (typingAttributes) in
                    // -> The font can differ from the specified text font while typing marked text.
                    guard self?.textView?.hasMarkedText() != true else { return }
                    
                    self?.indentAttributes = typingAttributes
                    self?.indentWidthCache.removeAll()
                }
        }
    }
    
    
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
        //    (2020-03 macOS 10.15)
        return true
    }
    
    
    override func lineFragmentRect(forProposedRect proposedRect: NSRect, at characterIndex: Int, writingDirection baseWritingDirection: NSWritingDirection, remaining remainingRect: UnsafeMutablePointer<NSRect>?) -> NSRect {
        
        assert(self.hangingIndentWidth >= 0)
        
        var rect = super.lineFragmentRect(forProposedRect: proposedRect, at: characterIndex, writingDirection: baseWritingDirection, remaining: remainingRect)
        
        guard
            self.isHangingIndentEnabled,
            let layoutManager = self.layoutManager as? LayoutManager
            else { return rect }
        
        let lineStartIndex = layoutManager.lineStartIndex(at: characterIndex)
        
        // no hanging indent for new line
        guard characterIndex != lineStartIndex else { return rect }
        
        // get base indent
        let string = layoutManager.string
        let indentString = string.indentString(in: lineStartIndex..<characterIndex)
        let baseIndent: CGFloat
        if indentString.isEmpty {
            baseIndent = 0
        } else if let cache = self.indentWidthCache[indentString] {
            baseIndent = cache
        } else {
            baseIndent = (indentString as NSString).size(withAttributes: self.indentAttributes).width
            self.indentWidthCache[indentString] = baseIndent
        }
        
        // calculate hanging indent
        let hangingIndent = CGFloat(self.hangingIndentWidth) * layoutManager.spaceWidth
        let indent = baseIndent + hangingIndent
        
        // intentionally give up overflown hanging indent
        guard indent + 2 * layoutManager.spaceWidth < rect.width else { return rect }
        
        // remove hanging indent space from rect
        rect.size.width -= indent
        rect.origin.x += (baseWritingDirection != .rightToLeft) ? indent : 0
        
        return rect
    }
    
    
    
    // MARK: Private Methods
    
    /// Let layoutManager invalidate the entire layout.
    private func invalidateLayout() {
        
        guard let layoutManager = self.layoutManager else { return }
        
        layoutManager.invalidateLayout(forCharacterRange: layoutManager.attributedString().range, actualCharacterRange: nil)
    }
    
}



// MARK: -

private extension NSString {
    
    /// The fast way to find the indent characters at the beginning of the given range.
    ///
    /// - Parameters:
    ///   - range: The UTF16-based character range where searching for the indent.
    /// - Returns: The indent part of the string at the beginning of the given range.
    func indentString(in range: Range<Int>) -> String {
        
        let characters: [unichar] = range.lazy
            .map { self.character(at: $0) }
            .prefix { $0 == 0x0020 || $0 == 0x0009 }  // SPACE || HORIZONTAL TAB
        
        return String(utf16CodeUnits: characters, count: characters.count)
    }
    
}
