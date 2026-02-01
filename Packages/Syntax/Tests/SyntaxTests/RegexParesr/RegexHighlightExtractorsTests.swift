//
//  RegexHighlightExtractorsTests.swift
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
import ValueRange
@testable import Syntax

struct RegexHighlightExtractorsTests {
    
    @Test func regularExpressionExtractor() throws {
        
        let definition = Syntax.Highlight(begin: #"\bfoo\w*\b"#, end: nil, isRegularExpression: true, ignoreCase: true)
        let extractor = try RegularExpressionExtractor(pattern: definition.begin, ignoresCase: true, isMultiline: false)
        
        #expect(try definition.extractor as? RegularExpressionExtractor == extractor)
        
        let source = "Foo food FOOX bar"
        let ranges = try extractor.ranges(in: source, range: source.nsRange)
        let matches = ranges.map((source as NSString).substring(with:))
        
        #expect(matches == ["Foo", "food", "FOOX"])
    }

    
    @Test func beginEndRegexExtractor() throws {
        
        let definition = Syntax.Highlight(begin: "(?=BEGIN)", end: "END", isRegularExpression: true, isMultiline: true)
        let extractor = try BeginEndRegularExpressionExtractor(beginPattern: "(?=BEGIN)", endPattern: "END", ignoresCase: false, isMultiline: true)
        
        #expect(try definition.extractor as? BeginEndRegularExpressionExtractor == extractor)
        
        let source = """
                     BEGINxEND
                     foo
                     BEGINEND
                     """
        let ranges = try extractor.ranges(in: source, range: source.nsRange)
        let matches = ranges.map((source as NSString).substring(with:))
        
        #expect(matches == ["BEGINxEND", "BEGINEND"])
    }

    
    @Test func beginEndStringExtractor() throws {
        
        let definition = Syntax.Highlight(begin: "/*", end: "*/")
        let extractor = BeginEndStringExtractor(begin: "/*", end: "*/", ignoresCase: false, isMultiline: false)
        
        #expect(try definition.extractor as? BeginEndStringExtractor == extractor)
        
        let source = """
                     /* a */
                     /* b
                     c */
                     """
        let ranges = try extractor.ranges(in: source, range: source.nsRange)
        let matches = ranges.map((source as NSString).substring(with:))
        
        #expect(matches == ["/* a */"])
    }

    
    @Test func beginEndStringExtractorMultiline() throws {
        
        let definition = Syntax.Highlight(begin: "/*", end: "*/", isMultiline: true)
        let extractor = try definition.extractor
        
        let source = """
                     /* a */
                     /* b
                      c */
                     """
        let ranges = try extractor.ranges(in: source, range: source.nsRange)
        let matches = ranges.map((source as NSString).substring(with:))
        
        #expect(matches == ["/* a */", "/* b\n c */"])
    }

    
    @Test func cancellation() async throws {
        
        let definition = Syntax.Highlight(begin: #"\w+"#, end: nil, isRegularExpression: true, isMultiline: true)
        let extractor = try definition.extractor
        
        let source = String(repeating: "a", count: 10_000)
        
        let task = Task<[NSRange], any Error> {
            try Task.checkCancellation()
            return try extractor.ranges(in: source, range: source.nsRange)
        }
        task.cancel()
        
        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }
    }
}
