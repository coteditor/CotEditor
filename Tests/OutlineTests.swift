//
//  OutlineTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-12.
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

final class OutlineTests: XCTestCase {

    private let items: [OutlineItem] = [
        OutlineItem(title: "a", range: NSRange(location: 10, length: 5)),         // 0
        OutlineItem(title: .separator, range: NSRange(location: 20, length: 5)),
        OutlineItem(title: .separator, range: NSRange(location: 30, length: 5)),
        OutlineItem(title: "b", range: NSRange(location: 40, length: 5)),         // 3
        OutlineItem(title: .separator, range: NSRange(location: 50, length: 5)),
        OutlineItem(title: "c", range: NSRange(location: 60, length: 5)),         // 5
        OutlineItem(title: .separator, range: NSRange(location: 70, length: 5)),
    ]
    
    private let emptyItems: [OutlineItem] = []
    
    
    
    func testIndex() throws {
        
        XCTAssertNil(self.emptyItems.indexOfItem(at: 10))
        
        XCTAssertNil(self.items.indexOfItem(at: 9))
        XCTAssertEqual(self.items.indexOfItem(at: 10), 0)
        XCTAssertEqual(self.items.indexOfItem(at: 18), 0)
        XCTAssertEqual(self.items.indexOfItem(at: 20), 0)
        XCTAssertEqual(self.items.indexOfItem(at: 40), 3)
        XCTAssertEqual(self.items.indexOfItem(at: 50), 3)
        XCTAssertEqual(self.items.indexOfItem(at: 59), 3)
        XCTAssertEqual(self.items.indexOfItem(at: 60), 5)
    }
    
    
    func testPreviousItem() throws {
        
        XCTAssertNil(self.emptyItems.previousItem(for: NSRange(10..<20)))
        
        XCTAssertNil(self.items.previousItem(for: NSRange(10..<20)))
        XCTAssertNil(self.items.previousItem(for: NSRange(19..<19)))
        XCTAssertEqual(self.items.previousItem(for: NSRange(59..<70)), items[0])
        XCTAssertEqual(self.items.previousItem(for: NSRange(60..<70)), items[3])
    }
    
    
    func testNextItem() throws {
        
        XCTAssertNil(self.emptyItems.nextItem(for: NSRange(10..<20)))
        
        XCTAssertEqual(self.items.nextItem(for: NSRange(0..<0)), items[0])
        XCTAssertEqual(self.items.nextItem(for: NSRange(0..<10)), items[3])
        XCTAssertEqual(self.items.nextItem(for: NSRange(40..<40)), items[5])
        XCTAssertNil(self.items.nextItem(for: NSRange(60..<60)))
        XCTAssertNil(self.items.nextItem(for: NSRange(40..<61)))
    }

}
