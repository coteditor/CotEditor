//
//  NSAttributedStringTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-05-13.
//
//  ---------------------------------------------------------------------------
//
//  © 2020 1024jp
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

import XCTest
@testable import CotEditor

final class NSAttributedStringTests: XCTestCase {
    
    func testAddition() throws {
        
        let foo = NSMutableAttributedString(string: "foo", attributes: [.toolTip: "moof"])
        let bar = NSAttributedString(string: "bar", attributes: [:])
        let fooBar = foo + bar
        
        XCTAssertFalse(fooBar is NSMutableAttributedString)
        XCTAssertEqual(fooBar.string, "foobar")
        XCTAssertEqual(fooBar.attribute(.toolTip, at: 1, effectiveRange: nil) as? String, "moof")
        XCTAssertNil(fooBar.attribute(.toolTip, at: 3, effectiveRange: nil))
    }
    
    
    func testAdditionEqual() throws {
        
        var fooBar = NSAttributedString(string: "foo", attributes: [.toolTip: "moof"])
        fooBar += NSAttributedString(string: "bar", attributes: [:])
        
        XCTAssertFalse(fooBar is NSMutableAttributedString)
        XCTAssertEqual(fooBar.string, "foobar")
        XCTAssertEqual(fooBar.attribute(.toolTip, at: 1, effectiveRange: nil) as? String, "moof")
        XCTAssertNil(fooBar.attribute(.toolTip, at: 3, effectiveRange: nil))
    }
    
    
    func testJoin() {
        
        let attrs: [NSAttributedString] = [
            NSMutableAttributedString(string: "foo", attributes: [.toolTip: "moof"]),
            NSAttributedString(string: "bar"),
            NSAttributedString(string: "buz"),
        ]
        let space = NSAttributedString(string: " ", attributes: [.toolTip: "space"])
        
        let joined = attrs.joined()
        XCTAssertFalse(joined is NSMutableAttributedString)
        XCTAssertEqual(joined.string, "foobarbuz")
        XCTAssertEqual(joined.attribute(.toolTip, at: 1, effectiveRange: nil) as? String, "moof")
        XCTAssertNil(joined.attribute(.toolTip, at: 3, effectiveRange: nil))
        
        let spaceJoined = attrs.joined(separator: space)
        XCTAssertFalse(spaceJoined is NSMutableAttributedString)
        XCTAssertEqual(spaceJoined.string, "foo bar buz")
        XCTAssertEqual(spaceJoined.attribute(.toolTip, at: 0, effectiveRange: nil) as? String, "moof")
        XCTAssertEqual(spaceJoined.attribute(.toolTip, at: 3, effectiveRange: nil) as? String, "space")
        XCTAssertNil(spaceJoined.attribute(.toolTip, at: 4, effectiveRange: nil))
        
        let empty: [NSAttributedString] = []
        let emptyJoined = empty.joined(separator: space)
        XCTAssertFalse(emptyJoined is NSMutableAttributedString)
        XCTAssertEqual(emptyJoined.string, "")
        
        let single: [NSAttributedString] = [NSMutableAttributedString(string: "foo", attributes: [.toolTip: "moof"])]
        let singleJoined = single.joined(separator: space)
        XCTAssertFalse(singleJoined is NSMutableAttributedString)
        XCTAssertEqual(singleJoined.string, "foo")
    }
    
}
