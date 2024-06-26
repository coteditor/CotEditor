//
//  SyntaxObject+Validation.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2024 1024jp
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
import Syntax

extension SyntaxObject {
    
    struct Error: Swift.Error {
        
        enum Code {
            
            case duplicated
            case regularExpression
            case blockComment
        }
        
        
        var code: Code
        nonisolated(unsafe) var type: PartialKeyPath<SyntaxObject>
        var string: String
        
        
        init(_ code: Code, type: PartialKeyPath<SyntaxObject>, string: String) {
            
            self.code = code
            self.type = type
            self.string = string
        }
    }
    
    
    // MARK: Public Methods
    
    /// Checks syntax and returns `Error`s.
    func validate() -> [Error] {
        
        var errors: [Error] = []
        
        for keyPath in SyntaxType.allCases.map(Self.highlightKeyPath(for:)) {
            let highlights = self[keyPath: keyPath]
                .sorted {  // sort for duplication check
                    if $0.begin != $1.begin {
                        $0.begin < $1.begin
                    } else if let end0 = $0.end, let end1 = $1.end {
                        end0 < end1
                    } else {
                        true
                    }
                }
            
            // allow appearing the same highlights in different kinds
            var lastHighlight: Highlight?
            
            for highlight in highlights {
                defer {
                    lastHighlight = highlight
                }
                
                guard highlight != lastHighlight else {
                    errors.append(Error(.duplicated, type: keyPath, string: highlight.begin))
                    continue
                }
                
                if highlight.isRegularExpression {
                    do {
                        _ = try NSRegularExpression(pattern: highlight.begin)
                    } catch {
                        errors.append(Error(.regularExpression, type: keyPath, string: highlight.begin))
                    }
                    
                    if let end = highlight.end {
                        do {
                            _ = try NSRegularExpression(pattern: end)
                        } catch {
                            errors.append(Error(.regularExpression, type: keyPath, string: end))
                        }
                    }
                }
            }
        }
        
        for outline in self.outlines {
            do {
                _ = try NSRegularExpression(pattern: outline.pattern)
            } catch {
                errors.append(Error(.regularExpression, type: \.outlines, string: outline.pattern))
            }
        }
        
        // validate block comment delimiter pair
        let delimiters = self.commentDelimiters
        let beginDelimiterExists = !(delimiters.blockBegin?.isEmpty ?? true)
        let endDelimiterExists = !(delimiters.blockEnd?.isEmpty ?? true)
        if beginDelimiterExists != endDelimiterExists {
            errors.append(Error(.blockComment, type: \.commentDelimiters, string: delimiters.blockBegin ?? delimiters.blockEnd!))
        }
        
        return errors
    }
}
