//
//  LegacyYAMLTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-28.
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

struct LegacyYAMLTests {
    
    @Test func legacyYAMLHighlightAndOutlineDecoding() throws {
        
        let yaml = """
            kind: code
            keywords:
              - beginString: foo
                endString: bar
                regularExpression: true
            outlineMenu:
              - beginString: '^func\\s+(.+)'
                keyString: '$1'
            """
        
        let syntax = try Syntax(yamlData: Data(yaml.utf8))
        
        #expect(syntax.kind == .code)
        #expect(syntax.highlights[.keywords] == [.init(begin: "foo", end: "bar", isRegularExpression: true)])
        #expect(syntax.outlines == [.init(pattern: "^func\\s+(.+)", template: "$1")])
    }
}
