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

extension NSTextView {
    
    /// Inserts the string provided by the menu item to the insertion point.
    @IBAction func insertVariable(_ sender: NSMenuItem) {
        
        guard let string = sender.representedObject as? String else { return assertionFailure() }
        
        let range = self.rangeForUserTextChange
        
        guard self.shouldChangeText(in: range, replacementString: string) else { return }
        
        self.replaceCharacters(in: range, with: string)
        self.didChangeText()
    }
}


struct TokenTextEditor: NSViewRepresentable {
    
    typealias NSViewType = NSScrollView
    
    @Binding var text: String?
    var tokenizer: Tokenizer
    
    @Environment(\.isEnabled) private var isEnabled
    
    
    func makeNSView(context: Context) -> NSScrollView {
        
        let scrollView = NSTextView.scrollablePlainDocumentContentTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.allowsUndo = true
        textView.textContainerInset = CGSize(width: 4, height: 6)
        textView.font = .systemFont(ofSize: 0)
        textView.delegate = context.coordinator
        textView.textLayoutManager?.delegate = context.coordinator
        
        return scrollView
    }
    
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        
        guard let textView = nsView.documentView as? NSTextView else { return assertionFailure() }
        
        textView.isEditable = self.isEnabled
        
        guard textView.string != self.text else { return }
        
        textView.string = self.text ?? ""
        if let storage = textView.textContentStorage {
            self.tokenizer.invalidateTokens(in: storage)
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(tokenizer: self.tokenizer, text: $text)
    }
    
    
    
    final class Coordinator: NSObject, NSTextViewDelegate, NSTextLayoutManagerDelegate {
        
        let tokenizer: Tokenizer
        
        @Binding private var text: String?
        
        
        init(tokenizer: Tokenizer, text: Binding<String?>) {
            
            self.tokenizer = tokenizer
            self._text = text
        }
        
        
        // MARK: Text View Delegate
        
        func textDidChange(_ notification: Notification) {
            
            guard let textView = notification.object as? NSTextView else { return assertionFailure() }
            
            self.text = textView.string
            if let storage = textView.textContentStorage {
                self.tokenizer.invalidateTokens(in: storage)
            }
        }
        
        
        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            
            // select token by selecting word
            guard
                textView.selectionGranularity == .selectByWord,
                let effectiveRange = textView.textStorage?.longestEffectiveRange(of: .token, at: oldSelectedCharRange.location)
            else { return newSelectedCharRange }
            
            return effectiveRange
        }
        
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            
            switch commandSelector {
                case #selector(NSTextView.deleteBackward):
                    // delete whole token if cursor located at the end of a token
                    let selectedRange = textView.selectedRange
                    guard
                        selectedRange.isEmpty,
                        selectedRange.location > 0,
                        let effectiveRange = textView.textStorage?.longestEffectiveRange(of: .token, at: selectedRange.location - 1),
                        effectiveRange.upperBound == selectedRange.location
                    else { return false }
                    
                    textView.replace(with: "", range: effectiveRange, selectedRange: nil)
                    return true
                    
                default:
                    return false
            }
        }
        
        
        // MARK: Text Layout Manager Delegate
        
        func textLayoutManager(_ textLayoutManager: NSTextLayoutManager, textLayoutFragmentFor location: any NSTextLocation, in textElement: NSTextElement) -> NSTextLayoutFragment {
            
            TokenLayoutFragment(textElement: textElement, range: textElement.elementRange)
        }
    }
}


// MARK: Private APIs

private extension Tokenizer {
    
    /// Updates token highlights in text storage.
    func invalidateTokens(in storage: NSTextContentStorage) {
        
        guard let textStorage = storage.textStorage else { return }
        
        storage.performEditingTransaction {
            textStorage.removeAttribute(.token, range: textStorage.range)
            textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: textStorage.range)
            
            self.tokenize(textStorage.string) { (_, range, keywordRange) in
                textStorage.addAttribute(.token, value: UUID(), range: range)
                textStorage.addAttribute(.foregroundColor, value: NSColor.tokenBracketColor, range: range)
                textStorage.addAttribute(.foregroundColor, value: NSColor.tokenTextColor, range: keywordRange)
            }
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


private extension NSAttributedString {
    
    /// Returns the full range over which the value of the named attribute is the same as that at index.
    ///
    /// - Parameters:
    ///   - attrName: The name of an attribute.
    ///   - index: The index at which to test for `attributeName`.
    /// - Returns: The character range of the attribute, or `nil`if the attribute was not specified.
    func longestEffectiveRange(of attrName: NSAttributedString.Key, at index: Int) -> NSRange? {
        
        var range = NSRange.notFound
        guard self.attribute(attrName, at: index, longestEffectiveRange: &range, in: self.range) != nil else { return nil }
        
        return range
    }
}



// MARK: - Preview

#Preview {
    @Previewable @State var text: String? = "abc<<<CURSOR>>><<<CURSOR>>>defg\n<<<SELECTION>>>abc"
    
    return TokenTextEditor(text: $text, tokenizer: Snippet.Variable.tokenizer)
}
