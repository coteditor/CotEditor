//
//  Syntax+Localization.swift
//  Syntax
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-03-02.
//
//  ---------------------------------------------------------------------------
//
//  © 2024-2026 1024jp
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

public import Foundation

public extension Syntax.Kind {
    
    var label: LocalizedStringResource {
        
        switch self {
            case .general:
                .init("Syntax.Kind.general.label",
                      defaultValue: "General",
                      bundle: .module)
            case .code:
                .init("Syntax.Kind.code.label",
                      defaultValue: "Code",
                      bundle: .module)
        }
    }
}


public extension SyntaxType {
    
    var label: LocalizedStringResource {
        
        switch self {
            case .keywords:
                .init("SyntaxType.keywords.label",
                      defaultValue: "Keywords",
                      bundle: .module)
            case .commands:
                .init("SyntaxType.commands.label",
                      defaultValue: "Commands",
                      bundle: .module)
            case .types:
                .init("SyntaxType.types.label",
                      defaultValue: "Types",
                      bundle: .module)
            case .attributes:
                .init("SyntaxType.attributes.label",
                      defaultValue: "Attributes",
                      bundle: .module)
            case .variables:
                .init("SyntaxType.variables.label",
                      defaultValue: "Variables",
                      bundle: .module)
            case .values:
                .init("SyntaxType.values.label",
                      defaultValue: "Values",
                      bundle: .module)
            case .numbers:
                .init("SyntaxType.numbers.label",
                      defaultValue: "Numbers",
                      bundle: .module)
            case .strings:
                .init("SyntaxType.strings.label",
                      defaultValue: "Strings",
                      bundle: .module)
            case .characters:
                .init("SyntaxType.characters.label",
                      defaultValue: "Characters",
                      bundle: .module)
            case .comments:
                .init("SyntaxType.comments.label",
                      defaultValue: "Comments",
                      bundle: .module)
        }
    }
}


public extension Syntax.Outline.Kind {
    
    var label: LocalizedStringResource {
        
        switch self {
            case .container:
                .init("Syntax.Outline.Kind.container.label",
                      defaultValue: "Container",
                      bundle: .module)
            case .value:
                .init("Syntax.Outline.Kind.value.label",
                      defaultValue: "Value",
                      bundle: .module)
            case .function:
                .init("Syntax.Outline.Kind.function.label",
                      defaultValue: "Function",
                      bundle: .module)
            case .title:
                .init("Syntax.Outline.Kind.title.label",
                      defaultValue: "Title",
                      bundle: .module)
            case .heading(let level?):
                .init("Syntax.Outline.Kind.heading.level.label",
                      defaultValue: "Heading \(level)",
                      bundle: .module)
            case .heading(nil):
                .init("Syntax.Outline.Kind.heading.label",
                      defaultValue: "Heading",
                      bundle: .module)
            case .mark:
                .init("Syntax.Outline.Kind.mark.label",
                      defaultValue: "Mark",
                      bundle: .module)
            case .separator:
                .init("Syntax.Outline.Kind.separator.label",
                      defaultValue: "Separator",
                      bundle: .module)
        }
    }
}
