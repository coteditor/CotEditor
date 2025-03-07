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
//  © 2023-2025 1024jp
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
import RegexHighlighting

struct RegexTextField: NSViewRepresentable {
    
    typealias NSViewType = NSTextField
    
    enum Style {
        
        case automatic
        case table
    }
    
    @Binding private var text: String
    private var isHighlighted: Bool = true
    private var mode: RegexParseMode
    private var showsError: Bool
    
    private var prompt: String?
    private var onSubmit: () -> Void
    
    private var leadingInset: Double = 0
    private var style: Style = .automatic
    
    
    init(text: Binding<String>, mode: RegexParseMode = .search, showsError: Bool = false, prompt: String? = nil, onSubmit: @escaping () -> Void = {}) {
        
        self._text = text
        self.prompt = prompt
        self.onSubmit = onSubmit
        
        self.mode = mode
        self.showsError = showsError
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
    
    
    /// Sets the field style.
    ///
    /// - Parameters:
    ///   - style: The field style.
    func style(_ style: Style) -> Self {
        
        var view = self
        view.style = style
        
        return view
    }
    
    
    /// Adds a condition that controls whether enabled syntax highlighting.
    ///
    /// - Parameter highlighted: A Boolean value that determines whether enabled syntax highlighting.
    /// - Returns: A view that controls whether enabled syntax highlighting.
    func regexHighlighted(_ highlighted: Bool) -> Self {
        
        var view = self
        view.isHighlighted = highlighted
        return view
    }
    
    
    func makeNSView(context: Context) -> NSTextField {
        
        let textField = RegexNSTextField(string: self.text, mode: self.mode, showsError: self.showsError)
        textField.delegate = context.coordinator
        textField.placeholderString = self.prompt
        textField.isEditable = true
        textField.lineBreakMode = .byTruncatingTail
        (textField.cell as? PaddingTextFieldCell)?.leadingPadding = self.leadingInset
        switch self.style {
            case .automatic:
                break
            case .table:
                textField.isBordered = false
                textField.drawsBackground = false
        }
        
        return textField
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        
        nsView.stringValue = self.text
        (nsView as! RegexNSTextField).isRegexHighlighted = self.isHighlighted
        
        context.coordinator.updateBinding(text: $text)
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
        
        
        /// Updates the text binding.
        ///
        /// - Parameter text: The new binding.
        func updateBinding(text: Binding<String>) {
            
            self._text = text
        }
    }
}


private final class RegexNSTextField: NSTextField {
    
    // MARK: Public Properties
    
    var isRegexHighlighted = true {
        
        didSet {
            self.regexFormatter.parsesRegularExpression = isRegexHighlighted
            self.invalidateFieldEditor()
            self.needsDisplay = true
        }
    }
    
    
    // MARK: Private Properties
    
    private let regexFormatter: RegexFormatter<NSColor>
    
    
    // MARK: Text Field Methods
    
    init(string: String = "", mode: RegexParseMode, showsError: Bool) {
        
        let formatter = RegexFormatter(theme: .default, showsError: showsError)
        formatter.mode = mode
        self.regexFormatter = formatter
        
        super.init(frame: .zero)
        
        self.formatter = formatter
        self.stringValue = string
    }
    
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override static var cellClass: AnyClass? {
        
        get { PaddingTextFieldCell.self }
        set { _ = newValue }
    }
    
    
    /// Invoked when the receiver was focused to edit the contents.
    override func becomeFirstResponder() -> Bool {
        
        guard super.becomeFirstResponder() else { return false }
        
        self.invalidateFieldEditor()
        
        return true
    }
    
    
    /// Invoked when the text (in the field editor) was just changed.
    override func textDidChange(_ notification: Notification) {
        
        super.textDidChange(notification)
        
        self.invalidateFieldEditor()
    }
    
    
    /// Invoked when the string value was directly changed.
    override var objectValue: Any? {
        
        didSet {
            self.invalidateFieldEditor()
        }
    }
    
    
    // MARK: Private Methods
    
    /// Updates the syntax highlight in the field editor.
    private func invalidateFieldEditor() {
        
        guard let editor = self.currentEditor() as? NSTextView else { return }
        
        editor.highlightAsRegularExpressionPattern(mode: self.regexFormatter.mode, theme: self.regexFormatter.theme, enabled: self.isRegexHighlighted)
    }
}


// MARK: - Preview

#Preview {
    RegexTextField(text: .constant("[^abc]def"), prompt: "Pattern")
        .leadingInset(20)
}

#Preview("Error") {
    RegexTextField(text: .constant("[]def"), showsError: true)
}
