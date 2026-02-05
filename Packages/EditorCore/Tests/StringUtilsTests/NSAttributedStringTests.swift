//
//  NSAttributedStringTests.swift
//  StringUtilsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-05-13.
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

import Foundation
import Testing
@testable import StringUtils

struct NSAttributedStringTests {
    
    @Test func add() throws {
        
        let foo = NSMutableAttributedString(string: "foo", attributes: [.test: "moof"])
        let bar = NSAttributedString(string: "bar", attributes: [:])
        let fooBar = foo + bar
        
        #expect(!(fooBar is NSMutableAttributedString))
        #expect(fooBar.string == "foobar")
        #expect(unsafe fooBar.attribute(.test, at: 1, effectiveRange: nil) as? String == "moof")
        #expect(unsafe fooBar.attribute(.test, at: 3, effectiveRange: nil) == nil)
    }
    
    
    @Test func addEqual() throws {
        
        var fooBar = NSAttributedString(string: "foo", attributes: [.test: "moof"])
        fooBar += NSAttributedString(string: "bar", attributes: [:])
        
        #expect(!(fooBar is NSMutableAttributedString))
        #expect(fooBar.string == "foobar")
        #expect(unsafe fooBar.attribute(.test, at: 1, effectiveRange: nil) as? String == "moof")
        #expect(unsafe fooBar.attribute(.test, at: 3, effectiveRange: nil) == nil)
    }
    
    
    @Test func truncate() throws {
        
        let string1 = NSMutableAttributedString(string: "0123456")
        string1.truncateHead(until: 5, offset: 2)
        #expect(string1.string == "…3456")
        
        let string2 = NSMutableAttributedString(string: "0123456")
        string2.truncateHead(until: 2, offset: 3)
        #expect(string2.string == "0123456")
        
        let string3 = NSMutableAttributedString(string: "🐱🐶🐮")
        string3.truncateHead(until: 4, offset: 1)
        #expect(string3.string == "…🐶🐮")
        
        let string4 = NSMutableAttributedString(string: "🐈‍⬛🐕🐄")
        string4.truncateHead(until: 4, offset: 1)
        #expect(string4.string == "🐈‍⬛🐕🐄")
        
        let string5 = NSMutableAttributedString(string: "🐈‍⬛🐕🐄")
        string5.truncateHead(until: 5, offset: 1)
        #expect(string5.string == "🐈‍⬛🐕🐄")
        
        let string6 = NSMutableAttributedString(string: "🐈‍⬛ab")
        string6.truncateHead(until: 5, offset: 1)
        #expect(string6.string == "…ab")
        
        let string7 = NSMutableAttributedString(string: "🐈‍⬛🐕🐄")
        string7.truncateHead(until: 6, offset: 1)
        #expect(string7.string == "…🐕🐄")
    }
    
    
    @Test func join() {
        
        let attrs: [NSAttributedString] = [
            NSMutableAttributedString(string: "foo", attributes: [.test: "moof"]),
            NSAttributedString(string: "bar"),
            NSAttributedString(string: "buz"),
        ]
        let space = NSAttributedString(string: " ", attributes: [.test: "space"])
        
        let joined = attrs.joined()
        #expect(!(joined is NSMutableAttributedString))
        #expect(joined.string == "foobarbuz")
        #expect(unsafe joined.attribute(.test, at: 1, effectiveRange: nil) as? String == "moof")
        #expect(unsafe joined.attribute(.test, at: 3, effectiveRange: nil) == nil)
        
        let spaceJoined = attrs.joined(separator: space)
        #expect(!(spaceJoined is NSMutableAttributedString))
        #expect(spaceJoined.string == "foo bar buz")
        #expect(unsafe spaceJoined.attribute(.test, at: 0, effectiveRange: nil) as? String == "moof")
        #expect(unsafe spaceJoined.attribute(.test, at: 3, effectiveRange: nil) as? String == "space")
        #expect(unsafe spaceJoined.attribute(.test, at: 4, effectiveRange: nil) == nil)
        
        let empty: [NSAttributedString] = []
        let emptyJoined = empty.joined(separator: space)
        #expect(!(emptyJoined is NSMutableAttributedString))
        #expect(emptyJoined.string.isEmpty)
        
        let single: [NSAttributedString] = [NSMutableAttributedString(string: "foo", attributes: [.test: "moof"])]
        let singleJoined = single.joined(separator: space)
        #expect(!(singleJoined is NSMutableAttributedString))
        #expect(singleJoined.string == "foo")
    }
    
    
    @Test func rangeAndMutable() {
        
        let string = NSAttributedString(string: "abc")
        #expect(string.range == NSRange(0..<3))
        
        let mutable = string.mutable
        mutable.append(NSAttributedString(string: "d"))
        #expect(mutable.string == "abcd")
    }
    
    
    @Test func enumerateAttribute() {
        
        let string = NSMutableAttributedString(string: "ababa")
        string.addAttribute(.test, value: "hit", range: NSRange(0..<2))
        string.addAttribute(.test, value: "hit", range: NSRange(3..<5))
        
        var ranges: [NSRange] = []
        unsafe string.enumerateAttribute(.test, type: String.self, in: string.range) { value, range, _ in
            ranges.append(range)
            #expect(value == "hit")
        }
        
        #expect(ranges == [NSRange(0..<2), NSRange(3..<5)])
    }
    
    
    @Test func longestEffectiveRange() {
        
        let string = NSMutableAttributedString(string: "ababa")
        string.addAttribute(.test, value: "hit", range: NSRange(1..<4))
        
        #expect(string.longestEffectiveRange(of: .test, at: 2) == NSRange(1..<4))
        #expect(string.longestEffectiveRange(of: .test, at: 0) == nil)
    }
    
    
    @Test func hasAttribute() {
        
        let string = NSMutableAttributedString(string: "ababa")
        string.addAttribute(.test, value: "hit", range: NSRange(1..<4))
        
        #expect(string.hasAttribute(.test))
        #expect(!string.hasAttribute(.test, in: NSRange(0..<1)))
        #expect(string.hasAttribute(.test, in: NSRange(2..<3)))
        
        let empty = NSAttributedString(string: "")
        #expect(!empty.hasAttribute(.test))
    }
    
    
    @Test func truncatedHead() {
        
        let original = NSAttributedString(string: "0123456")
        let truncated = original.truncatedHead(until: 5, offset: 2)
        
        #expect(truncated.string == "…3456")
        #expect(original.string == "0123456")
    }
    
    
    @Test func mutableAddEqual() {
        
        var string = NSMutableAttributedString(string: "foo")
        string += NSAttributedString(string: "bar", attributes: [.test: "test"])
        
        #expect(string.string == "foobar")
        #expect(unsafe string.attribute(.test, at: 1, effectiveRange: nil) == nil)
        #expect(unsafe string.attribute(.test, at: 5, effectiveRange: nil) as? String == "test")
    }
    
    
    @Test func joinWithStringSeparator() {
        
        let items: [NSAttributedString] = [
            NSAttributedString(string: "foo"),
            NSAttributedString(string: "bar", attributes: [.test: "test"]),
            NSAttributedString(string: "buz"),
        ]
        
        let joined = items.joined(separator: ",")
        #expect(joined.string == "foo,bar,buz")
    }
}


private extension NSAttributedString.Key {
    
    static let test = NSAttributedString.Key("test")
}
