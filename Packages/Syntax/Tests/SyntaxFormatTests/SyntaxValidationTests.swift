//
//  SyntaxValidationTests.swift
//  SyntaxFormatTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
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

import Testing
import StringUtils
@testable import SyntaxFormat

struct SyntaxValidationTests {
    
    @Test func highlightValidation() {
        
        let duplicate = Syntax.Highlight(begin: "abc")
        let syntax = Syntax(
            highlights: [
                .keywords: [
                    duplicate,
                    duplicate,
                    .init(begin: "(", isRegularExpression: true),
                    .init(begin: "a", end: "(", isRegularExpression: true),
                ],
            ],
            outlines: [],
            commentDelimiters: .init()
        )
        
        let errors = syntax.validate()
        
        #expect(errors.contains { $0.code == .duplicated && $0.scope == .highlight(.keywords) && $0.value == "abc" })
        #expect(errors.contains { $0.code == .regularExpression && $0.scope == .highlight(.keywords) && $0.value == "(" })
    }
    
    
    @Test func outlineAndBlockCommentValidation() {
        
        let syntax = Syntax(
            outlines: [
                .init(pattern: "(", template: "t"),
            ],
            commentDelimiters: .init(
                blocks: [
                    .init(begin: "", end: "*/"),
                    .init(begin: "/*", end: ""),
                ]
            )
        )
        
        let errors = syntax.validate()
        
        #expect(errors.contains { $0.code == .regularExpression && $0.scope == .outline && $0.value == "(" })
        #expect(errors.contains { $0.code == .blockComment && $0.scope == .blockComment && $0.value == "*/" })
        #expect(errors.contains { $0.code == .blockComment && $0.scope == .blockComment && $0.value == "/*" })
    }
    
    
    @Test func nestableBlockCommentValidation() {
        
        let syntax = Syntax(
            commentDelimiters: .init(
                blocks: [
                    .init(begin: "%%", end: "%%", isNestable: true),
                    .init(begin: "##", end: "##", isNestable: false),
                ]
            )
        )
        
        let errors = syntax.validate()
        
        #expect(errors.contains { $0.code == .nestableBlockComment && $0.scope == .blockComment && $0.value == "%%" })
        #expect(!errors.contains { $0.code == .nestableBlockComment && $0.value == "##" })
    }
    
    
    @Test func invalidEscapeCharacterValidation() {
        
        let syntax = Syntax(
            stringDelimiters: [
                .init(begin: "'", end: "'", escapeCharacter: "'"),      // valid (single UTF-16)
                .init(begin: "\"", end: "\"", escapeCharacter: "\\"),   // valid (single UTF-16)
                .init(begin: "\"", end: "\"", escapeCharacter: "🐕"),   // invalid (surrogate pair)
            ],
            characterDelimiters: [
                .init(begin: "'", end: "'", escapeCharacter: "`"),      // valid
            ]
        )
        
        let errors = syntax.validate()
        
        #expect(!errors.contains { $0.code == .invalidEscapeCharacter && $0.value == "'" })
        #expect(!errors.contains { $0.code == .invalidEscapeCharacter && $0.value == "\\" })
        #expect(errors.contains { $0.code == .invalidEscapeCharacter && $0.scope == .stringDelimiter && $0.value == "🐕" })
        #expect(!errors.contains { $0.code == .invalidEscapeCharacter && $0.scope == .characterDelimiter })
    }
}
