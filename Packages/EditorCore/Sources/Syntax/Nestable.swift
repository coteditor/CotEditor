//
//  Nestable.swift
//  Syntax

//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-16.
//
//  ---------------------------------------------------------------------------
//
//  © 2004-2007 nakamuxu
//  © 2014-2025 1024jp
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

enum NestableToken: Equatable, Hashable, Sendable {
    
    case inline(String)
    case pair(Pair<String>)
    
    
    init?(highlight: Syntax.Highlight) {
        
        guard
            !highlight.isRegularExpression,
            let pair = highlight.end.map({ Pair(highlight.begin, $0) }),
            Set(pair.begin) == Set(pair.end),
            pair.array.allSatisfy({ $0.rangeOfCharacter(from: .alphanumerics) == nil })  // symbol
        else { return nil }
        
        self = .pair(pair)
    }
}


struct NestableItem {
    
    var type: SyntaxType
    var token: NestableToken
    var role: Role
    var range: NSRange
    
    
    struct Role: OptionSet {
        
        var rawValue: Int
        
        static let begin = Self(rawValue: 1 << 0)
        static let end   = Self(rawValue: 1 << 1)
    }
}
