//
//  FormatStylesTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-12-18.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2026 1024jp
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

struct FormatStylesTests {
    
    @Test func formatCSV() throws {
        
        #expect(["dog", "cat"].formatted(.csv) == "dog, cat")
        #expect(["dog"].formatted(.csv) == "dog")
        #expect(["dog", "", "dog", ""].formatted(.csv) == "dog, , dog, ")
        #expect(["dog", "", "dog", ""].formatted(.csv(omittingEmptyItems: true)) == "dog, dog")
        
        let strategy = CSVFormatStyle().parseStrategy
        #expect(try strategy.parse("dog,  cat") == ["dog", "cat"])
        #expect(try strategy.parse(" a,b,c") == ["a", "b", "c"])
        #expect(try strategy.parse(" a, ,c") == ["a", "", "c"])
        #expect(try CSVFormatStyle(omittingEmptyItems: true).parseStrategy.parse(" a,,c") == ["a", "c"])
    }
}
