//
//  OutlineExtractor.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2018-04-30.
//
//  ---------------------------------------------------------------------------
//
//  © 2018-2026 1024jp
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
import StringUtils

public struct OutlineExtractor: Sendable {
    
    var regex: NSRegularExpression
    var template: String
    var kind: Syntax.Outline.Kind?
    
    
    init(definition: Syntax.Outline) throws {
        
        // compile to regex object
        var options: NSRegularExpression.Options = .anchorsMatchLines
        if definition.ignoreCase {
            options.formUnion(.caseInsensitive)
        }
        self.regex = try NSRegularExpression(pattern: definition.pattern, options: options)
        
        self.template = definition.template
        self.kind = definition.kind
    }
    
    
    /// Extracts outline items in the given string.
    ///
    /// - Parameters:
    ///   - string: The string to parse.
    ///   - parseRange: The range of the string to parse.
    /// - Throws: `CancellationError`
    /// - Returns: An array of `OutlineItem`.
    func items(in string: String, range parseRange: NSRange) throws -> [OutlineItem] {
        
        try self.regex.cancellableMatches(in: string, options: [.withTransparentBounds, .withoutAnchoringBounds], range: parseRange).lazy
            .compactMap { result in
                // separator
                if self.kind == .separator {
                    return OutlineItem.separator(range: result.range)
                }
                
                // standard outline
                let title = (self.template.isEmpty
                             ? (string as NSString).substring(with: result.range)
                             : self.regex.replacementString(for: result, in: string, offset: 0, template: self.template))
                    .replacing(/(\S)\s+/) { "\($0.1) " }
                
                guard
                    let match = title.firstMatch(of: /^(?<indent>\s*)(?<title>.+)$/),
                    !match.title.isEmpty
                else { return nil }
                
                return OutlineItem(title: String(match.title), range: result.range, kind: self.kind, indent: .string(String(match.indent)))
            }
            .normalizedLevels()
    }
}
