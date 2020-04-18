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
//  © 2015-2020 1024jp
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

final class FindPanelLayoutManager: NSLayoutManager, NSLayoutManagerDelegate, InvisibleDrawing {
    
    // MARK: Invisible Drawing Properties
    
    let textFont: NSFont = .systemFont(ofSize: 0)
    var showsInvisibles: Bool = false
    var showsControls: Bool = false
    lazy var replacementGlyphWidth = self.textFont.width(of: "0")
    var invisiblesDefaultsObservers: [UserDefaultsObservation] = []
    
    
    // MARK: Private Properties
    
    private var lineHeight: CGFloat = 0
    private var baselineOffset: CGFloat = 0
    private var invisibleVisibilityObserver: UserDefaultsObservation?
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    override init() {
        
        super.init()
        
        self.lineHeight = self.defaultLineHeight(for: self.textFont)
        self.baselineOffset = self.defaultBaselineOffset(for: self.textFont)
        
        self.delegate = self
        
        self.invisibleVisibilityObserver = UserDefaults.standard.observe(key: .showInvisibles, options: [.initial, .new]) { [weak self] (change) in
            self?.showsInvisibles = change.new!
            self?.invalidateInvisibleDisplay()
        }
        
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        self.invisiblesDefaultsObservers.forEach { $0.invalidate() }
        self.invisibleVisibilityObserver?.invalidate()
    }
    
    
    
    // MARK: Layout Manager Methods
    
    /// draw invisible characters
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        
        if self.showsInvisibles {
            self.drawInvisibles(forGlyphRange: glyphsToShow, at: origin, baselineOffset: self.baselineOffset, color: .disabledControlTextColor)
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
    
    
    /// treat control characers as whitespace to draw replacement glyphs
    func layoutManager(_ layoutManager: NSLayoutManager, shouldUse action: NSLayoutManager.ControlCharacterAction, forControlCharacterAt charIndex: Int) -> NSLayoutManager.ControlCharacterAction {
        
        return self.showsControlCharacter(at: charIndex, proposedAction: action) ? .whitespace : action
    }
    
    
    /// make a blank space to draw the replacement glyph in `drawGlyphs(forGlyphRange:at:)` later
    func layoutManager(_ layoutManager: NSLayoutManager, boundingBoxForControlGlyphAt glyphIndex: Int, for textContainer: NSTextContainer, proposedLineFragment proposedRect: NSRect, glyphPosition: NSPoint, characterIndex charIndex: Int) -> NSRect {
        
        return NSRect(x: 0, y: 0, width: self.replacementGlyphWidth, height: proposedRect.height)
    }
    
}
