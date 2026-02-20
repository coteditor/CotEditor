//
//  OutlineExtractorTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-01.
//
//  ---------------------------------------------------------------------------
//
//  © 2026 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Testing
import Foundation
import StringUtils
@testable import Syntax

struct OutlineExtractorTests {
    
    @Test func buildsRegexWithOptions() throws {
        
        let definition = Syntax.Outline(pattern: "^foo$", template: "$0", ignoreCase: true, kind: .heading)
        let extractor = try OutlineExtractor(definition: definition)
        
        let items = try extractor.items(in: "FOO\nfoo\n", range: NSRange(0..<7))
        
        #expect(items.count == 2)
        #expect(items.allSatisfy { $0.kind == .heading })
        #expect(items[0].title == "FOO")
        #expect(items[1].title == "foo")
    }
    
    
    @Test func templateReplacementAndWhitespaceNormalization() throws {
        
        let definition = Syntax.Outline(pattern: #"^(\s*\w+)\s+(\w+)\s*$"#, template: "$1   $2", kind: .function)
        let extractor = try OutlineExtractor(definition: definition)
        
        let source = """
                      alpha    beta
                       gamma\t\t delta
                     """
        let items = try extractor.items(in: source, range: source.nsRange)
        
        #expect(items.count == 2)
        #expect(items[0].title == "alpha beta")
        #expect(items[0].indent == .string(" "))
        #expect(items[1].title == "gamma delta")
        #expect(items[1].indent == .string("  "))
    }
    
    
    @Test func separatorKindProducesSeparatorItems() throws {
        
        let definition = Syntax.Outline(pattern: "^---+$", template: "", kind: .separator)
        let extractor = try OutlineExtractor(definition: definition)
        
        let source = """
                     ---
                     text
                     -----
                     """
        let items = try extractor.items(in: source, range: source.nsRange)
        
        #expect(items.count == 2)
        #expect(items[0].kind == .separator)
        #expect(items[1].kind == .separator)
    }
    
    
    @Test func emptyTemplateFallsBackToMatchedSubstring() throws {
        
        let definition = Syntax.Outline(pattern: #"^\s*TITLE: .+$"#, template: "", kind: .value)
        let extractor = try OutlineExtractor(definition: definition)
        
        let source = "  TITLE: Hello World\n"
        let items = try extractor.items(in: source, range: source.nsRange)
        
        #expect(items.count == 1)
        #expect(items[0].title == "TITLE: Hello World")
        #expect(items[0].indent == .string("  "))
        #expect(items[0].kind == .value)
    }
    
    
    /// Ensure that the template that could produce empty title should be filtered out.
    @Test func ignoresEmptyTitlesAfterTemplate() throws {
        
        let definition = Syntax.Outline(pattern: #"^\s*$"#, template: "$0", kind: .mark)
        let extractor = try OutlineExtractor(definition: definition)
        
        let source = "\n\n"
        let items = try extractor.items(in: source, range: source.nsRange)
        
        #expect(items.isEmpty)
    }
}
