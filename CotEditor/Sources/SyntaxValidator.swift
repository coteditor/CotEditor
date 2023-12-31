//
//  SyntaxValidator.swift
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

final class SyntaxValidator {
    
    /// Model object for syntax validation result.
    struct Error: LocalizedError {
        
        enum Code {
            
            case duplicated
            case regularExpression
            case blockComment
        }
        
        
        enum Role {
            
            case begin
            case end
        }
        
        
        var code: Code
        var type: String
        var role: Role?
        var string: String
        
        
        init(_ code: Code, type: String, role: Role?, string: String) {
            
            self.code = code
            self.type = type
            self.role = role
            self.string = string
        }
    }
    
    
    
    // MARK: Public Properties
    
    @Published private(set) var errors: [Error] = []
    
    
    // MARK: Private Properties
    
    private let syntax: NSMutableDictionary
    
    
    
    // MARK: Lifestyle
    
    init(syntax: NSMutableDictionary) {
        
        assert(syntax is SyntaxManager.SyntaxDictionary)
        
        self.syntax = syntax
    }
    
    
    
    // MARK: Public Methods
    
    /// Checks syntax and update `errors`.
    ///
    /// - Returns: `true` when the syntax is valid; otherwise `false`.``
    @discardableResult
    func validate() -> Bool {
        
        guard let syntaxDictionary = self.syntax as? SyntaxManager.SyntaxDictionary else { return false }
        
        self.errors.removeAll()
        
        let syntaxDictKeys = SyntaxType.allCases.map(\.rawValue) + [SyntaxKey.outlineMenu.rawValue]
        
        for key in syntaxDictKeys {
            guard let dictionaries = syntaxDictionary[key] as? [[String: Any]] else { continue }
            
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
                    self.errors.append(Error(.duplicated, type: key, role: .begin, string: definition.beginString))
                    continue
                }
                
                if definition.isRegularExpression {
                    do {
                        _ = try NSRegularExpression(pattern: definition.beginString)
                    } catch {
                        self.errors.append(Error(.regularExpression, type: key, role: .begin, string: definition.beginString))
                    }
                    
                    if let endString = definition.endString {
                        do {
                            _ = try NSRegularExpression(pattern: endString)
                        } catch {
                            self.errors.append(Error(.regularExpression, type: key, role: .end, string: endString))
                        }
                    }
                }
                
                if key == SyntaxKey.outlineMenu.rawValue {
                    do {
                        _ = try NSRegularExpression(pattern: definition.beginString)
                    } catch {
                        self.errors.append(Error(.regularExpression, type: "outline", role: nil, string: definition.beginString))
                    }
                }
            }
        }
        
        // validate block comment delimiter pair
        if let commentDelimiters = syntaxDictionary[SyntaxKey.commentDelimiters] as? [String: String] {
            let beginDelimiter = commentDelimiters[DelimiterKey.beginDelimiter]
            let endDelimiter = commentDelimiters[DelimiterKey.endDelimiter]
            let beginDelimiterExists = !(beginDelimiter?.isEmpty ?? true)
            let endDelimiterExists = !(endDelimiter?.isEmpty ?? true)
            if beginDelimiterExists != endDelimiterExists {
                self.errors.append(Error(.blockComment, type: "comments",
                                         role: beginDelimiterExists ? .begin : .end,
                                         string: beginDelimiter ?? endDelimiter!))
            }
        }
        
        return self.errors.isEmpty
    }
}


extension SyntaxValidator.Error {
    
    var errorDescription: String? {
        
        self.localizedType + ": " + self.string
    }
    
    
    var failureReason: String? {
        
        switch self.code {
            case .duplicated:
                String(localized: "The same word is registered multiple times.")
            case .regularExpression:
                String(localized: "Invalid regular expression.")
            case .blockComment:
                String(localized: "Block comment needs both begin delimiter and end delimiter.")
        }
    }
    
    
    var localizedType: String {
        
        String(localized: String.LocalizationValue(self.type.capitalized))
    }
    
    
    var localizedRole: String? {
        
        switch self.role {
            case .begin: String(localized: "Begin string")
            case .end: String(localized: "End string")
            case .none: nil
        }
    }
}
