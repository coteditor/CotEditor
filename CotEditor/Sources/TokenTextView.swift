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
//  © 2017-2018 1024jp
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

private extension NSAttributedStringKey {
    
    static let token = NSAttributedStringKey("token")
}


final class TokenTextView: NSTextView {
    
    var tokenizer: Tokenizer?
    var tokenColor: NSColor = .selectedControlColor
    
    
    
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
            self.selectedRange.length == 0,
            self.selectedRange.location > 0,
            let effectiveRange = self.textStorage?.effectiveTokenRange(at: self.selectedRange.location - 1),
            effectiveRange.upperBound == self.selectedRange.location
            else { return super.deleteBackward(sender) }
        
        self.replace(with: "", range: effectiveRange, selectedRange: nil)
    }
    
    
    /// draw token capsule
    override func drawBackground(in rect: NSRect) {
        
        super.drawBackground(in: rect)
        
        guard let textStorage = self.textStorage else { return }
        
        let fillColor = self.tokenColor.withAlphaComponent(0.3)
        
        textStorage.enumerateAttribute(.token, in: textStorage.string.nsRange) { (token, range, _) in
            guard token != nil else { return }
            
            self.drawRoundedBackground(for: range, color: fillColor)
        }
    }
    
    
    /// select token by selecting word
    override func selectionRange(forProposedRange proposedCharRange: NSRange, granularity: NSSelectionGranularity) -> NSRange {
        
        guard
            granularity == .selectByWord,
            let effectiveRange = self.textStorage?.effectiveTokenRange(at: proposedCharRange.location)
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
    
    @IBAction func insertVariable(_ sender: Any?) {
        
        guard
            let menuItem = sender as? NSMenuItem,
            let title = menuItem.representedObject as? String
            else { return }
        
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
        
        textStorage.removeAttribute(.token, range: textStorage.string.nsRange)
        textStorage.removeAttribute(.foregroundColor, range: textStorage.string.nsRange)
        
        tokenizer.tokenize(textStorage.string) { (token, range, keywordRange) in
            textStorage.addAttribute(.token, value: token, range: range)
            textStorage.addAttribute(.foregroundColor, value: braketColor, range: range)
            textStorage.addAttribute(.foregroundColor, value: textColor, range: keywordRange)
        }
        
        self.needsDisplay = true
    }
    
}



private extension NSTextStorage {
    
    /// return range of a token if the location is in a token, otherwise nil.
    func effectiveTokenRange(at location: Int) -> NSRange? {
        
        var effectiveRange = NSRange.notFound
        
        guard
            self.attribute(.token, at: location, longestEffectiveRange: &effectiveRange, in: self.string.nsRange) != nil
            else { return nil }
        
        return effectiveRange
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
