//
//  WindowDraggableTextField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-11-07.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2025 1024jp
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

struct WindowDraggableTextField: NSViewRepresentable {
    
    typealias NSViewType = NSTextField
    
    @Binding private var text: String
    private var prompt: String
    
    private var onSubmit: () -> Void = {}
    
    
    init(_ prompt: String, text: Binding<String>) {
        
        self._text = text
        self.prompt = prompt
    }
    
    
    func makeNSView(context: Context) -> NSTextField {
        
        let textField = DraggableTextField(string: self.text)
        textField.usesSingleLineMode = true
        textField.placeholderString = self.prompt
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = .systemFont(ofSize: 20, weight: .light)
        
        return textField
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        
        nsView.stringValue = self.text
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
                return true
            }
            
            return false
        }
    }
}


extension WindowDraggableTextField {
    
    /// Sets an action to perform when the user submits a value to this view.
    ///
    /// - Parameter action: The action to perform on submission of a value.
    func onSubmit(_ action: @escaping () -> Void) -> Self {
        
        var view = self
        view.onSubmit = action
        return view
    }
}


// MARK: - Private Classes

private final class DraggableTextField: NSTextField {
    
    override static var cellClass: AnyClass? {
        
        get { DraggableTextFieldCell.self }
        set { _ = newValue }
    }
    
    
    override var mouseDownCanMoveWindow: Bool  {
        
        true
    }
}


private final class DraggableTextFieldCell: NSTextFieldCell {
    
    private weak var fieldEditor: NSTextView?
    
    
    override func fieldEditor(for controlView: NSView) -> NSTextView? {
        
        guard self.userInterfaceLayoutDirection != .rightToLeft else {
            return super.fieldEditor(for: controlView)
        }
        
        if self.fieldEditor == nil {
            let fieldEditor = DraggableFieldEditor()
            fieldEditor.isFieldEditor = true
            fieldEditor.placeholderString = self.placeholderString
            
            self.fieldEditor = fieldEditor
        }
        
        // update field width to follow field editor size
        controlView.layoutSubtreeIfNeeded()
        
        return self.fieldEditor
    }
}


private final class DraggableFieldEditor: NSTextView {
    
    var placeholderString: String?
    
    
    override var mouseDownCanMoveWindow: Bool {
        
        self.string.isEmpty
    }
    
    
    override func didChangeText() {
        
        super.didChangeText()
        
        self.sizeToFitTextWidth()
    }
    
    
    /// Resizes the receiver's frame width just enough to draw the current text.
    private func sizeToFitTextWidth() {
        
        // keep width to draw placeholder text
        let attributedString = if self.string.isEmpty, let placeholderString {
            NSAttributedString(string: placeholderString, attributes: self.typingAttributes)
        } else {
            self.attributedString()
        }
        
        let textWidth = attributedString.size().width
        let padding = self.textContainer?.lineFragmentPadding ?? 0
        
        self.frame.size.width = ceil(textWidth) + 2 * padding
    }
}
