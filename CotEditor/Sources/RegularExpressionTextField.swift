//
//  RegularExpressionTextField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2022 1024jp
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

final class RegularExpressionTextField: NSTextField {
    
    // MARK: Public Properties
    
    @objc dynamic var parsesRegularExpression = true {
        
        didSet {
            self.regexFormatter.parsesRegularExpression = parsesRegularExpression
            self.invalidateFieldEditor()
            self.needsDisplay = true
        }
    }
    
    var unescapesReplacement: Bool = false {
        
        didSet {
            self.regexFormatter.mode = self.parseMode
        }
    }
    
    
    // MARK: Private Properties
    
    private let regexFormatter = RegularExpressionFormatter()
    
    @IBInspectable private var isReplacement: Bool = false
    @IBInspectable private var showsError: Bool = true
    @IBInspectable private var showsInvisibles: Bool = false
    @IBInspectable private var bindingKeyPath: String = ""
    
    
    
    // MARK: -
    // MARK: Text Field Methods
    
    override class var cellClass: AnyClass? {
        
        get { PaddingTextFieldCell.self }
        set { _ = newValue }
    }
    
    
    init(string: String = "") {
     
        super.init(frame: .zero)
        
        self.formatter = self.regexFormatter
        self.stringValue = string
    }
    
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        
        self.formatter = self.regexFormatter
    }
    
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        // setup regex formatter
        self.regexFormatter.mode = self.parseMode
        self.regexFormatter.showsError = self.showsError
        self.regexFormatter.showsInvisibles = self.showsInvisibles
        self.formatter = formatter
        
        // bind with cellView's objectValue
        if !self.bindingKeyPath.isEmpty {
            guard let tableCellView = self.superview as? NSTableCellView else { return assertionFailure() }
            
            self.bind(NSBindingName(#keyPath(parsesRegularExpression)), to: tableCellView, withKeyPath: "objectValue." + self.bindingKeyPath, options: [.nullPlaceholder: false])
        }
    }
    
    
    /// The Receiver was focused to edit content.
    override func becomeFirstResponder() -> Bool {
        
        guard super.becomeFirstResponder() else { return false }
        
        self.invalidateFieldEditor()
        
        return true
    }
    
    
    /// Invoked when the text in the field editor was just changed.
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
    
    private var parseMode: RegularExpressionParseMode {
        
        self.isReplacement ? .replacement(unescapes: self.unescapesReplacement) : .search
    }
    
    
    /// Syntax highlights the field editor.
    private func invalidateFieldEditor() {
        
        guard let editor = self.currentEditor() as? NSTextView else { return }
        
        editor.highlightAsRegularExpressionPattern(mode: self.parseMode, enabled: self.parsesRegularExpression)
    }
}
