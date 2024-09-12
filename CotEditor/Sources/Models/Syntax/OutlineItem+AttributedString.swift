//
//  OutlineItem+AttributedString.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-02-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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

import Foundation
import SwiftUI
import AppKit.NSFont
import Syntax

extension OutlineItem {
    
    /// Returns styled title for a view in AppKit.
    ///
    /// - Parameters:
    ///   - baseFont: The base font of change.
    /// - Returns: An AttributedString.
    func attributes(baseFont: NSFont) -> [NSAttributedString.Key: Any] {
        
        var attributes: [NSAttributedString.Key: Any] = [:]
        var traits: NSFontDescriptor.SymbolicTraits = []
        
        if self.style.contains(.bold) {
            traits.insert(.bold)
        }
        if self.style.contains(.italic) {
            traits.insert(.italic)
        }
        if self.style.contains(.underline) {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        
        attributes[.font] = traits.isEmpty
            ? baseFont
            : NSFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(traits), size: baseFont.pointSize)
        
        return attributes
    }
    
    
    /// Returns styled title applying the filter match highlight for a view in SwiftUI.
    ///
    /// - Parameter fontSize: The size of the font.
    /// - Returns: An AttributedString.
    func attributes(fontSize: Double = 0) -> AttributeContainer {
        
        var attributes = AttributeContainer()
        var font: Font = .system(size: fontSize)
        
        if self.style.contains(.bold) {
            font = font.bold()
        }
        if self.style.contains(.italic) {
            font = font.italic()
        }
        if self.style.contains(.underline) {
            attributes.underlineStyle = .single
        }
        
        attributes.font = font
        
        return attributes
    }
}
