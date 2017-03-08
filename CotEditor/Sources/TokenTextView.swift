/*
 
 TokenTextView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-28.
 
 ------------------------------------------------------------------------------
 
 © 2017 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import AppKit

private let tokenAttributeName = "tokenAttributeName"


final class TokenTextView: NSTextView {
    
    var tokenizer: Tokenizer?
    var tokenColor: NSColor = .selectedControlColor
    
    
    
    // MARK: Text View Methods
    
    override var string: String? {
        
        didSet {
            self.invalidateTokens()
        }
    }
    
    
    override func didChangeText() {
        
        super.didChangeText()
        
        self.invalidateTokens()
    }
    
    
    /// draw token capsule
    override func drawBackground(in rect: NSRect) {
        
        super.drawBackground(in: rect)
        
        guard
            let textStorage = self.textStorage,
            let layoutManager = self.layoutManager,
            let textContainer = self.textContainer
            else { return }
        
        NSGraphicsContext.saveGraphicsState()
        
        self.tokenColor.setStroke()
        self.tokenColor.withAlphaComponent(0.3).setFill()
        
        let containerOrigin = self.textContainerOrigin
        let radius = (self.font?.pointSize ?? NSFont.systemFontSize()) / 3
        
        textStorage.enumerateAttribute(tokenAttributeName, in: textStorage.string.nsRange, options: []) { (token, range, _) in
            
            guard token != nil else { return }
            
            let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            
            var glyphLocation = glyphRange.location
            while glyphRange.contains(location: glyphLocation) {
                var effectiveRange = NSRange.notFound
                layoutManager.lineFragmentRect(forGlyphAt: glyphLocation, effectiveRange: &effectiveRange)
                
                let inlineRange = effectiveRange.intersection(glyphRange)
                let boundingRect = layoutManager.boundingRect(forGlyphRange: inlineRange, in: textContainer)
                let rect = boundingRect.offset(by: containerOrigin).insetBy(dx: 0.5, dy: 0.5)
                
                let bezier = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
                bezier.fill()
                bezier.stroke()
                
                glyphLocation = inlineRange.max
            }
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    
    /// select token by selecting word
    override func selectionRange(forProposedRange proposedCharRange: NSRange, granularity: NSSelectionGranularity) -> NSRange {
        
        var effectiveRange = NSRange.notFound
        
        guard
            granularity == .selectByWord,
            let textStorage = self.textStorage,
            textStorage.attribute(tokenAttributeName, at: proposedCharRange.location, longestEffectiveRange: &effectiveRange, in: textStorage.string.nsRange) != nil,
            effectiveRange != .notFound
            else { return super.selectionRange(forProposedRange: proposedCharRange, granularity: granularity) }
        
        return effectiveRange
    }
    
    
    
    // MARK: Actions
    
    
    /// variable insertion menu was selected
    
    @IBAction func insertVariable(_ sender: Any?) {
        
        guard let menuItem = sender as? NSMenuItem else { return }
        
        let title = menuItem.title
        let range = self.rangeForUserTextChange
        
        self.window?.makeFirstResponder(self)
        if self.shouldChangeText(in: range, replacementString: title) {
            self.replaceCharacters(in: range, with: title)
            self.didChangeText()
        }
    }
    
    
    // MARK: Private Method
    
    /// find tokens in contens and mark-up them
    private func invalidateTokens() {
        
        guard
            let tokenizer = self.tokenizer,
            let textStorage = self.textStorage
            else { return }
        
        let textColor = self.tokenColor.shadow(withLevel: 0.7)!
        let braketColor = self.tokenColor.shadow(withLevel: 0.3)!
        
        textStorage.removeAttribute(tokenAttributeName, range: textStorage.string.nsRange)
        textStorage.removeAttribute(NSForegroundColorAttributeName, range: textStorage.string.nsRange)
        
        tokenizer.tokenize(textStorage.string) { (token, range, keywordRange) in
            textStorage.addAttribute(tokenAttributeName, value: token, range: range)
            textStorage.addAttribute(NSForegroundColorAttributeName, value: braketColor, range: range)
            textStorage.addAttribute(NSForegroundColorAttributeName, value: textColor, range: keywordRange)
        }
        
        self.needsDisplay = true
    }
    
}



extension NSMenu {
    
    /// add a menu item to insert variable to TokenTextView
    func addItems<T: TokenRepresentable>(for variables: [T], target: TokenTextView?) {
        
        let fontSize = NSFont.systemFontSize(for: .small)
        let font = NSFont.menuFont(ofSize: fontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 2 * fontSize
        paragraphStyle.headIndent = 2 * fontSize
        
        for variable in variables {
            let token = NSAttributedString(string: variable.token, attributes: [NSFontAttributeName: font])
            let description = NSAttributedString(string: "\n" + variable.localizedDescription, attributes: [NSFontAttributeName: font,
                                                                                                            NSForegroundColorAttributeName: NSColor.gray,
                                                                                                            NSParagraphStyleAttributeName: paragraphStyle])
            let item = NSMenuItem()
            item.target = target
            item.action = #selector(TokenTextView.insertVariable)
            item.attributedTitle = token + description
            
            self.addItem(item)
        }
    }
    
}
