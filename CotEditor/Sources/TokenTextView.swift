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
//  © 2017-2020 1024jp
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
    
    var tokenizer: Tokenizer?
    var tokenColor: NSColor = .selectedControlColor
    
    
    
    // MARK: -
    // MARK: Text View Methods
    
    override func viewDidMoveToWindow() {
        
        super.viewDidMoveToWindow()
        
        guard self.window != nil else { return }
        
        NotificationCenter.default.addObserver(self, selector: #selector(invalidateTokens), name: NSColor.systemColorsDidChangeNotification, object: nil)
    }
    
    
    @available(macOS 10.14, *)
    override func viewDidChangeEffectiveAppearance() {
        
        super.viewDidChangeEffectiveAppearance()
        
        self.invalidateTokens()
    }
    
    
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
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        
        if item.action == #selector(insertVariable) {
            return self.isEditable
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
    @objc private func invalidateTokens() {
        
        guard
            let tokenizer = self.tokenizer,
            let layoutManager = self.layoutManager
            else { return }
        
        let isDark = self.effectiveAppearance.isDark
        let textColor = self.tokenColor.blended(withFraction: 0.7, of: isDark ? .white : .black)!
        let braketColor = self.tokenColor.blended(withFraction: 0.3, of: isDark ? .white : .black)!
        let backgroundColor = self.tokenColor.withAlphaComponent(0.3)
        
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
            layoutManager.addTemporaryAttribute(.roundedBackgroundColor, value: backgroundColor, forCharacterRange: range)
            layoutManager.addTemporaryAttribute(.foregroundColor, value: braketColor, forCharacterRange: range)
            layoutManager.addTemporaryAttribute(.foregroundColor, value: textColor, forCharacterRange: keywordRange)
        }
    }
    
}



extension NSMenu {
    
    /// add a menu item to insert variable to TokenTextView
    func addItems<T: TokenRepresentable>(for variables: [T], target: TokenTextView?) {
        
        let fontSize = NSFont.systemFontSize(for: .small)
        let font = NSFont.menuFont(ofSize: fontSize)
        let paragraphStyle = NSParagraphStyle.default.mutable
        paragraphStyle.firstLineHeadIndent = 2 * fontSize
        paragraphStyle.headIndent = 2 * fontSize
        
        for variable in variables {
            let token = NSAttributedString(string: variable.token, attributes: [.font: font])
            let description = NSAttributedString(string: "\n" + variable.localizedDescription, attributes: [.font: font,
                                                                                                            .foregroundColor: NSColor.gray,
                                                                                                            .paragraphStyle: paragraphStyle])
            let item = NSMenuItem()
            item.target = target
            item.action = #selector(TokenTextView.insertVariable)
            item.attributedTitle = token + description
            item.representedObject = variable.token
            
            self.addItem(item)
        }
    }
    
}
