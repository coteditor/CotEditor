//
//  StyledButton.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2017-03-12.
//
//  ---------------------------------------------------------------------------
//
//  © 2017-2019 1024jp
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

@IBDesignable
final class StyledButton: NSButton {
    
    @IBInspectable var isItalic: Bool = false {
        
        didSet {
            guard let font = self.font else { return }
            
            self.font = isItalic
                ? NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                : NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask)
        }
    }
    
    
    @IBInspectable var isUnderlined: Bool = false {
        
        didSet {
            let attributedTitle = self.attributedTitle.mutable
            let range = attributedTitle.range
            
            if isUnderlined {
                attributedTitle.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            } else {
                attributedTitle.removeAttribute(.underlineStyle, range: range)
            }
            
            self.attributedTitle = attributedTitle
        }
    }
    
}
