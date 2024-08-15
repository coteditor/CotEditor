//
//  ComparableTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-05-25.
//
//  ---------------------------------------------------------------------------
//
//  © 2024 1024jp
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
@testable import CotEditor

struct ComparableTests {
    
    @Test func clamp() {
        
        #expect((-2).clamped(to: -10...10) == -2)
        #expect(5.clamped(to: 6...10) == 6)
        #expect(20.clamped(to: 6...10) == 10)
    }
    
    
    @Test func compareBool() {
        
        #expect([false, true, false, true, false].sorted() == [true, true, false, false, false])
    }
    
    
    @Test func compareBoolItem() {
        
        struct Item: Equatable {
            
            var id: Int
            var bool: Bool
        }
        
        let items = [
            Item(id: 0, bool: false),
            Item(id: 1, bool: true),
            Item(id: 2, bool: true),
            Item(id: 3, bool: false),
            Item(id: 4, bool: true),
        ]
        
        #expect(items.sorted(using: [KeyPathComparator(\.bool)]) == [
            Item(id: 1, bool: true),
            Item(id: 2, bool: true),
            Item(id: 4, bool: true),
            Item(id: 0, bool: false),
            Item(id: 3, bool: false),
        ])
    }
}
