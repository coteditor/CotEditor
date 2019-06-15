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
//  © 2019 1024jp
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
    
    var isHangingIndentEnabled = false { didSet { self.invalidateLayout() } }
    var hangingIndentWidth = 0 { didSet { self.invalidateLayout() } }
    
    
    
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
        let lineRange = string.lineRange(for: NSRange(characterIndex..<characterIndex))
        
        // no hanging indent for new line
        guard lineRange.location < characterIndex else { return rect }
        
        // get base indent
        let indentRange = string.range(of: "[ \t]+", options: [.regularExpression, .anchored], range: lineRange)
        let baseIndent = (indentRange == .notFound) ? 0 : storage.attributedSubstring(from: indentRange).size().width
        
        // calculate hanging indent
        let hangingIndent = CGFloat(self.hangingIndentWidth) * layoutManager.spaceWidth
        let indent = baseIndent + hangingIndent
        
        // remove hanging indent space from rect
        rect.size.width -= indent
        switch baseWritingDirection {
        case .leftToRight, .natural:
            rect.origin.x += indent
        case .rightToLeft:
            break
        @unknown default:
            assertionFailure()
        }
        
        return rect
    }
    
    
    
    // MARK: Private Methods
    
    /// invalidate layout in layoutManager
    private func invalidateLayout() {
        
        guard let layoutManager = self.layoutManager else { return }
        
        layoutManager.invalidateLayout(forCharacterRange: layoutManager.attributedString().range, actualCharacterRange: nil)
    }
    
}
