//
//
//  FilenameTextField.swift
//  ControlUI
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-08-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
import URLUtils

/// Text field that keeps the standard text color while editing.
public final class FilenameTextField: NSTextField {
    
    public override static var cellClass: AnyClass? {
        
        get { FilenameTextFieldCell.self }
        set { _ = newValue }
    }
    
    
    public override var stringValue: String {
        
        didSet {
            self.invalidateToolTip()
        }
    }
    
    
    public override func setFrameSize(_ newSize: NSSize) {
        
        super.setFrameSize(newSize)
        
        self.invalidateToolTip()
    }
    
    
    public override func mouseDown(with event: NSEvent) {
        
        super.mouseDown(with: event)
        
        self.currentEditor()?.selectFilename()
    }
    
    
    public override func becomeFirstResponder() -> Bool {
        
        guard super.becomeFirstResponder() else { return false }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentEditor()?.selectFilename()
        }
        
        return true
    }
    
    
    /// Invalidates whether showing the tool tip if the label is truncated.
    private func invalidateToolTip() {
        
        guard let cell else { return }
        
        let expansionFrame = cell.expansionFrame(withFrame: self.frame, in: self)
        let isTruncated = !expansionFrame.isEmpty
        
        self.toolTip = isTruncated ? self.stringValue : nil
    }
}


private final class FilenameTextFieldCell: NSTextFieldCell {
    
    private var originalTextColor: NSColor?
    
    
    override func setUpFieldEditorAttributes(_ textObj: NSText) -> NSText {
        
        self.originalTextColor = self.textColor
        self.textColor = .labelColor
        
        return super.setUpFieldEditorAttributes(textObj)
    }
    
    
    override func endEditing(_ textObj: NSText) {
        
        super.endEditing(textObj)
        
        self.textColor = self.originalTextColor
    }
}


private extension NSText {
    
    /// Selects all text without filename extension.
    func selectFilename() {
        
        self.selectedRange = NSRange(..<self.string.deletingPathExtension.utf16.count)
    }
}
