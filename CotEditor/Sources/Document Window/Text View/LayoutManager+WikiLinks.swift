//
//  LayoutManager+WikiLinks.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by Claude Code on 2025-01-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 CotEditor Project
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
import Foundation

// MARK: - Wiki Link Rendering

extension LayoutManager {
    
    /// Colors for wiki link rendering
    private enum WikiLinkColors {
        static let validLink = NSColor.systemBlue
        static let invalidLink = NSColor.systemRed
        static let linkBrackets = NSColor.secondaryLabelColor
        static let linkBackground = NSColor.controlAccentColor.withAlphaComponent(0.1)
    }
    
    /// Draws wiki link decorations after normal glyph drawing
    /// This method should be called from the main drawGlyphs override
    /// - Parameters:
    ///   - glyphRange: The range of glyphs to draw
    ///   - origin: The drawing origin point
    func drawWikiLinkDecorationsIfNeeded(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        // Draw wiki link decorations
        drawWikiLinkDecorations(forGlyphRange: glyphsToShow, at: origin)
    }
    
    /// Draws custom decorations for wiki links
    /// - Parameters:
    ///   - glyphRange: The range of glyphs being drawn
    ///   - origin: The drawing origin point
    private func drawWikiLinkDecorations(forGlyphRange glyphRange: NSRange, at origin: NSPoint) {
        guard let textStorage = self.textStorage else { return }
        
        let characterRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        let string = textStorage.string
        
        // Find wiki links that intersect with the character range
        let wikiLinks = WikiLinkParser.findWikiLinks(in: string, range: characterRange)
        
        for wikiLink in wikiLinks {
            drawWikiLinkDecoration(for: wikiLink, at: origin)
        }
    }
    
    /// Draws decoration for a specific wiki link
    /// - Parameters:
    ///   - wikiLink: The wiki link to decorate
    ///   - origin: The drawing origin point
    private func drawWikiLinkDecoration(for wikiLink: WikiLink, at origin: NSPoint) {
        guard let textContainer = self.textContainers.first else { return }
        
        // Get the glyph range for the wiki link
        let glyphRange = self.glyphRange(forCharacterRange: wikiLink.range, actualCharacterRange: nil)
        
        // Draw background highlight
        drawWikiLinkBackground(for: wikiLink, glyphRange: glyphRange, in: textContainer, at: origin)
        
        // Draw underline for the title
        drawWikiLinkUnderline(for: wikiLink, glyphRange: glyphRange, in: textContainer, at: origin)
        
        // Draw bracket styling
        drawWikiLinkBrackets(for: wikiLink, glyphRange: glyphRange, in: textContainer, at: origin)
    }
    
    /// Draws background highlight for wiki links
    private func drawWikiLinkBackground(for wikiLink: WikiLink, glyphRange: NSRange, in textContainer: NSTextContainer, at origin: NSPoint) {
        let linkRect = self.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let backgroundRect = linkRect.offsetBy(dx: origin.x, dy: origin.y)
        
        WikiLinkColors.linkBackground.setFill()
        backgroundRect.fill()
    }
    
    /// Draws underline for wiki link titles
    private func drawWikiLinkUnderline(for wikiLink: WikiLink, glyphRange: NSRange, in textContainer: NSTextContainer, at origin: NSPoint) {
        // Get glyph range for just the title (excluding brackets)
        let titleGlyphRange = self.glyphRange(forCharacterRange: wikiLink.titleRange, actualCharacterRange: nil)
        
        let titleRect = self.boundingRect(forGlyphRange: titleGlyphRange, in: textContainer)
        let underlineRect = NSRect(
            x: titleRect.minX + origin.x,
            y: titleRect.minY + origin.y - 2,
            width: titleRect.width,
            height: 1
        )
        
        // Use different colors for valid vs invalid links
        let underlineColor = wikiLink.isValid ? WikiLinkColors.validLink : WikiLinkColors.invalidLink
        underlineColor.setFill()
        underlineRect.fill()
    }
    
    /// Draws special styling for wiki link brackets
    private func drawWikiLinkBrackets(for wikiLink: WikiLink, glyphRange: NSRange, in textContainer: NSTextContainer, at origin: NSPoint) {
        // This could be enhanced to dim the brackets or style them differently
        // For now, we'll rely on the color attributes set in the text storage
        
        // Calculate bracket positions
        let openBracketRange = NSRange(location: wikiLink.range.location, length: 2) // [[
        let closeBracketRange = NSRange(location: wikiLink.range.upperBound - 2, length: 2) // ]]
        
        // Set temporary attributes for brackets to make them less prominent
        self.setTemporaryAttributes(
            [.foregroundColor: WikiLinkColors.linkBrackets],
            forCharacterRange: openBracketRange
        )
        self.setTemporaryAttributes(
            [.foregroundColor: WikiLinkColors.linkBrackets],
            forCharacterRange: closeBracketRange
        )
    }
    
    // MARK: - Mouse Tracking for Wiki Links
    
    /// Tracks mouse movement over wiki links for hover effects
    /// - Parameters:
    ///   - point: The mouse location in the text view
    ///   - textView: The text view containing the links
    /// - Returns: The wiki link under the mouse, if any
    func wikiLinkUnderMouse(at point: NSPoint, in textView: NSTextView) -> WikiLink? {
        let characterIndex = textView.characterIndexForInsertion(at: point)
        guard characterIndex < textView.string.count else { return nil }
        
        return WikiLinkParser.wikiLink(at: characterIndex, in: textView.string)
    }
    
    /// Updates cursor style when hovering over wiki links
    /// - Parameters:
    ///   - point: The mouse location
    ///   - textView: The text view
    @MainActor func updateCursorForWikiLink(at point: NSPoint, in textView: NSTextView) {
        if wikiLinkUnderMouse(at: point, in: textView) != nil {
            NSCursor.pointingHand.set()
        } else {
            NSCursor.iBeam.set()
        }
    }
}

// MARK: - Theme Integration

extension LayoutManager {
    
    /// Updates wiki link colors based on the current theme
    /// - Parameter theme: The current editor theme
    func updateWikiLinkColors(for theme: Theme?) {
        // This would integrate with CotEditor's theme system
        // For now, we use system colors that adapt to light/dark mode
        
        guard let textStorage = self.textStorage else { return }
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        
        // Update all existing wiki link colors
        textStorage.enumerateAttribute(.wikiLink, in: fullRange) { (value, range, _) in
            if let wikiLink = value as? WikiLink {
                // Update colors based on theme and link validity
                let titleColor = wikiLink.isValid ? 
                    (theme?.text.color ?? WikiLinkColors.validLink) :
                    WikiLinkColors.invalidLink
                
                textStorage.addAttribute(.foregroundColor, value: titleColor, range: wikiLink.titleRange)
            }
        }
    }
}

// MARK: - NSTextView Integration

extension NSTextView {
    
    /// Override mouse tracking to handle wiki link interactions
    open override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        if let layoutManager = self.layoutManager as? LayoutManager {
            let point = self.convert(event.locationInWindow, from: nil)
            Task { @MainActor in
                layoutManager.updateCursorForWikiLink(at: point, in: self)
            }
        }
    }
    
    /// Override mouse down to handle wiki link clicks
    open override func mouseDown(with event: NSEvent) {
        // Check if this is a wiki link click before processing normally
        if let editorTextView = self as? EditorTextView,
           editorTextView.handleWikiLinkClick(with: event) {
            return // Wiki link click was handled
        }
        
        super.mouseDown(with: event)
    }
}