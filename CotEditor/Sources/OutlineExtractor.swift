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
        
        self.style = OutlineItem.Style()
            .union(definition.bold ? .bold : [])
            .union(definition.italic ? .italic : [])
            .union(definition.underline ? .underline : [])
    }
    
    
    /// Extracts outline items in the given string.
    ///
    /// - Parameters:
    ///   - string: The string to parse.
    ///   - parseRange: The range of the string to parse.
    /// - Throws: `CancellationError`
    /// - Returns: An array of `OutlineItem`.
    func items(in string: String, range parseRange: NSRange) throws -> [OutlineItem] {
        
        try self.regex.cancellableMatches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: parseRange).lazy.map { result in
            
            // separator
            if self.template == .separator {
                return OutlineItem(title: self.template, range: result.range)
            }
            
            // standard outline
            let title = (self.template.isEmpty
                         ? (string as NSString).substring(with: result.range)
                         : self.regex.replacementString(for: result, in: string, offset: 0, template: self.template))
                .replacing(/\R/, with: " ")
            
            return OutlineItem(title: title, range: result.range, style: self.style)
        }
    }
}
