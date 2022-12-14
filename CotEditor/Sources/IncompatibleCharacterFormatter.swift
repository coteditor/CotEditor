//
//  IncompatibleCharacterFormatter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2021-10-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2021 1024jp
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
import AppKit.NSColor

final class IncompatibleCharacterFormatter: Formatter {
    
    private let invisibleCategories: Set<Unicode.GeneralCategory> = [.control, .spaceSeparator, .lineSeparator]
    
    
    
    // MARK: Formatter Function
    
    /// convert to plain string
    override func string(for obj: Any?) -> String? {
        
        obj as? String
    }
    
    
    /// create attributed string from object
    override func attributedString(for obj: Any, withDefaultAttributes attrs: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString? {
        
        guard
            let string = self.string(for: obj),
            string.unicodeScalars.compareCount(with: 1) == .equal,
            let unicode = string.unicodeScalars.first,
            self.invisibleCategories.contains(unicode.properties.generalCategory)
        else { return nil }
        
        let attributes = (attrs ?? [:]).merging([.foregroundColor: NSColor.tertiaryLabelColor]) { $1 }
        
        return NSAttributedString(string: unicode.codePoint, attributes: attributes)
    }
}
