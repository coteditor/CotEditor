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
//  © 2020-2024 1024jp
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
        #expect(fooBar.attribute(.test, at: 1, effectiveRange: nil) as? String == "moof")
        #expect(fooBar.attribute(.test, at: 3, effectiveRange: nil) == nil)
    }
    
    
    @Test func addEqual() throws {
        
        var fooBar = NSAttributedString(string: "foo", attributes: [.test: "moof"])
        fooBar += NSAttributedString(string: "bar", attributes: [:])
        
        #expect(!(fooBar is NSMutableAttributedString))
        #expect(fooBar.string == "foobar")
        #expect(fooBar.attribute(.test, at: 1, effectiveRange: nil) as? String == "moof")
        #expect(fooBar.attribute(.test, at: 3, effectiveRange: nil) == nil)
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
        #expect(joined.attribute(.test, at: 1, effectiveRange: nil) as? String == "moof")
        #expect(joined.attribute(.test, at: 3, effectiveRange: nil) == nil)
        
        let spaceJoined = attrs.joined(separator: space)
        #expect(!(spaceJoined is NSMutableAttributedString))
        #expect(spaceJoined.string == "foo bar buz")
        #expect(spaceJoined.attribute(.test, at: 0, effectiveRange: nil) as? String == "moof")
        #expect(spaceJoined.attribute(.test, at: 3, effectiveRange: nil) as? String == "space")
        #expect(spaceJoined.attribute(.test, at: 4, effectiveRange: nil) == nil)
        
        let empty: [NSAttributedString] = []
        let emptyJoined = empty.joined(separator: space)
        #expect(!(emptyJoined is NSMutableAttributedString))
        #expect(emptyJoined.string.isEmpty)
        
        let single: [NSAttributedString] = [NSMutableAttributedString(string: "foo", attributes: [.test: "moof"])]
        let singleJoined = single.joined(separator: space)
        #expect(!(singleJoined is NSMutableAttributedString))
        #expect(singleJoined.string == "foo")
    }
}


private extension NSAttributedString.Key {
    
    static let test = NSAttributedString.Key("test")
}
