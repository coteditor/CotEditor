//
//  IdentifiableCollectionTests.swift
//  SyntaxTests
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

import Testing
@testable import Syntax

struct IdentifiableCollectionTests {
    
    @Test func removingDuplicateIDsKeepsFirstOccurrence() {
        
        struct TestItem: Identifiable, Equatable {
            
            var id: Int
            var value: String
        }
        
        let items: [TestItem] = [
            TestItem(id: 1, value: "a"),
            TestItem(id: 1, value: "b"),
            TestItem(id: 2, value: "c"),
            TestItem(id: 3, value: "d"),
            TestItem(id: 3, value: "e"),
        ]
        
        #expect(items.removingDuplicateIDs == [
            TestItem(id: 1, value: "a"),
            TestItem(id: 2, value: "c"),
            TestItem(id: 3, value: "d"),
        ])
    }
}
