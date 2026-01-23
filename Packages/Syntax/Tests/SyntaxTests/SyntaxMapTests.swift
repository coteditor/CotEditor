//
//  SyntaxMapTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-02-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2020-2026 1024jp
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
import Foundation
@testable import Syntax

struct SyntaxMapTests {
    
    @Test func testMapLoad() throws {
        
        let urls = try #require(Bundle.module.urls(forResourcesWithExtension: "cotsyntax", subdirectory: "Syntaxes"))
        let maps = try Syntax.FileMap.load(at: urls)
        
        #expect(maps == [
            "Apache": Syntax.FileMap(extensions: ["conf"],
                                     filenames: [".htaccess"],
                                     interpreters: nil),
            "Python": Syntax.FileMap(extensions: ["py"],
                                     filenames: nil,
                                     interpreters: ["python", "python2", "python3"]),
        ])
    }
}
