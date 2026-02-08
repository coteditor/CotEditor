//
//  Syntax+Validation.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2026 1024jp
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
internal import StringUtils

public extension Syntax {
    
    struct Error: Swift.Error, Equatable {
        
        public enum Code: Equatable, Sendable {
            
            case duplicated
            case regularExpression
            case blockComment
        }
        
        
        public enum Scope: Equatable, Sendable {
            
            case highlight(SyntaxType)
            case outline
            case blockComment
        }
        
        
        public var code: Code
        public var scope: Scope
        public var value: String
        
        
        public init(_ code: Code, scope: Scope, value: String) {
            
            self.code = code
            self.scope = scope
            self.value = value
        }
    }
    
    
    // MARK: Public Methods
    
    /// Checks syntax and returns `Error`s.
    func validate() -> [Error] {
        
        var errors: [Error] = []
        
        for type in SyntaxType.allCases {
            guard let highlights = self.highlights[type]?
                .sorted(using: [KeyPathComparator(\.begin), KeyPathComparator(\.end)])  // sort for duplication check
            else { continue }
            
            // allow appearing the same highlights in different kinds
            var lastHighlight: Syntax.Highlight?
            
            for highlight in highlights {
                defer {
                    lastHighlight = highlight
                }
                
                guard highlight != lastHighlight else {
                    errors.append(Error(.duplicated, scope: .highlight(type), value: highlight.begin))
                    continue
                }
                
                if highlight.isRegularExpression {
                    do {
                        _ = try NSRegularExpression(pattern: highlight.begin)
                    } catch {
                        errors.append(Error(.regularExpression, scope: .highlight(type), value: highlight.begin))
                    }
                    
                    if let end = highlight.end {
                        do {
                            _ = try NSRegularExpression(pattern: end)
                        } catch {
                            errors.append(Error(.regularExpression, scope: .highlight(type), value: end))
                        }
                    }
                }
            }
        }
        
        for outline in self.outlines {
            do {
                _ = try NSRegularExpression(pattern: outline.pattern)
            } catch {
                errors.append(Error(.regularExpression, scope: .outline, value: outline.pattern))
            }
        }
        
        // validate block comment delimiter pairs
        errors += self.commentDelimiters.blocks.compactMap { delimiter in
            switch (delimiter.begin.isEmpty, delimiter.end.isEmpty) {
                case (false, false), (true, true): nil
                case (true, false): Error(.blockComment, scope: .blockComment, value: delimiter.end)
                case (false, true): Error(.blockComment, scope: .blockComment, value: delimiter.begin)
            }
        }
        
        return errors
    }
}
