/*
 
 EncodingTableCellView.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2016-01-25.
 
 ------------------------------------------------------------------------------
 
 © 2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension NSColor {
    class func alternateDisabledControlTextColor() -> NSColor {
        return NSColor(white: 1.0, alpha: 0.75)
    }
}




// MARK:

class EncodingTableCellView: NSTableCellView {
    
    /// inverse text color of highlighted cell
    override var backgroundStyle: NSBackgroundStyle {
        
        didSet {
            guard let textField = self.textField else { return }
            
            let highlighted = (backgroundStyle == .dark)
            let attrString = textField.attributedStringValue
            let mutableAttrString = attrString.mutableCopy() as! NSMutableAttributedString
            
            attrString.enumerateAttribute(NSForegroundColorAttributeName,
                                          in: NSRange(location: 0, length: attrString.length),
                                          using: { (value: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                                            
                                            let color = value as! NSColor?
                                            var newColor: NSColor?
                                            
                                            if highlighted && color == nil {
                                                newColor = .alternateSelectedControlTextColor()
                                            } else if highlighted && color == .disabledControlTextColor() {
                                                newColor = .alternateDisabledControlTextColor()
                                            } else if !highlighted && color == .alternateSelectedControlTextColor() {
                                                newColor = nil
                                            } else if !highlighted && color == .alternateDisabledControlTextColor() {
                                                newColor = .disabledControlTextColor()
                                            } else {
                                                return
                                            }
                                            
                                            if let newColor = newColor {
                                                mutableAttrString.addAttribute(NSForegroundColorAttributeName, value: newColor, range: range)
                                            } else {
                                                mutableAttrString.removeAttribute(NSForegroundColorAttributeName, range: range)
                                            }
            })
            
            textField.attributedStringValue = mutableAttrString
        }
    }
    
}
