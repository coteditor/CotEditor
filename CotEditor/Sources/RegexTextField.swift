//
//  RegexTextField.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2018 1024jp
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

import Cocoa

final class RegexTextField: NSTextField {
    
    // MARK: Private Properties
    
    @IBInspectable private var isReplacement: Bool = false
    @IBInspectable private var bindingKeyPath: String = ""
    
    @objc private dynamic var isRegularExpression = true {
        
        didSet {
            self.formatter = isRegularExpression ? self.regexFormatter : nil
            self.invalidateFieldEditor()
            self.needsDisplay = true
        }
    }
    
    private lazy var regexFormatter = RegularExpressionFormatter(mode: self.parseMode)
    
    
    
    // MARK: -
    // MARK: Text Field Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.formatter = self.isRegularExpression ? self.regexFormatter : nil

        // bind with cellView's objectValue
        if !self.bindingKeyPath.isEmpty  {
            guard let tableCellView = self.superview as? NSTableCellView else { return assertionFailure() }
            
            self.bind(NSBindingName(#keyPath(isRegularExpression)), to: tableCellView, withKeyPath: "objectValue." + self.bindingKeyPath, options: [.nullPlaceholder: false])
        }
    }
    
    
    /// receiver was focused to edit content
    override func becomeFirstResponder() -> Bool {
        
        guard super.becomeFirstResponder() else { return false }
        
        self.invalidateFieldEditor()
        
        return true
    }
    
    
    /// text (in the field editor) was just changed
    override func textDidChange(_ notification: Notification) {
        
        super.textDidChange(notification)
        
        self.invalidateFieldEditor()
    }
    
    
    
    // MARK: Private Methods
    
    private var parseMode: RegularExpressionParseMode {
        
        return self.isReplacement ? .replacement(unescapes: false) : .search
    }
    
    
    /// syntax highlight field editor
    private func invalidateFieldEditor() {
        
        guard let editor = self.currentEditor() as? NSTextView else { return }
        
        editor.highlightAsRegularExpressionPattern(mode: self.parseMode, enabled: self.isRegularExpression)
    }
    
}
