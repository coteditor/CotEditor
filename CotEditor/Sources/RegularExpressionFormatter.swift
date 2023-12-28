//
//  RegularExpressionFormatter.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-12-23.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2023 1024jp
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

final class RegularExpressionFormatter: Formatter {
    
    // MARK: Public Properties
    
    var mode: RegularExpressionParseMode = .search
    var parsesRegularExpression: Bool = true
    var showsInvisibles: Bool = false
    var showsError: Bool = true
    
    
    // MARK: Private Properties
    
    private let invisibles: [Invisible] = [.newLine, .tab, .fullwidthSpace]
    
    
    
    // MARK: -
    // MARK: Formatter Function
    
    /// Converts to plain string
    override func string(for obj: Any?) -> String? {
        
        obj as? String
    }
    
    
    /// Creates attributed string from object.
    override func attributedString(for obj: Any, withDefaultAttributes attrs: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString? {
        
        guard let string = self.string(for: obj) else { return nil }
        
        let attributedString = NSMutableAttributedString(string: string, attributes: attrs)
        
        guard !string.isEmpty else { return attributedString }
        
        if self.parsesRegularExpression {
            // validate regex pattern
            switch self.mode {
                case .search:
                    do {
                        _ = try NSRegularExpression(pattern: string)
                    } catch {
                        if self.showsError {
                            let alert = NSAttributedString(systemSymbolName: "exclamationmark.triangle.fill",
                                                           configuration: .preferringMulticolor())
                            attributedString.insert(alert, at: 0)
                        }
                        return attributedString
                    }
                case .replacement: break
            }
            
            // syntax highlight
            for type in RegularExpressionSyntaxType.allCases.reversed() {
                for range in type.ranges(in: string, mode: self.mode) {
                    attributedString.addAttribute(.foregroundColor, value: type.color, range: range)
                }
            }
        }
        
        if self.showsInvisibles {
            let attributes = (attrs ?? [:]).merging([.foregroundColor: NSColor.tertiaryLabelColor]) { $1 }
            
            for (index, codeUnit) in string.utf16.enumerated() {
                guard
                    let invisible = Invisible(codeUnit: codeUnit),
                    self.invisibles.contains(invisible)
                else { continue }
                
                let attributedInvisible = NSAttributedString(string: String(invisible.symbol), attributes: attributes)
                attributedString.replaceCharacters(in: NSRange(location: index, length: 1), with: attributedInvisible)
            }
        }
        
        return attributedString
    }
    
    
    /// Formats backwards.
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        obj?.pointee = string as AnyObject
        
        return true
    }
}
