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
    
    // MARK: Public Properties
    
    @IBInspectable private var regexKeyPath: String = "objectValue.regularExpression"
    
    @objc dynamic var isRegularExpression = true {
        
        didSet {
            self.formatter = isRegularExpression ? self.regexFormatter : nil
            self.needsDisplay = true
        }
    }
    
    
    // MARK: Private Properties
    
    private lazy var regexFormatter =  RegularExpressionFormatter()
    
    
    
    // MARK: -
    // MARK: Text Field Methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        guard let tableCellView = self.superview as? NSTableCellView else { return assertionFailure() }
        
        // bind with cellView's objectValue
        self.bind(NSBindingName(#keyPath(isRegularExpression)), to: tableCellView, withKeyPath: self.regexKeyPath, options: [.nullPlaceholder: false])
    }
    
}
