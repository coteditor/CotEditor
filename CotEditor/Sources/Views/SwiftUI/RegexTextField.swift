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

import SwiftUI
import AppKit
import RegexHighlighting

struct RegexTextField: NSViewRepresentable {
    
    typealias NSViewType = NSTextField
    
    enum Style {
        
        case automatic
        case table
    }
    
    @Binding private var text: String
    private var mode: RegexParseMode
    private var prompt: String?
    
    private var isHighlighted: Bool = true
    private var leadingInset: Double = 0
    private var style: Style = .automatic
    
    
    init(text: Binding<String>, mode: RegexParseMode = .search, prompt: String? = nil) {
        
        self._text = text
        self.mode = mode
        self.prompt = prompt
    }
    
    
    /// Sets the regular expression parse mode.
    ///
    /// - Parameter mode: The mode how to parse the value as a regular expression pattern.
    func regexParseMode(_ mode: RegexParseMode) -> Self {
        
        var view = self
        view.mode = mode
        
        return view
    }
    
    
    /// Sets the inset value inside the field.
    ///
    /// - Parameter inset: An amount, given in points, to inset this view on the specified edges.
    func leadingInset(_ inset: CGFloat) -> Self {
        
        var view = self
        view.leadingInset = inset
        
        return view
    }
    
    
    /// Sets the field style.
    ///
    /// - Parameter style: The field style.
    func style(_ style: Style) -> Self {
        
        var view = self
        view.style = style
        
        return view
    }
    
    
    /// Adds a condition that controls whether enabled syntax highlighting.
    ///
    /// - Parameter highlighted: A Boolean value that determines whether enabled syntax highlighting.
    func regexHighlighted(_ highlighted: Bool) -> Self {
        
        var view = self
        view.isHighlighted = highlighted
        
        return view
    }
    
    
    func makeNSView(context: Context) -> NSTextField {
        
        let textField = RegularExpressionTextField(string: self.text)
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
        (nsView as! RegularExpressionTextField).isRegexHighlighted = self.isHighlighted
        (nsView as! RegularExpressionTextField).mode = self.mode
    }
    
    
    func makeCoordinator() -> Coordinator {
        
        Coordinator(text: $text)
    }
    
    
    final class Coordinator: NSObject, NSTextFieldDelegate {
        
        @Binding private var text: String
        
        
        init(text: Binding<String>) {
            
            self._text = text
        }
        
        
        func controlTextDidChange(_ obj: Notification) {
            
            guard let textField = obj.object as? NSTextField else { return }
            
            self.text = textField.stringValue
        }
    }
}


final class RegularExpressionTextField: NSTextField {
    
    // MARK: Public Properties
    
    @objc dynamic var isRegexHighlighted = true {
        
        didSet {
            self.regexFormatter.parsesRegularExpression = isRegexHighlighted
            self.invalidateFieldEditor()
            self.needsDisplay = true
        }
    }
    
    var mode: RegexParseMode {
        
        get { self.regexFormatter.mode }
        set {
            self.regexFormatter.mode = newValue
            self.invalidateFieldEditor()
        }
    }
    
    var unescapesReplacement: Bool = false  { didSet { self.invalidateMode() } }
    @IBInspectable var isReplacement: Bool = false  { didSet { self.invalidateMode() } }
    
    
    // MARK: Private Properties
    
    private let regexFormatter = RegexFormatter(theme: .default)
    
    
    // MARK: Text Field Methods
    
    override static var cellClass: AnyClass? {
        
        get { PaddingTextFieldCell.self }
        set { _ = newValue }
    }
    
    
    override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        
        self.formatter = self.regexFormatter
    }
    
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        self.formatter = self.regexFormatter
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
    
    
    /// The string value was directly changed.
    override var objectValue: Any? {
        
        didSet {
            self.invalidateFieldEditor()
        }
    }
    
    
    // MARK: Private Methods
    
    /// Updates the formatter's mode.
    private func invalidateMode() {
        
        self.regexFormatter.mode = self.isReplacement ? .replacement(unescapes: self.unescapesReplacement) : .search
    }
    
    
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
    RegexTextField(text: .constant("[]def"))
}
