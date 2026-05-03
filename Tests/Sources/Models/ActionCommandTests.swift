//
//  ActionCommandTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-03.
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

import AppKit
import Testing

@testable import CotEditor

struct ActionCommandTests {
    
    private let command = ActionCommand(kind: .command,
                                        title: "Swift",
                                        paths: ["Format", "Syntax"],
                                        action: #selector(NSResponder.yank))
    
    
    @Test(arguments: ["syntaxswift", "syntax swift", "syntax  swift"])
    func matchMenuPathComponents(_ query: String) throws {
        
        let match = try #require(self.command.match(command: query))
        
        #expect(match.result.map(\.string) == ["Syntax", "Swift"])
    }
    
    
    @Test func matchWhitespaceOnlyCommand() {
        
        #expect(self.command.match(command: " ") == nil)
    }
}
