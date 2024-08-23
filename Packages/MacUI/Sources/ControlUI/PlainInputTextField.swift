//
//
//  PlainInputTextField.swift
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

/// Text field that keeps the standard text color while editing.
public final class PlainInputTextField: NSTextField {
    
    public override static var cellClass: AnyClass? {
        
        get { PlainInputTextFieldCell.self }
        set { _ = newValue }
    }
}


private final class PlainInputTextFieldCell: NSTextFieldCell {
    
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
