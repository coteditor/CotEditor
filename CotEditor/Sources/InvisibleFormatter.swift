//
//  InvisibleFormatter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-01.
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

import Foundation
import AppKit.NSColor

final class InvisibleFormatter: Formatter {
    
    // MARK: Properties
    
    var invisibles: [Invisible] = [.newLine, .tab, .fullwidthSpace]
    
    
    
    // MARK: -
    // MARK: Formatter Function
    
    /// convert to plain string
    override func string(for obj: Any?) -> String? {
        
        return obj as? String
    }
    
    
    /// make invisible characters visible
    override func attributedString(for obj: Any, withDefaultAttributes attrs: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString? {
        
        guard let string = self.string(for: obj) else { return nil }
        
        let attributedString = NSMutableAttributedString(string: string, attributes: attrs)
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.tertiaryLabelColor]
        
        for (index, codeUnit) in string.utf16.enumerated() {
            guard
                let invisible = Invisible(codeUnit: codeUnit),
                self.invisibles.contains(invisible)
                else { continue }
            
            let range = NSRange(location: index, length: 1)
            attributedString.replaceCharacters(in: range, with: NSAttributedString(string: invisible.usedSymbol, attributes: attributes))
        }
        
        return attributedString
    }
    
    
    /// format backwards
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        obj?.pointee = string as AnyObject
        
        return true
    }
    
}
