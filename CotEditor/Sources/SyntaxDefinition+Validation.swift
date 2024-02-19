//
//  SyntaxDefinition+Validation.swift
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

extension SyntaxDefinition {
    
    /// Model object for syntax validation result.
    struct Error {
        
        enum Code {
            
            case duplicated
            case empty
            case regularExpression
            case blockComment
        }
        
        
        enum Role {
            
            case begin
            case end
        }
        
        
        enum Location {
            
            case term(SyntaxType, UUID)
            case outline(UUID)
            case comment
        }
        
        
        var code: Code
        var location: Location
        var role: Role?
        var string: String
        
        
        init(_ code: Code, location: Location, role: Role? = nil, string: String) {
            
            self.code = code
            self.location = location
            self.role = role
            self.string = string
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Checks syntax and returns `Error`s.
    func validate() -> [Error] {
        
        var errors: [Error] = []
        
        for type in SyntaxType.allCases {
            let terms = self[type: type]
                .sorted {  // sort for duplication check
                    if $0.begin != $1.begin {
                        $0.begin < $1.begin
                    } else if let end0 = $0.end, let end1 = $1.end {
                        end0 < end1
                    } else {
                        true
                    }
                }
            
            // allow appearing the same terms in different kinds
            var lastTerm: Term?
            
            for term in terms {
                defer {
                    lastTerm = term
                }
                
                guard term.begin != lastTerm?.begin || term.end != lastTerm?.end else {
                    errors.append(Error(.duplicated, location: .term(type, term.id), role: .begin, string: term.begin))
                    continue
                }
                
                if term.isRegularExpression {
                    do {
                        _ = try NSRegularExpression(pattern: term.begin)
                    } catch {
                        errors.append(Error(.regularExpression, location: .term(type, term.id), role: .begin, string: term.begin))
                    }
                    
                    if let end = term.end {
                        do {
                            _ = try NSRegularExpression(pattern: end)
                        } catch {
                            errors.append(Error(.regularExpression, location: .term(type, term.id), role: .end, string: end))
                        }
                    }
                }
            }
        }
        
        for outline in self.outlines {
            if outline.pattern.isEmpty {
                errors.append(Error(.empty, location: .outline(outline.id), string: outline.pattern))
            }
            
            do {
                _ = try NSRegularExpression(pattern: outline.pattern)
            } catch {
                errors.append(Error(.regularExpression, location: .outline(outline.id), string: outline.pattern))
            }
        }
        
        // validate block comment delimiter pair
        let delimiters = self.commentDelimiters
        let beginDelimiterExists = !(delimiters.blockBegin?.isEmpty ?? true)
        let endDelimiterExists = !(delimiters.blockEnd?.isEmpty ?? true)
        if beginDelimiterExists != endDelimiterExists {
            errors.append(Error(.blockComment, location: .comment,
                                role: beginDelimiterExists ? .begin : .end,
                                string: delimiters.blockBegin ?? delimiters.blockEnd!))
        }
        
        return errors
    }
}


extension SyntaxDefinition.Error: LocalizedError {
    
    var errorDescription: String? {
        
        self.localizedType + ": " + self.string
    }
    
    
    var failureReason: String? {
        
        switch self.code {
            case .duplicated:
                String(localized: "The same word is registered multiple times.")
            case .empty:
                String(localized: "The extraction pattern is empty.")
            case .regularExpression:
                String(localized: "Invalid regular expression.")
            case .blockComment:
                String(localized: "Block comment needs both begin delimiter and end delimiter.")
        }
    }
    
    
    var localizedType: String {
        
        switch self.location {
            case .term(let syntaxType, _):
                String(localized: String.LocalizationValue(syntaxType.rawValue.capitalized))
            case .outline:
                String(localized: "Outline")
            case .comment:
                String(localized: "Comment")
        }
    }
    
    
    var localizedRole: String? {
        
        switch self.role {
            case .begin: String(localized: "Begin string")
            case .end: String(localized: "End string")
            case .none: nil
        }
    }
}
