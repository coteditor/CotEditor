//
//  Syntax+Localization.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-03-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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

extension Syntax.Kind {
    
    var label: String {
        
        switch self {
            case .general:
                String(localized: "Syntax.Kind.general.label",
                       defaultValue: "General",
                       table: "Syntax",
                       comment: "syntax kind")
            case .code:
                String(localized: "Syntax.Kind.code.label",
                       defaultValue: "Code",
                       table: "Syntax",
                       comment: "syntax kind")
        }
    }
}


extension SyntaxType {
    
    var label: String {
        
        switch self {
            case .keywords:
                String(localized: "SyntaxType.keywords.label",
                       defaultValue: "Keywords",
                       table: "Syntax")
            case .commands:
                String(localized: "SyntaxType.commands.label",
                       defaultValue: "Commands",
                       table: "Syntax")
            case .types:
                String(localized: "SyntaxType.types.label",
                       defaultValue: "Types",
                       table: "Syntax")
            case .attributes:
                String(localized: "SyntaxType.attributes.label",
                       defaultValue: "Attributes",
                       table: "Syntax")
            case .variables:
                String(localized: "SyntaxType.variables.label",
                       defaultValue: "Variables",
                       table: "Syntax")
            case .values:
                String(localized: "SyntaxType.values.label",
                       defaultValue: "Values",
                       table: "Syntax")
            case .numbers:
                String(localized: "SyntaxType.numbers.label",
                       defaultValue: "Numbers",
                       table: "Syntax")
            case .strings:
                String(localized: "SyntaxType.strings.label",
                       defaultValue: "Strings",
                       table: "Syntax")
            case .characters:
                String(localized: "SyntaxType.characters.label",
                       defaultValue: "Characters",
                       table: "Syntax")
            case .comments:
                String(localized: "SyntaxType.comments.label",
                       defaultValue: "Comments",
                       table: "Syntax")
        }
    }
}
