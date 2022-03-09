//
//  OutlineExtractor.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2022 1024jp
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

struct OutlineExtractor {
    
    var regex: NSRegularExpression
    var template: String
    var style: OutlineItem.Style
    
    
    init(definition: OutlineDefinition) throws {
        
        // compile to regex object
        var options: NSRegularExpression.Options = .anchorsMatchLines
        if definition.ignoreCase {
            options.formUnion(.caseInsensitive)
        }
        self.regex = try NSRegularExpression(pattern: definition.pattern, options: options)
        
        self.template = definition.template
        
        var style = OutlineItem.Style()
        if definition.bold {
            style.formUnion(.bold)
        }
        if definition.italic {
            style.formUnion(.italic)
        }
        if definition.underline {
            style.formUnion(.underline)
        }
        self.style = style
    }
    
    
    /// Extract outline items in given string.
    ///
    /// - Parameters:
    ///   - string: The string to parse.
    ///   - parseRange: The range of the string to parse.
    /// - Throws: `CancellationError`
    /// - Returns: An array of `OutlineItem`.
    func items(in string: String, range parseRange: NSRange) async throws -> [OutlineItem] {
        
        try await self.regex.matches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: parseRange).lazy.map { result in
            
            // separator item
            if self.template == .separator {
                return OutlineItem(title: self.template, range: result.range)
            }
            
            // menu item
            var title: String
            
            if self.template.isEmpty {
                title = (string as NSString).substring(with: result.range)
                
            } else {
                let template: String
                if self.template.contains("$LN") {
                    let lineNumber = string.lineNumber(at: result.range.location)
                    template = self.template.replacingOccurrences(of: "$LN", with: String(lineNumber), options: .literal)
                } else {
                    template = self.template
                }
                
                title = self.regex.replacementString(for: result, in: string, offset: 0, template: template)
            }
            
            title = title.replacingOccurrences(of: "\\R", with: " ", options: .regularExpression)
            
            return OutlineItem(title: title, range: result.range, style: self.style)
        }
    }
    
}


extension OutlineExtractor: Equatable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        
        return lhs.regex.pattern == rhs.regex.pattern &&
            lhs.regex.options == rhs.regex.options &&
            lhs.template == rhs.template &&
            lhs.style == rhs.style
    }
    
}
