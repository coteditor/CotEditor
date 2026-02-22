//
//  HighlightCategoryConstraintTests.swift
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
@testable import Syntax

struct HighlightQueriesTests {
    
    @Test(arguments: TreeSitterSyntax.allCases)
    func highlightsCaptureRootsAreAllowed(syntax: TreeSitterSyntax) throws {
        
        let highlightsURL = LanguageRegistry.shared.queriesURL(for: syntax)
            .appending(component: "highlights.scm")
        let lines = try String(contentsOf: highlightsURL, encoding: .utf8)
            .components(separatedBy: .newlines)
        
        let allowedRoots = Set(SyntaxType.allCases.map(\.rawValue))
        for (index, line) in lines.enumerated() {
            let code = line.prefix { $0 != ";" }
            
            for capture in Self.captures(in: code) {
                let root = capture.split(separator: ".", maxSplits: 1).first.map(String.init) ?? capture
                
                #expect(allowedRoots.contains(root), "\(highlightsURL.path):\(index + 1): @\(capture)")
            }
        }
    }
    
    
    @Test(arguments: TreeSitterSyntax.allCases)
    func highlightsSampleFiles(syntax: TreeSitterSyntax) async throws {
        
        let samplesDirectoryURL = try #require(Bundle.module.url(forResource: "Samples", withExtension: nil))
        let sampleURL = samplesDirectoryURL
            .appending(component: syntax.sampleFilename, directoryHint: .notDirectory)
        let source = try String(contentsOf: sampleURL, encoding: .utf8)
        
        let parser = try LanguageRegistry.shared.parser(syntax: syntax).parser
        let result = try #require(await parser.parseHighlights(in: source, range: NSRange(..<source.utf16.count)))
        
        #expect(result.highlights.count > 10)
    }
    
    
    // MARK: Private Methods
    
    /// Extracts highlight capture names while ignoring non-capture `@` in strings and identifiers.
    private static func captures(in line: Substring) -> [String] {
        
        line.matches(of: /(?:^|[^"A-Za-z0-9_])@([A-Za-z][A-Za-z0-9_.]*)/)
            .map { String($0.output.1) }
    }
}


private extension TreeSitterSyntax {
    
    var sampleFilename: String {
        
        switch self {
            case .bash: "test.sh"
            case .c: "test.c"
            case .css: "test.css"
            case .go: "test.go"
            case .html: "test.html"
            case .java: "test.java"
            case .javaScript: "test.js"
            case .makefile: "Makefile"
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
