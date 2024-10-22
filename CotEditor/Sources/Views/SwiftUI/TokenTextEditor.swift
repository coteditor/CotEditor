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
        
        let scrollView = TokenTextView.scrollablePlainDocumentContentTextView()
        let textView = scrollView.documentView as! TokenTextView
        textView.allowsUndo = true
        textView.textContainerInset = CGSize(width: 4, height: 6)
        textView.font = .systemFont(ofSize: 0)
        textView.delegate = context.coordinator
        textView.textLayoutManager?.delegate = context.coordinator
        textView.tokenizer = self.tokenizer
        
        return scrollView
    }
    
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        
        guard let textView = nsView.documentView as? NSTextView else { return assertionFailure() }
        
        textView.isEditable = self.isEnabled
        
        guard textView.string != self.text else { return }
        
        textView.string = self.text ?? ""
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(text: $text)
    }
    
    
    
    final class Coordinator: NSObject, NSTextViewDelegate, NSTextLayoutManagerDelegate {
        
        @Binding private var text: String?
        
        
        init(text: Binding<String?>) {
            
            self._text = text
        }
        
        
        func textDidChange(_ notification: Notification) {
            
            guard let textView = notification.object as? NSTextView else { return assertionFailure() }
            
            self.text = textView.string
        }
        
        
        func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: any NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
            
           TokenLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }
    }
}


private extension NSAttributedString.Key {
    
    static let token = NSAttributedString.Key("token")
    static let tokenKeyword = NSAttributedString.Key("tokenKeyword")
}


private final class TokenLayoutFragment: NSTextLayoutFragment {
    
    override func draw(at point: CGPoint, in context: CGContext) {
        
        // draw capsules
        context.saveGState()
        
        for lineFragment in self.textLineFragments {
            lineFragment.attributedString.enumerateAttribute(.token, type: UUID.self, in: lineFragment.characterRange) { (_, range, _) in
                let lineBounds = lineFragment.typographicBounds
                let lowerBound = lineFragment.locationForCharacter(at: range.lowerBound).x
                let upperBound = lineFragment.locationForCharacter(at: range.upperBound).x
                
                let frameRect = NSRect(x: lowerBound, y: lineBounds.minY,
                                       width: upperBound - lowerBound, height: lineBounds.height)
                let radius = frameRect.height / 3
                
                context.addPath(CGPath(roundedRect: frameRect, cornerWidth: radius, cornerHeight: radius, transform: nil))
            }
        }
        
        if !context.isPathEmpty {
            context.setFillColor(NSColor.tokenBackgroundColor.cgColor)
            context.fillPath()
        }
        context.restoreGState()
        
        // draw text
        super.draw(at: point, in: context)
    }
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
        
        var range = NSRange.notFound
        guard self.textStorage?.attribute(.token, at: location, longestEffectiveRange: &range, in: self.string.nsRange) != nil else { return nil }
        
        return range
    }
    
    
    /// Finds tokens in contents and mark-up them.
    private func invalidateTokens() {
        
        guard let tokenizer, let textStorage else { return }
        
        textStorage.beginEditing()
        
        textStorage.removeAttribute(.token, range: textStorage.range)
        textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: textStorage.range)
        
        tokenizer.tokenize(self.string) { (_, range, keywordRange) in
            textStorage.addAttribute(.token, value: UUID(), range: range)
            textStorage.addAttribute(.foregroundColor, value: NSColor.tokenBracketColor, range: range)
            textStorage.addAttribute(.foregroundColor, value: NSColor.tokenTextColor, range: keywordRange)
        }
        
        textStorage.endEditing()
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
    @Previewable @State var text: String? = "abc<<<CURSOR>>><<<CURSOR>>>defg\n<<<SELECTION>>>abc"
    
    return TokenTextEditor(text: $text, tokenizer: Snippet.Variable.tokenizer)
}
