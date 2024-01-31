//
//  RegexTextField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2023-08-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2023-2024 1024jp
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
import SwiftUI

struct RegexTextField: NSViewRepresentable {
    
    typealias NSViewType = NSTextField
    
    @Binding private var text: String
    private let prompt: LocalizedStringResource?
    private let onSubmit: () -> Void
    
    private var leadingInset: Double = 0
    
    
    init(text: Binding<String>, prompt: LocalizedStringResource? = nil, onSubmit: @escaping () -> Void = {}) {
        
        self._text = text
        self.prompt = prompt
        self.onSubmit = onSubmit
    }
    
    
    /// Sets the inset value inside the field.
    ///
    /// - Parameters:
    ///   - inset: An amount, given in points, to inset this view on the specified edges.
    func leadingInset(_ inset: CGFloat) -> Self {
        
        var view = self
        view.leadingInset = inset
        
        return view
    }
    
    
    func makeNSView(context: Context) -> NSTextField {
        
        let textField = RegularExpressionTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = self.prompt.flatMap(String.init(localized:))
        textField.isEditable = true
        textField.lineBreakMode = .byTruncatingTail
        (textField.cell as? PaddingTextFieldCell)?.leadingPadding = self.leadingInset
        
        return textField
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        
        nsView.stringValue = self.text
        nsView.delegate = context.coordinator
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(text: $text, onSubmit: self.onSubmit)
    }
    
    
    
    final class Coordinator: NSObject, NSTextFieldDelegate {
        
        @Binding private var text: String
        private var onSubmit: () -> Void
        
        
        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            
            self._text = text
            self.onSubmit = onSubmit
        }
        
        
        func controlTextDidChange(_ obj: Notification) {
            
            guard let textField = obj.object as? NSTextField else { return }
            
            self.text = textField.stringValue
        }
        
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            
            if commandSelector == #selector(NSTextView.insertNewline) {
                self.onSubmit()
            }
            
            return false
        }
    }
}



// MARK: - Preview

#Preview {
    @State var text = "[^abc]def"
    
    return RegexTextField(text: $text)
        .leadingInset(20)
}
