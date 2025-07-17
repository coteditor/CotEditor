//
//  MultipleReplaceTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2015-07-17.
//
//  ---------------------------------------------------------------------------
//
//  © 2025 1024jp
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
@testable import TextFind

struct MultipleReplaceTests {
    
    @Test func isEmptyReplace() {
        
        #expect(MultipleReplace().isEmpty)
        #expect(MultipleReplace(replacements: [.init()]).isEmpty)
        #expect(MultipleReplace(replacements: [.init(), .init()]).isEmpty)
        #expect(MultipleReplace(replacements: [.init(findString: "a")]).isEmpty == false)
    }
    
    
    @Test func isEmptyReplacement() {
        
        #expect(MultipleReplace.Replacement().isEmpty)
        #expect(MultipleReplace.Replacement(findString: "a").isEmpty == false)
        #expect(MultipleReplace.Replacement(description: "a").isEmpty == false)
    }
}
