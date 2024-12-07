//
//  LineEndingScannerTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2022-04-08.
//
//  ---------------------------------------------------------------------------
//
//  © 2022-2024 1024jp
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

import AppKit.NSTextStorage
import Testing
import ValueRange
@testable import CotEditor

struct LineEndingScannerTests {
    
    @Test func scan() {
        
        let storage = NSTextStorage(string: "dog\ncat\r\ncow")
        let scanner = LineEndingScanner(textStorage: storage, lineEnding: .lf)
        
        storage.replaceCharacters(in: NSRange(0..<3), with: "dog\u{85}cow")
        
        // test line ending scan
        #expect(scanner.inconsistentLineEndings ==
                [ValueRange(value: .nel, range: NSRange(location: 3, length: 1)),
                 ValueRange(value: .crlf, range: NSRange(location: 11, length: 2))])
    }
    
    
    @Test func empty() {
        
        let storage = NSTextStorage(string: "\r")
        let scanner = LineEndingScanner(textStorage: storage, lineEnding: .lf)
        
        #expect(scanner.inconsistentLineEndings == [ValueRange(value: .cr, range: NSRange(location: 0, length: 1))])
        
        // test scanRange does not expand to the out of range
        storage.replaceCharacters(in: NSRange(0..<1), with: "")
        
        // test line ending scan
        #expect(scanner.inconsistentLineEndings.isEmpty)
    }
    
    
    @Test func editCRLF() {
        
        let storage = NSTextStorage(string: "dog\ncat\r\ncow")
        let scanner = LineEndingScanner(textStorage: storage, lineEnding: .lf)
        
        // add \r before \n (LF -> CRLF)
        storage.replaceCharacters(in: NSRange(3..<3), with: "\r")
        // remove \n after \r (CRLF -> CR)
        storage.replaceCharacters(in: NSRange(9..<10), with: "")
        
        // test line ending scan
        #expect(scanner.inconsistentLineEndings ==
                [ValueRange(value: .crlf, range: NSRange(location: 3, length: 2)),
                 ValueRange(value: .cr, range: NSRange(location: 8, length: 1))])
    }
}


extension NSTextStorage {
    
    open override var string: String {
        
        get { super.string }
        set { self.replaceCharacters(in: self.range, with: newValue) }
    }
}
