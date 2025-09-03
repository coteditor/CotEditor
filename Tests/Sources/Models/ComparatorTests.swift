//
//  ComparatorTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-09-03.
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
@testable import CotEditor

struct ComparatorTests {
    
    @Test func bool() {
        
        struct Item {
            
            var id: Int
            var value: Bool
        }
        
        let items = [
            Item(id: 0, value: false),
            Item(id: 1, value: true),
            Item(id: 2, value: true),
            Item(id: 3, value: false),
            Item(id: 4, value: true),
        ]
        
        #expect(items.sorted(using: KeyPathComparator(\.value, comparator: BoolComparator())).map(\.id) == [1, 2, 4, 0, 3])
        #expect(items.sorted(using: KeyPathComparator(\.value, comparator: BoolComparator(order: .forward))).map(\.id) == [1, 2, 4, 0, 3])
        #expect(items.sorted(using: KeyPathComparator(\.value, comparator: BoolComparator(order: .reverse))).map(\.id) == [0, 3, 1, 2, 4])
    }
}
