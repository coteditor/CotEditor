//
//  InsetTextField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2025 1024jp
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

struct InsetTextField: NSViewRepresentable {
    
    typealias NSViewType = NSTextField
    
    @Binding private var text: String
    private var prompt: String?
    
    private var insets: EdgeInsets = .init()
    private var usesMonospacedDigit = false
    private var onSubmit: () -> Void = {}
    
    
    init(text: Binding<String>, prompt: String? = nil) {
        
        self._text = text
        self.prompt = prompt
    }
    
    
    func makeNSView(context: Context) -> NSTextField {
        
        let textField = PaddingTextField(string: self.text)
        textField.leadingPadding = self.insets.leading
        textField.trailingPadding = self.insets.trailing
        textField.delegate = context.coordinator
        textField.placeholderString = self.prompt
        textField.isEditable = true
        
        return textField
    }
    
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        
        nsView.stringValue = self.text
        (nsView as! PaddingTextField).leadingPadding = self.insets.leading
        (nsView as! PaddingTextField).trailingPadding = self.insets.trailing
        if self.usesMonospacedDigit, let font = nsView.font {
            nsView.font = .monospacedDigitSystemFont(ofSize: font.pointSize, weight: font.weight)
        }
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


extension InsetTextField {
    
    /// Sets the inset value inside the field.
    ///
    /// - Parameters:
    ///   - edges: The set of edges to inset for this view.
    ///   - length: An amount, given in points, to inset this view on the specified edges.
    func inset(_ edges: Edge.Set, _ length: CGFloat) -> Self {
        
        assert(!edges.isEmpty)
        assert(edges.isDisjoint(with: .vertical))
        
        var view = self
        if edges.contains(.leading) {
            view.insets.leading = length
        }
        if edges.contains(.trailing) {
            view.insets.trailing = length
        }
        
        return view
    }
    
    
    /// Sets an action to perform when the user submits a value to this view.
    ///
    /// - Parameter action: The action to perform on submission of a value.
    func onSubmit(_ action: @escaping () -> Void) -> Self {
        
        var view = self
        view.onSubmit = action
        return view
    }
    
    
    /// Modifies the font to use fixed-width digits.
    func monospacedDigit() -> Self {
        
        var view = self
        view.usesMonospacedDigit = true
        return view
    }
}


private final class PaddingTextField: NSTextField {
    
    override static var cellClass: AnyClass? {
        
        get { PaddingTextFieldCell.self }
        set { _ = newValue }
    }
    
    
    var leadingPadding: CGFloat {
        
        get { (self.cell as? PaddingTextFieldCell)?.leadingPadding ?? 0 }
        set { (self.cell as? PaddingTextFieldCell)?.leadingPadding = newValue }
    }
    
    var trailingPadding: CGFloat {
        
        get { (self.cell as? PaddingTextFieldCell)?.trailingPadding ?? 0 }
        set { (self.cell as? PaddingTextFieldCell)?.trailingPadding = newValue }
    }
}


// MARK: - Preview

#Preview {
    @Previewable @State var text = ""
    
    InsetTextField(text: $text, prompt: "Prompt")
        .inset(.leading, 20)
        .frame(width: 160)
}
