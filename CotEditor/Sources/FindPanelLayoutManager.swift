//
//  FindPanelLayoutManager.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-03-04.
//
//  ---------------------------------------------------------------------------
//
//  © 2015-2022 1024jp
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
import Combine

final class FindPanelLayoutManager: NSLayoutManager, NSLayoutManagerDelegate, InvisibleDrawing {
    
    // MARK: Invisible Drawing Properties
    
    let invisiblesColor: NSColor = .disabledControlTextColor
    let textFont: NSFont = .systemFont(ofSize: 0)
    private(set) var showsInvisibles: Bool = false  { didSet { self.invalidateInvisibleDisplay() } }
    var showsControls: Bool = false
    var invisiblesDefaultsObserver: AnyCancellable?
    
    
    // MARK: Private Properties
    
    private lazy var lineHeight = self.defaultLineHeight(for: self.textFont)
    private lazy var baselineOffset = self.defaultBaselineOffset(for: self.textFont)
    private lazy var boundingBoxForControlGlyph = self.boundingBoxForControlGlyph(for: self.textFont)
    private var invisibleVisibilityObserver: AnyCancellable?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.delegate = self
        
        self.invisibleVisibilityObserver = UserDefaults.standard.publisher(for: .showInvisibles, initial: true)
            .sink { [weak self] in self?.showsInvisibles = $0 }
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    // MARK: Layout Manager Methods
    
    /// draw invisible characters
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        if self.showsInvisibles {
            self.drawInvisibles(forGlyphRange: glyphsToShow, at: origin, baselineOffset: self.baselineOffset, types: UserDefaults.standard.showsInvisible)
        }
        
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }
    
    
    
    // MARK: Layout Manager Delegate Methods
    
    /// adjust line height to be all the same
    func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>, lineFragmentUsedRect: UnsafeMutablePointer<NSRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
        
        lineFragmentRect.pointee.size.height = self.lineHeight
        lineFragmentUsedRect.pointee.size.height = self.lineHeight
        baselineOffset.pointee = self.baselineOffset
        
        return true
    }
    
    
    /// treat control characters as whitespace to draw replacement glyphs
    func layoutManager(_ layoutManager: NSLayoutManager, shouldUse action: NSLayoutManager.ControlCharacterAction, forControlCharacterAt charIndex: Int) -> NSLayoutManager.ControlCharacterAction {
        
        self.showsControlCharacter(at: charIndex, proposedAction: action) ? .whitespace : action
    }
    
    
    /// make a blank space to draw the replacement glyph in `drawGlyphs(forGlyphRange:at:)` later
    func layoutManager(_ layoutManager: NSLayoutManager, boundingBoxForControlGlyphAt glyphIndex: Int, for textContainer: NSTextContainer, proposedLineFragment proposedRect: NSRect, glyphPosition: NSPoint, characterIndex charIndex: Int) -> NSRect {
        
        self.boundingBoxForControlGlyph
    }
    
    
    
    // MARK: Invisible Drawing Methods
    
    func isInvalidInvisible(_ invisible: Invisible, at characterIndex: Int) -> Bool {
        
        false
    }
}
