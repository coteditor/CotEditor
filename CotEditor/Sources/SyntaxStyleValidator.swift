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
//  © 2014-2018 1024jp
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
            case regularExpression(error: Swift.Error)
            case blockComment
        }
        
        enum Role {
            case begin
            case end
            case regularExpression
        }
        
        let kind: ErrorKind
        let type: String
        let role: Role
        let string: String
        
        
        var errorDescription: String? {
            
            return self.type.localized + " [" + self.localizedRole + "]: " + self.string
        }
        
        
        var failureReason: String? {
            
            switch self.kind {
            case .duplicated:
                return "The same word is registered multiple times.".localized
                
            case .regularExpression(let error):
                return "Regular Expression Error: ".localized + error.localizedDescription
            
            case .blockComment:
                return "Block comment needs both begin delimiter and end delimiter.".localized
            }
        }
        
        
        private var localizedRole: String {
            
            switch self.role {
            case .begin:
                return "Begin string".localized
                
            case .end:
                return "End string".localized
                
            case .regularExpression:
                return "Regular expression".localized
            }
        }
        
    }
    
    
    // MARK: -
    // MARK: Lifecycle
    
    private init() { }
    
    
    
    // MARK: Public Methods
    
    /// check regular expression syntax and duplicatioin and return errors
    static func validate(_ styleDictionary: SyntaxManager.StyleDictionary) -> [StyleError] {
        
        var results = [StyleError]()
        
        let syntaxDictKeys = SyntaxType.allCases.map { $0.rawValue } + [SyntaxKey.outlineMenu.rawValue]
        
        var lastBeginString: String?
        var lastEndString: String?
        
        for key in syntaxDictKeys {
            guard let dictionaries = styleDictionary[key] as? [[String: Any]] else { continue }
            
            let definitions = dictionaries
                .compactMap { HighlightDefinition(dictionary: $0) }
                .sorted {
                    // sort for duplication check
                    guard $0.beginString == $1.beginString else {
                        return $0.beginString < $1.beginString
                    }
                    guard
                        let endString1 = $1.endString,
                        let endString0 = $0.endString else { return true }
                    
                    return endString0 < endString1
                }
            
            for definition in definitions {
                defer {
                    lastBeginString = definition.beginString
                    lastEndString = definition.endString
                }
                
                guard definition.beginString != lastBeginString || definition.endString != lastEndString else {
                    results.append(StyleError(kind: .duplicated,
                                              type: key,
                                              role: .begin,
                                              string: definition.beginString))
                    
                    continue
                }
                
                if definition.isRegularExpression {
                    do {
                        _ = try NSRegularExpression(pattern: definition.beginString)
                    } catch {
                        results.append(StyleError(kind: .regularExpression(error: error),
                                                  type: key,
                                                  role: .begin,
                                                  string: definition.beginString))
                    }
                    
                    if let endString = definition.endString {
                        do {
                            _ = try NSRegularExpression(pattern: endString)
                        } catch {
                            results.append(StyleError(kind: .regularExpression(error: error),
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
                        results.append(StyleError(kind: .regularExpression(error: error),
                                                  type: key,
                                                  role: .regularExpression,
                                                  string: definition.beginString))
                    }
                }
            }
        }
        
        // validate block comment delimiter pair
        if let commentDelimiters = styleDictionary[SyntaxKey.commentDelimiters.rawValue] as? [String: String] {
            let beginDelimiter = commentDelimiters[DelimiterKey.beginDelimiter.rawValue]
            let endDelimiter = commentDelimiters[DelimiterKey.endDelimiter.rawValue]
            let beginDelimiterExists = !(beginDelimiter?.isEmpty ?? true)
            let endDelimiterExists = !(endDelimiter?.isEmpty ?? true)
            if (beginDelimiterExists && !endDelimiterExists) || (!beginDelimiterExists && endDelimiterExists) {
                results.append(StyleError(kind: .blockComment,
                                          type: "comment",
                                          role: beginDelimiterExists ? .begin : .end,
                                          string: beginDelimiter ?? endDelimiter!))
            }
        }
        
        return results
    }
    
}
