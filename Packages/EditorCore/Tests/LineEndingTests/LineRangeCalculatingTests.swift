//
//  LineRangeCalculatingTests.swift
//  LineEndingTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2024-07-13.
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
import StringBasics
import ValueRange
@testable import LineEnding

struct LineRangeCalculatingTests {
    
    @Test func lineNumber() {
        
        let calculator = Calculator(string: "dog \n\n cat \n cow \n")
        
        #expect(calculator.lineNumber(at: 0) == 1)
        #expect(calculator.lineNumber(at: 1) == 1)
        #expect(calculator.lineNumber(at: 4) == 1)
        #expect(calculator.lineNumber(at: 5) == 2)
        #expect(calculator.lineNumber(at: 6) == 3)
        #expect(calculator.lineNumber(at: 11) == 3)
        #expect(calculator.lineNumber(at: 12) == 4)
        #expect(calculator.lineNumber(at: 17) == 4)
        #expect(calculator.lineNumber(at: 18) == 5)
        
        for _ in 0..<10 {
            let string = String(" 🐶 \n 🐱 \n 🐮 \n".shuffled())
            let calculator = Calculator(string: string)
            
            for index in (0..<string.utf16.count).shuffled() {
                #expect(calculator.lineNumber(at: index) == string.lineNumber(at: index))
            }
        }
    }
}


private struct Calculator: LineRangeCalculating {
    
    let string: NSString
    let lineEndings: [ValueRange<LineEnding>]
    
    
    init(string: String) {
        
        self.string = string as NSString
        self.lineEndings = string.lineEndingRanges()
    }
}
