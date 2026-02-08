//
//  SyntaxSanitizationTests.swift
//  SyntaxTests
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
@testable import Syntax

struct SyntaxSanitizationTests {
    
    @Test func sanitizedRemovesEmptyAndSorts() {
        
        let syntax = Syntax(
            fileMap: .init(extensions: ["", "b", "A"],
                           filenames: ["", "foo"],
                           interpreters: ["", "zsh", "bash"]),
            highlights: [
                .keywords: [
                    .init(),
                    .init(begin: "beta"),
                    .init(begin: "Alpha"),
                ],
            ],
            outlines: [
                .init(),
                .init(pattern: "b", template: "t"),
                .init(pattern: "A", template: "t"),
            ],
            commentDelimiters: .init(
                inlines: [
                    .init(),
                    .init(begin: "//"),
                ],
                blocks: [
                    Pair("", "*/"),
                    Pair("/*", ""),
                    Pair("/*", "*/"),
                ]
            ),
            completions: [
                .init(),
                .init(text: "Zoo", type: .keywords),
                .init(text: "apple", type: .keywords),
            ]
        )
        
        let sanitized = syntax.sanitized
        
        #expect(sanitized.fileMap.extensions == ["b", "A"])
        #expect(sanitized.fileMap.filenames == ["foo"])
        #expect(sanitized.fileMap.interpreters == ["zsh", "bash"])
        
        let keywordHighlights = sanitized.highlights[.keywords]
        #expect(keywordHighlights?.map(\.begin) == ["Alpha", "beta"])
        
        #expect(sanitized.outlines.map(\.pattern) == ["A", "b"])
        
        #expect(sanitized.commentDelimiters.inlines.map(\.begin) == ["//"])
        #expect(sanitized.commentDelimiters.blocks == [Pair("/*", "*/")])
        
        #expect(sanitized.completions.map(\.text) == ["apple", "Zoo"])
    }
    
    
    @Test func completionWordsFallback() {
        
        let syntax = Syntax(
            highlights: [
                .keywords: [
                    .init(begin: " apple "),
                    .init(begin: "regex", isRegularExpression: true),
                    .init(begin: "pair", end: "end"),
                ],
                .values: [
                    .init(begin: "beta"),
                ],
            ],
            completions: []
        )
        
        #expect(syntax.completionWords.map(\.text) == ["apple", "beta"])
        #expect(syntax.completionWords.map(\.type) == [.keywords, .values])
    }
    
    
    @Test func completionWordsPreferExplicitList() {
        
        let syntax = Syntax(
            highlights: [
                .keywords: [.init(begin: "keyword")],
            ],
            completions: [
                .init(text: "explicit", type: .keywords),
                .init(text: ""),
            ]
        )
        
        #expect(syntax.completionWords.map(\.text) == ["explicit"])
    }
}
