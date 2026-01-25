//
//  BundledSyntaxTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-11.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2026 1024jp
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
import Syntax
import StringUtils
@testable import CotEditor

actor BundledSyntaxTests {
    
    private let syntaxes: [String: Syntax]
    
    
    init() throws {
        
        let urls = try #require(Bundle.main.urls(forResourcesWithExtension: "cotsyntax", subdirectory: "Syntaxes"))
        
        // load syntaxes
        self.syntaxes = try urls.reduce(into: [:]) { dict, url in
            let name = url.deletingPathExtension().lastPathComponent
            
            dict[name] = try Syntax(contentsOf: url)
        }
    }
    
    
    @Test func validateAllSyntaxes() {
        
        for (name, syntax) in self.syntaxes {
            let errors = syntax.validate()
            
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
                #expect(syntax.highlights[type] == sanitized.highlights[type],
                        ".\(type.rawValue) of “\(name)” is not sanitized in the latest manner")
            }
            
            #expect(syntax.outlines == sanitized.outlines,
                    ".outlines of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.completions == sanitized.completions,
                    ".completions of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.commentDelimiters == sanitized.commentDelimiters,
                    ".commentDelimiters of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.fileMap.extensions == sanitized.fileMap.extensions,
                    ".extensions of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.fileMap.filenames == sanitized.fileMap.filenames,
                    ".filenames of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.fileMap.interpreters == sanitized.fileMap.interpreters,
                    ".interpreters of “\(name)” is not sanitized in the latest manner")
            #expect(syntax.metadata == sanitized.metadata,
                    ".metadata of “\(name)” is not sanitized in the latest manner")
        }
    }
    
    
    @Test func xmlSyntax() throws {
        
        let syntax = try #require(self.syntaxes["HTML"])
        
        #expect(syntax.parser.hasRules)
        #expect(syntax.commentDelimiters.inlines.isEmpty)
        #expect(syntax.commentDelimiters.blocks == [Pair("<!--", "-->")])
    }
    
    
    @Test func parseOutline() async throws {
        
        let syntax = try #require(self.syntaxes["HTML"])
        
        // load test file
        let bundle = Bundle(for: type(of: self))
        let sourceURL = try #require(bundle.url(forResource: "sample", withExtension: "html"))
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        
        let outlineItems = try await syntax.parser.parseOutline(in: source)
        #expect(outlineItems.count == 3)
        
        let item = outlineItems[1]
        #expect(item.title == "   h2: 🐕 🐄")
        #expect(item.range.location == 354)
        #expect(item.range.length == 15)
        #expect(item.style.isEmpty)
    }
}
