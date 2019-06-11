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

struct OutlineExtractor {
    
    var regex: NSRegularExpression
    var template: String
    var style: OutlineItem.Style
    
    
    init(definition: OutlineDefinition) throws {
        
        // compile to regex object
        var options: NSRegularExpression.Options = .anchorsMatchLines
        if definition.ignoreCase {
            options.update(with: .caseInsensitive)
        }
        self.regex = try NSRegularExpression(pattern: definition.pattern, options: options)
        
        self.template = definition.template
        
        var style = OutlineItem.Style()
        if definition.bold {
            style.update(with: .bold)
        }
        if definition.italic {
            style.update(with: .italic)
        }
        if definition.underline {
            style.update(with: .underline)
        }
        self.style = style
    }
    
    
    /// extract outline items in given string
    func items(in string: String, range parseRange: NSRange, using block: (_ stop: inout Bool) -> Void) -> [OutlineItem] {
        
        return self.regex.matches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: parseRange, using: block).map { result in
            
            // separator item
            if self.template == .separator {
                return OutlineItem(title: self.template, range: result.range)
            }
            
            // menu item title
            var title: String
            
            if self.template.isEmpty {
                // no pattern definition
                title = (string as NSString).substring(with: result.range)
                
            } else {
                // replace matched string with template
                title = self.regex.replacementString(for: result, in: string, offset: 0, template: self.template)
                
                // replace $LN with line number of the beginning of the matched range
                if title.contains("$LN") {
                    let lineNumber = string.lineNumber(at: result.range.location)
                    
                    title = title.replacingOccurrences(of: "(?<!\\\\)\\$LN", with: String(lineNumber), options: .regularExpression)
                }
            }
            
            // replace line breaks
            title = title.replacingOccurrences(of: "\n", with: " ")
            
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
