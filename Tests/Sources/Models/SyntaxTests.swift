//
//  SyntaxTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2024 1024jp
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
import Yams
import Syntax
import StringUtils
@testable import CotEditor

actor SyntaxTests {
    
    private var syntaxes: [String: Syntax] = [:]
    
    
    init() throws {
        
        let urls = try #require(Bundle.main.urls(forResourcesWithExtension: "yml", subdirectory: "Syntaxes"))
        
        // load syntaxes
        let decoder = YAMLDecoder()
        self.syntaxes = try urls.reduce(into: [:]) { (dict, url) in
            let data = try Data(contentsOf: url)
            let name = url.deletingPathExtension().lastPathComponent
            
            dict[name] = try decoder.decode(Syntax.self, from: data)
        }
    }
    
    
    @Test func validateAllSyntaxes() {
        
        for (name, syntax) in self.syntaxes {
            let model = SyntaxObject(value: syntax)
            let errors = model.validate()
            
            #expect(errors.isEmpty)
            for error in errors {
                Issue.record("\(name): \(error)")
            }
        }
    }
    
    
    @Test func sanitize() {
        
        for (name, syntax) in self.syntaxes {
            let sanitized = syntax.sanitized
            
            #expect(syntax.kind == sanitized.kind)
            
            for type in SyntaxType.allCases {
                let keyPath = Syntax.highlightKeyPath(for: type)
                #expect(syntax[keyPath: keyPath] == sanitized[keyPath: keyPath],
                        ".\(type.rawValue) of “\(name)” is not sanitized in the latest manner")
            }
            
            #expect(syntax.outlines == sanitized.outlines,
                    ".outlines of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.completions == sanitized.completions,
                    ".completions of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.commentDelimiters == sanitized.commentDelimiters,
                    ".commentDelimiters of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.extensions == sanitized.extensions,
                    ".extensions of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.filenames == sanitized.filenames,
                    ".filenames of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.interpreters == sanitized.interpreters,
                    ".interpreters of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.metadata == sanitized.metadata,
                    ".metadata of “\(name)” is not sanitized in the latest manner")
        }
    }
    
    
    @Test func xmlSyntax() throws {
        
        let syntax = try #require(self.syntaxes["HTML"])
        
        #expect(!syntax.highlightParser.isEmpty)
        #expect(syntax.commentDelimiters.inline == nil)
        #expect(syntax.commentDelimiters.block == Pair("<!--", "-->"))
    }
    
    
    @Test func parseOutline() async throws {
        
        let syntax = try #require(self.syntaxes["HTML"])
        
        // load test file
        let bundle = Bundle(for: type(of: self))
        let sourceURL = try #require(bundle.url(forResource: "sample", withExtension: "html"))
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        
        let outlineItems = try syntax.outlineExtractors
            .flatMap { try $0.items(in: source, range: source.range) }
            .sorted(using: SortDescriptor(\.range.location))
        
        
        #expect(outlineItems.count == 3)
        
        let item = outlineItems[1]
        #expect(item.title == "   h2: 🐕 🐄")
        #expect(item.range.location == 354)
        #expect(item.range.length == 15)
        #expect(item.style.isEmpty)
    }
    
    
    @Test func viewModelHighlightEquality() {
        
        let termA = SyntaxObject.Highlight(begin: "abc", end: "def")
        let termB = SyntaxObject.Highlight(begin: "abc", end: "def")
        let termC = SyntaxObject.Highlight(begin: "abc")
        
        #expect(termA == termB)
        #expect(termA != termC)
        #expect(termA.id != termB.id)
    }
}
