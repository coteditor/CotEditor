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

final class RegularExpressionFormatter: Formatter {
    
    // MARK: Public Properties
    
    var parsesRegularExpression: Bool = true
    var mode: RegularExpressionParseMode = .search
    
    
    
    // MARK: -
    // MARK: Lifecycle
    
    convenience init(mode: RegularExpressionParseMode) {
        
        self.init()
        self.mode = mode
    }
    
    
    
    // MARK: Formatter Function
    
    /// convert to plain string
    override func string(for obj: Any?) -> String? {
        
        return obj as? String
    }
    
    
    /// syntax highlight regular expression pattern
    override func attributedString(for obj: Any, withDefaultAttributes attrs: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString? {
        
        guard let string = self.string(for: obj) else { return nil }
        
        let attributedString = NSMutableAttributedString(string: string, attributes: attrs)
        
        guard self.parsesRegularExpression, !string.isEmpty else { return attributedString }
        
        // valdiate regex pattern
        switch self.mode {
        case .search:
            do {
                _ = try NSRegularExpression(pattern: string)
            } catch {
                attributedString.insert(NSAttributedString(string: "⚠️ "), at: 0)
                return attributedString
            }
        case .replacement: break
        }
        
        // syntax highlight
        for type in RegularExpressionSyntaxType.priority.reversed() {
            for range in type.ranges(in: string, mode: self.mode) {
                attributedString.addAttribute(.foregroundColor, value: type.color, range: range)
            }
        }
        
        return attributedString
    }
    
    
    /// format backwards
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        obj?.pointee = string as AnyObject
        
        return true
    }
    
}
