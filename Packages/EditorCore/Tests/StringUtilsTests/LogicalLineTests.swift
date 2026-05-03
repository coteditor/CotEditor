//
//  LogicalLineTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-05-04.
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
@testable import StringUtils

struct LogicalLineTests {
    
    @Test func logicalLines() {
        
        let string = "b\r\na\nc"
        
        #expect(string.logicalLines(in: string.nsRange) == [
            LogicalLine(contents: "b", lineEnding: "\r\n"),
            LogicalLine(contents: "a", lineEnding: "\n"),
            LogicalLine(contents: "c", lineEnding: nil),
        ])
    }
    
    
    @Test func logicalLinesWithTrailingLineEnding() {
        
        let string = "b\r\na\n"
        
        #expect(string.logicalLines(in: string.nsRange) == [
            LogicalLine(contents: "b", lineEnding: "\r\n"),
            LogicalLine(contents: "a", lineEnding: "\n"),
        ])
        #expect(string.logicalLines(in: (string as NSString).lineContentsRange(for: string.nsRange)) == [
            LogicalLine(contents: "b", lineEnding: "\r\n"),
            LogicalLine(contents: "a", lineEnding: nil),
        ])
    }
    
    
    @Test func joinLogicalLines() {
        
        let lines = [
            LogicalLine(contents: "c", lineEnding: nil),
            LogicalLine(contents: "a", lineEnding: "\n"),
            LogicalLine(contents: "b", lineEnding: "\r\n"),
        ]
        
        #expect(lines.joined(baseLineEnding: "\r\n") == "c\r\na\nb")
        #expect(lines.joined(baseLineEnding: "\r\n", includingTrailingLineEnding: true) == "c\r\na\nb\r\n")
        
        let lastLineWithoutEnding = [
            LogicalLine(contents: "a", lineEnding: "\n"),
            LogicalLine(contents: "c", lineEnding: nil),
        ]
        
        #expect(lastLineWithoutEnding.joined(baseLineEnding: "\n", includingTrailingLineEnding: true) == "a\nc\n")
    }
}
