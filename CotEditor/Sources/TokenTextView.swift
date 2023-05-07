//
//  TokenTextView.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2023 1024jp
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

private extension NSAttributedString.Key {
    
    static let token = NSAttributedString.Key("token")
}



final class TokenTextView: NSTextView {
    
    // MARK: Public Properties
    
    var tokenizer: Tokenizer?
    
    
    
    // MARK: -
    // MARK: Text View Methods
    
    override var string: String {
        
        didSet {
            self.invalidateTokens()
        }
    }
    
    
    override func didChangeText() {
        
        super.didChangeText()
        
        self.invalidateTokens()
    }
    
    
    /// delete whole token if cursor located at the end of a token
    override func deleteBackward(_ sender: Any?) {
        
        guard
            self.selectedRange.isEmpty,
            self.selectedRange.location > 0,
            let effectiveRange = self.layoutManager?.effectiveRange(of: .token, at: self.selectedRange.location - 1),
            effectiveRange.upperBound == self.selectedRange.location
        else { return super.deleteBackward(sender) }
        
        self.replace(with: "", range: effectiveRange, selectedRange: nil)
    }
    
    
    /// draw token capsule
    override func drawBackground(in rect: NSRect) {
        
        super.drawBackground(in: rect)
        
        self.drawRoundedBackground(in: rect)
    }
    
    
    /// select token by selecting word
    override func selectionRange(forProposedRange proposedCharRange: NSRange, granularity: NSSelectionGranularity) -> NSRange {
        
        guard
            granularity == .selectByWord,
            let effectiveRange = self.layoutManager?.effectiveRange(of: .token, at: proposedCharRange.location)
        else { return super.selectionRange(forProposedRange: proposedCharRange, granularity: granularity) }
        
        return effectiveRange
    }
    
    
    /// validate insertion menu
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        
        switch item.action {
            case #selector(insertVariable):
                return self.isEditable
            default:
                break
        }
        
        return super.validateUserInterfaceItem(item)
    }
    
    
    
    // MARK: Actions
    
    /// variable insertion menu was selected
    @IBAction func insertVariable(_ sender: NSMenuItem) {
        
        guard let title = sender.representedObject as? String else { return }
        
        let range = self.rangeForUserTextChange
        
        self.window?.makeFirstResponder(self)
        if self.shouldChangeText(in: range, replacementString: title) {
            self.replaceCharacters(in: range, with: title)
            self.didChangeText()
        }
    }
    
    
    
    // MARK: Private Method
    
    /// find tokens in contents and mark-up them
    private func invalidateTokens() {
        
        guard
            let tokenizer = self.tokenizer,
            let layoutManager = self.layoutManager
        else { return }
        
        let wholeRange = self.string.nsRange
        layoutManager.removeTemporaryAttribute(.token, forCharacterRange: wholeRange)
        layoutManager.removeTemporaryAttribute(.roundedBackgroundColor, forCharacterRange: wholeRange)
        if let textColor = self.textColor {
            layoutManager.addTemporaryAttribute(.foregroundColor, value: textColor, forCharacterRange: wholeRange)
        } else {
            layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: wholeRange)
        }
        
        tokenizer.tokenize(self.string) { (token, range, keywordRange) in
            layoutManager.addTemporaryAttribute(.token, value: token, forCharacterRange: range)
            layoutManager.addTemporaryAttribute(.roundedBackgroundColor, value: NSColor.tokenBackgroundColor, forCharacterRange: range)
            layoutManager.addTemporaryAttribute(.foregroundColor, value: NSColor.tokenBracketColor, forCharacterRange: range)
            layoutManager.addTemporaryAttribute(.foregroundColor, value: NSColor.tokenTextColor, forCharacterRange: keywordRange)
        }
    }
}



extension TokenRepresentable {
    
    /// Return a menu item to insert variable to TokenTextView.
    ///
    /// - Parameter target: The action target.
    /// - Returns: A menu item.
    func insertionMenuItem(target: TokenTextView? = nil) -> NSMenuItem {
        
        let font = NSFont.menuFont(ofSize: NSFont.systemFontSize(for: .small))
        
        let token = NSAttributedString(string: self.token, attributes: [.font: font])
        let description = NSAttributedString(string: self.localizedDescription,
                                             attributes: [.font: font,
                                                          .foregroundColor: NSColor.secondaryLabelColor])
        
        let item = NSMenuItem()
        item.target = target
        item.action = #selector(TokenTextView.insertVariable)
        item.attributedTitle = [token, description].joined(separator: "\n")
        item.representedObject = self.token
        
        return item
    }
}



private extension NSColor {
    
    static let tokenTextColor = NSColor(name: nil) { (appearance) in
        NSColor.selectedControlColor.blended(withFraction: 0.7, of: appearance.isDark ? .white : .black)!
    }
    
    static let tokenBracketColor = NSColor(name: nil) { (appearance) in
        NSColor.selectedControlColor.blended(withFraction: 0.3, of: appearance.isDark ? .white : .black)!
    }
    
    static let tokenBackgroundColor = NSColor(name: nil) { (appearance) in
        NSColor.selectedControlColor.withAlphaComponent(appearance.isDark ? 0.5 : 0.3)
    }
}
