//
//  TreeSitterOutlineFormatterTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-16.
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

import Foundation
import Testing
import SyntaxFormat
@testable import SyntaxParsers

struct TreeSitterOutlineFormatterTests {
    
    @Test func formatCSS() {
        
        #expect(CSSOutlineFormatter.formatTitle("@media (prefers-color-scheme: dark) { .item { color: white; } }", kind: .container) == "@media (prefers-color-scheme: dark)")
        #expect(CSSOutlineFormatter.formatTitle("@layer utilities { .m-1 { margin: 1rem; } }", kind: .container) == "@layer utilities")
        #expect(CSSOutlineFormatter.formatTitle("@import url(\"theme.css\");", kind: .container) == "@import url(\"theme.css\")")
        #expect(CSSOutlineFormatter.formatTitle("@supports  ( display: grid )\n{ .item { display: grid; } }", kind: .container) == "@supports ( display: grid )")
        #expect(CSSOutlineFormatter.formatTitle("   ;", kind: .container) == nil)
    }
    
    
    @Test func formatMarkdown() {
        
        #expect(MarkdownOutlineFormatter.formatTitle("Setext H1\n========", kind: .heading(nil)) == "Setext H1")
        #expect(MarkdownOutlineFormatter.formatTitle("Setext H2\n--------", kind: .heading(nil)) == "Setext H2")
        #expect(MarkdownOutlineFormatter.formatTitle("ATX H1", kind: .heading(nil)) == "ATX H1")
        #expect(MarkdownOutlineFormatter.formatTitle("### ATX Closed ###", kind: .heading(nil)) == "ATX Closed")
        #expect(MarkdownOutlineFormatter.formatTitle("###   ", kind: .heading(nil)) == nil)
    }
    
    
    @Test func formatSwiftMarks() {
        
        #expect(SwiftOutlineFormatter.formatTitle("SomeFunction", kind: .function) == "SomeFunction")
        #expect(SwiftOutlineFormatter.formatTitle("// MARK: Swift", kind: .mark) == "Swift")
        #expect(SwiftOutlineFormatter.formatTitle("// MARK: - Swift", kind: .mark) == "Swift")
        #expect(SwiftOutlineFormatter.formatTitle("/* MARK: Swift */", kind: .mark) == "Swift")
        #expect(SwiftOutlineFormatter.formatTitle("// MARK:", kind: .mark) == nil)
    }
}
