//
//  SyntaxDictionary.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-24.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2021 1024jp
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

enum SyntaxType: String, CaseIterable {
    
    case keywords
    case commands
    case types
    case attributes
    case variables
    case values
    case numbers
    case strings
    case characters
    case comments
    
    var localizedName: String {
        
        return self.rawValue.localized
    }
    
}


enum SyntaxKey: String {
    
    case metadata
    case extensions
    case filenames
    case interpreters
    
    case commentDelimiters
    case outlineMenu
    case completions
    
    
    static let mappingKeys: [SyntaxKey] = [.extensions, .filenames, .interpreters]
}


enum SyntaxDefinitionKey: String {
    
    case keyString
    case beginString
    case endString
    case ignoreCase
    case regularExpression
}


enum DelimiterKey: String {
    
    case inlineDelimiter
    case beginDelimiter
    case endDelimiter
}


enum MetadataKey: String {
    
    case author
    case distributionURL
    case license
    case description
}
