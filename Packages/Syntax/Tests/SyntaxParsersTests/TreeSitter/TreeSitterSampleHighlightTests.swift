//
//  TreeSitterSampleHighlightTests.swift
//  SyntaxParsersTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-03-25.
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

struct TreeSitterSampleHighlightTests {
    
    private let registry: LanguageRegistry = .shared
    
    
    @Test(arguments: TreeSitterSyntax.allCases)
    func highlightsSampleFiles(syntax: TreeSitterSyntax) async throws {
        
        guard syntax.features.contains(.highlight) else { return }
        
        let sampleURL = try self.sampleURL(for: syntax)
        let source = try String(contentsOf: sampleURL, encoding: .utf8)
        let config = try self.registry.configuration(for: syntax)
        let client = try TreeSitterClient(languageConfig: config, languageProvider: self.registry.languageProvider, syntax: syntax)
        let result = try #require(await client.parseHighlights(in: source, range: NSRange(location: 0, length: source.utf16.count)))
        
        #expect(result.highlights.count > 10)
    }
    
    
    // MARK: Private Methods
    
    private func sampleURL(for syntax: TreeSitterSyntax) throws -> URL {
        
        guard let samplesURL = Bundle.module.url(forResource: "Samples", withExtension: nil) else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        
        return samplesURL.appending(component: self.sampleFilename(for: syntax), directoryHint: .notDirectory)
    }
    
    
    private func sampleFilename(for syntax: TreeSitterSyntax) -> String {
        
        switch syntax {
            case .bash: "test.sh"
            case .c: "test.c"
            case .cpp: "test.cpp"
            case .cSharp: "test.cs"
            case .css: "test.css"
            case .go: "test.go"
            case .html: "test.html"
            case .java: "test.java"
            case .javaScript: "test.js"
            case .kotlin: "test.kt"
            case .latex: "test.tex"
            case .lua: "test.lua"
            case .makefile: "Makefile"
            case .markdown: "test.md"
            case .php: "test.php"
            case .python: "test.py"
            case .ruby: "test.rb"
            case .rust: "test.rs"
            case .scala: "test.scala"
            case .sql: "test.sql"
            case .swift: "test.swift"
            case .typeScript: "test.ts"
        }
    }
}
