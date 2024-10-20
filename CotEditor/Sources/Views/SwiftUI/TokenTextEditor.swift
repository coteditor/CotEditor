//
//  TokenTextEditor.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-02-28.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2024 1024jp
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

import SwiftUI
import AppKit

struct TokenTextEditor: NSViewRepresentable {
    
    typealias NSViewType = NSScrollView
    
    
    @Binding var text: String?
    var tokenizer: Tokenizer
    
    @Environment(\.isEnabled) private var isEnabled
    
    
    func makeNSView(context: Context) -> NSScrollView {
        
        let textView = TokenTextView(usingTextLayoutManager: false)
        textView.allowsUndo = true
        textView.autoresizingMask = [.width, .height]
        textView.textContainerInset = CGSize(width: 4, height: 6)
        textView.isRichText = false
        textView.font = .systemFont(ofSize: 0)
        textView.delegate = context.coordinator
        textView.tokenizer = self.tokenizer
        
        let nsView = NSScrollView()
        nsView.documentView = textView
        
        return nsView
    }
    
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        
        guard let textView = nsView.documentView as? TokenTextView else { return assertionFailure() }
        
        if textView.string != self.text {
            textView.string = self.text ?? ""
        }
        textView.isEditable = self.isEnabled
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(text: $text)
    }
    
    
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        
        @Binding private var text: String?
        
        
        init(text: Binding<String?>) {
            
            self._text = text
        }
        
        
        func textDidChange(_ notification: Notification) {
            
            guard let textView = notification.object as? NSTextView else { return assertionFailure() }
            
            self.text = textView.string
        }
    }
}


private extension NSAttributedString.Key {
    
    static let token = NSAttributedString.Key("token")
}



final class TokenTextView: NSTextView {
    
    // MARK: Public Properties
    
    var tokenizer: Tokenizer?
    
    
    
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
    
    
    /// Deletes whole token if cursor located at the end of a token.
    override func deleteBackward(_ sender: Any?) {
        
        guard
            self.selectedRange.isEmpty,
            self.selectedRange.location > 0,
            let tokenRange = self.tokenRange(at: self.selectedRange.location - 1),
            tokenRange.upperBound == self.selectedRange.location
        else { return super.deleteBackward(sender) }
        
        self.replace(with: "", range: tokenRange, selectedRange: nil)
    }
    
    
    /// Draws token capsule.
    override func drawBackground(in rect: NSRect) {
        
        super.drawBackground(in: rect)
        
        self.drawRoundedBackground(in: rect)
    }
    
    
    /// Selects token by selecting word.
    override func selectionRange(forProposedRange proposedCharRange: NSRange, granularity: NSSelectionGranularity) -> NSRange {
        
        guard
            granularity == .selectByWord,
            let tokenRange = self.tokenRange(at: proposedCharRange.location)
        else { return super.selectionRange(forProposedRange: proposedCharRange, granularity: granularity) }
        
        return tokenRange
    }
    
    
    
    // MARK: Actions
    
    /// The variable insertion menu was selected.
    @IBAction func insertVariable(_ sender: NSMenuItem) {
        
        guard let variable = sender.representedObject as? String else { return }
        
        let range = self.rangeForUserTextChange
        
        self.window?.makeFirstResponder(self)
        if self.shouldChangeText(in: range, replacementString: variable) {
            self.replaceCharacters(in: range, with: variable)
            self.didChangeText()
        }
    }
    
    
    
    // MARK: Private Method
    
    /// Returns the character range of the token if the given position is a token.
    ///
    /// - Parameter location: The character index.
    /// - Returns: The character range of the token.
    private func tokenRange(at location: Int) -> NSRange? {
        
        self.layoutManager?.effectiveRange(of: .token, at: location)
    }
    
    
    /// Finds tokens in contents and mark-up them.
    private func invalidateTokens() {
        
        guard
            let tokenizer = self.tokenizer,
            let layoutManager = self.layoutManager
        else { return }
        
        let wholeRange = self.string.nsRange
        layoutManager.removeTemporaryAttribute(.token, forCharacterRange: wholeRange)
        layoutManager.removeTemporaryAttribute(.roundedBackgroundColor, forCharacterRange: wholeRange)
        layoutManager.removeTemporaryAttribute(.foregroundColor, forCharacterRange: wholeRange)
        
        tokenizer.tokenize(self.string) { (_, range, keywordRange) in
            layoutManager.addTemporaryAttribute(.token, value: UUID(), forCharacterRange: range)
            layoutManager.addTemporaryAttribute(.roundedBackgroundColor, value: NSColor.tokenBackgroundColor, forCharacterRange: range)
            layoutManager.addTemporaryAttribute(.foregroundColor, value: NSColor.tokenBracketColor, forCharacterRange: range)
            layoutManager.addTemporaryAttribute(.foregroundColor, value: NSColor.tokenTextColor, forCharacterRange: keywordRange)
        }
    }
}



private extension NSColor {
    
    static let tokenTextColor = NSColor(name: nil) { appearance in
        NSColor.selectedControlColor.blended(withFraction: 0.7, of: appearance.isDark ? .white : .black)!
    }
    
    static let tokenBracketColor = NSColor(name: nil) { appearance in
        NSColor.selectedControlColor.blended(withFraction: 0.3, of: appearance.isDark ? .white : .black)!
    }
    
    static let tokenBackgroundColor = NSColor(name: nil) { appearance in
        NSColor.selectedControlColor.withAlphaComponent(appearance.isDark ? 0.5 : 0.3)
    }
}



// MARK: - Preview

#Preview {
    @Previewable @State var text: String? = "abc<<<CURSOR>>><<<CURSOR>>>defg\n<<<SELECTION>>>"
    
    return TokenTextEditor(text: $text, tokenizer: Snippet.Variable.tokenizer)
}
