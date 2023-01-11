//
//  SyntaxStyleValidator.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by nakamuxu on 2004-12-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2023 1024jp
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

final class SyntaxStyleValidator {
    
    /// model object for syntax validation result
    struct StyleError: LocalizedError {
        
        enum ErrorKind {
            
            case duplicated
            case regularExpression
            case blockComment
        }
        
        
        enum Role {
            
            case begin
            case end
        }
        
        
        let kind: ErrorKind
        let type: String
        let role: Role?
        let string: String
    }
    
    
    
    // MARK: Public Properties
    
    @Published private(set) var errors: [StyleError] = []
    
    
    // MARK: Private Properties
    
    private let style: NSMutableDictionary
    
    
    
    // MARK: -
    // MARK: Lyfestyle
    
    init(style: NSMutableDictionary) {
        
        assert(style is SyntaxManager.StyleDictionary)
        
        self.style = style
    }
    
    
    
    // MARK: Public Methods
    
    /// Check style and update `errors`.
    ///
    /// - Returns: `true` when the style is valid; otherwise `false`.``
    @discardableResult
    func validate() -> Bool {
        
        guard let styleDictionary = self.style as? SyntaxManager.StyleDictionary else { return false }
        
        self.errors.removeAll()
        
        let syntaxDictKeys = SyntaxType.allCases.map(\.rawValue) + [SyntaxKey.outlineMenu.rawValue]
        
        for key in syntaxDictKeys {
            guard let dictionaries = styleDictionary[key] as? [[String: Any]] else { continue }
            
            let definitions = dictionaries
                .compactMap { try? HighlightDefinition(dictionary: $0) }
                .sorted {
                    // sort for duplication check
                    guard $0.beginString == $1.beginString else {
                        return $0.beginString < $1.beginString
                    }
                    guard
                        let endString1 = $1.endString,
                        let endString0 = $0.endString
                    else { return true }
                    
                    return endString0 < endString1
                }
            
            // allow appearing the same definitions in different kinds
            var lastDefinition: HighlightDefinition?
            
            for definition in definitions {
                defer {
                    lastDefinition = definition
                }
                
                guard
                    definition.beginString != lastDefinition?.beginString ||
                    definition.endString != lastDefinition?.endString
                else {
                    self.errors.append(StyleError(kind: .duplicated,
                                                  type: key,
                                                  role: .begin,
                                                  string: definition.beginString))
                    continue
                }
                
                if definition.isRegularExpression {
                    do {
                        _ = try NSRegularExpression(pattern: definition.beginString)
                    } catch {
                        self.errors.append(StyleError(kind: .regularExpression,
                                                      type: key,
                                                      role: .begin,
                                                      string: definition.beginString))
                    }
                    
                    if let endString = definition.endString {
                        do {
                            _ = try NSRegularExpression(pattern: endString)
                        } catch {
                            self.errors.append(StyleError(kind: .regularExpression,
                                                          type: key,
                                                          role: .end,
                                                          string: endString))
                        }
                    }
                }
                
                if key == SyntaxKey.outlineMenu.rawValue {
                    do {
                        _ = try NSRegularExpression(pattern: definition.beginString)
                    } catch {
                        self.errors.append(StyleError(kind: .regularExpression,
                                                      type: "outline",
                                                      role: nil,
                                                      string: definition.beginString))
                    }
                }
            }
        }
        
        // validate block comment delimiter pair
        if let commentDelimiters = styleDictionary[SyntaxKey.commentDelimiters] as? [String: String] {
            let beginDelimiter = commentDelimiters[DelimiterKey.beginDelimiter]
            let endDelimiter = commentDelimiters[DelimiterKey.endDelimiter]
            let beginDelimiterExists = !(beginDelimiter?.isEmpty ?? true)
            let endDelimiterExists = !(endDelimiter?.isEmpty ?? true)
            if beginDelimiterExists != endDelimiterExists {
                self.errors.append(StyleError(kind: .blockComment,
                                              type: "comments",
                                              role: beginDelimiterExists ? .begin : .end,
                                              string: beginDelimiter ?? endDelimiter!))
            }
        }
        
        return self.errors.isEmpty
    }
}


extension SyntaxStyleValidator.StyleError {
    
    var errorDescription: String? {
        
        self.type.localized + ": " + self.string
    }
    
    
    var failureReason: String? {
        
        switch self.kind {
            case .duplicated:
                return "The same word is registered multiple times.".localized
                
            case .regularExpression:
                return "Invalid regular expression.".localized
                
            case .blockComment:
                return "Block comment needs both begin delimiter and end delimiter.".localized
        }
    }
    
    
    var localizedType: String {
        
        self.type.localized
    }
    
    
    var localizedRole: String? {
        
        switch self.role {
            case .begin:
                return "Begin string".localized
                
            case .end:
                return "End string".localized
                
            case .none:
                return nil
        }
    }
}
