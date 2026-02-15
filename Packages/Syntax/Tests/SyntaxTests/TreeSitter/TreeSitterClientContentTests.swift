//
//  TreeSitterClientContentTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-11.
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
import SwiftTreeSitter
@testable import Syntax

struct TreeSitterClientContentTests {
    
    @Test func resetRebuildsLineStarts() {
        
        var content = TreeSitterClient.Content("a\nb")
        
        content.reset("ab\ncd")
        
        #expect(content.string == "ab\ncd")
        #expect(content.lineStarts == IndexSet([0, 3]))
    }
    
    
    @Test func applyEditReplacesTextAndUpdatesLineStarts() throws {
        
        var content = TreeSitterClient.Content("abc\ndef")
        
        let edit = try content.applyEdit(editedRange: NSRange(location: 2, length: 3),
                                         delta: 2,
                                         insertedText: "XYZ")
        
        #expect(content.string == "abXYZ\ndef")
        #expect(content.lineStarts == IndexSet([0, 6]))
        
        #expect(edit.startByte == 4)
        #expect(edit.oldEndByte == 6)
        #expect(edit.newEndByte == 10)
        #expect(edit.startPoint.row == 0)
        #expect(edit.startPoint.column == 2)
        #expect(edit.oldEndPoint.row == 0)
        #expect(edit.oldEndPoint.column == 3)
        #expect(edit.newEndPoint.row == 0)
        #expect(edit.newEndPoint.column == 5)
    }
    
    
    @Test func applyEditDeletesNewlineAndMergesLines() throws {
        
        var content = TreeSitterClient.Content("ab\ncd")
        
        let edit = try content.applyEdit(editedRange: NSRange(location: 2, length: 0),
                                         delta: -1,
                                         insertedText: "")
        
        #expect(content.string == "abcd")
        #expect(content.lineStarts == IndexSet([0]))
        
        #expect(edit.startByte == 4)
        #expect(edit.oldEndByte == 6)
        #expect(edit.newEndByte == 4)
        #expect(edit.startPoint.row == 0)
        #expect(edit.startPoint.column == 2)
        #expect(edit.oldEndPoint.row == 1)
        #expect(edit.oldEndPoint.column == 0)
        #expect(edit.newEndPoint.row == 0)
        #expect(edit.newEndPoint.column == 2)
    }
    
    
    @Test func applyEditThrowsForMismatchedRange() {
        
        var content = TreeSitterClient.Content("abc")
        
        #expect(throws: TreeSitterClient.Content.InputEditError.invalidRange) {
            try content.applyEdit(editedRange: NSRange(location: 1, length: 1),
                                  delta: 0,
                                  insertedText: "xx")
        }
    }
    
    
    @Test func applyEditThrowsForOutOfBoundsRange() {
        
        var content = TreeSitterClient.Content("abc")
        
        #expect(throws: TreeSitterClient.Content.InputEditError.invalidRange) {
            try content.applyEdit(editedRange: NSRange(location: 5, length: 0),
                                  delta: 0,
                                  insertedText: "")
        }
    }
}
