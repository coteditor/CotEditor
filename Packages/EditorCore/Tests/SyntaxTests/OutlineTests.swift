//
//  OutlineTests.swift
//  SyntaxTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-08-12.
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
@testable import Syntax

struct OutlineTests {
    
    private let items: [OutlineItem] = [
        OutlineItem(title: "dog", range: NSRange(location: 10, length: 5)),         // 0
        OutlineItem(title: .separator, range: NSRange(location: 20, length: 5)),
        OutlineItem(title: .separator, range: NSRange(location: 30, length: 5)),
        OutlineItem(title: "dogcow", range: NSRange(location: 40, length: 5)),      // 3
        OutlineItem(title: .separator, range: NSRange(location: 50, length: 5)),
        OutlineItem(title: "cow", range: NSRange(location: 60, length: 5)),         // 5
        OutlineItem(title: .separator, range: NSRange(location: 70, length: 5)),
    ]
    
    private let emptyItems: [OutlineItem] = []
    
    
    @Test func index() throws {
        
        #expect(self.emptyItems.item(at: 10) == nil)
        
        #expect(self.items.item(at: 9) == nil)
        #expect(self.items.item(at: 10) == self.items[0])
        #expect(self.items.item(at: 18) == self.items[0])
        #expect(self.items.item(at: 20) == self.items[0])
        #expect(self.items.item(at: 40) == self.items[3])
        #expect(self.items.item(at: 50) == self.items[3])
        #expect(self.items.item(at: 59) == self.items[3])
        #expect(self.items.item(at: 60) == self.items[5])
    }
    
    
    @Test func previousItem() throws {
        
        #expect(self.emptyItems.previousItem(for: NSRange(10..<20)) == nil)
        
        #expect(self.items.previousItem(for: NSRange(10..<20)) == nil)
        #expect(self.items.previousItem(for: NSRange(19..<19)) == nil)
        #expect(self.items.previousItem(for: NSRange(59..<70)) == items[0])
        #expect(self.items.previousItem(for: NSRange(60..<70)) == items[3])
    }
    
    
    @Test func nextItem() throws {
        
        #expect(self.emptyItems.nextItem(for: NSRange(10..<20)) == nil)
        
        #expect(self.items.nextItem(for: NSRange(0..<0)) == items[0])
        #expect(self.items.nextItem(for: NSRange(0..<10)) == items[3])
        #expect(self.items.nextItem(for: NSRange(40..<40)) == items[5])
        #expect(self.items.nextItem(for: NSRange(60..<60)) == nil)
        #expect(self.items.nextItem(for: NSRange(40..<61)) == nil)
    }
    
    
    @Test func filter() throws {
        
        #expect(self.items.compactMap { $0.filter("", keyPath: \.title) }.count == 7)
        #expect(self.items.compactMap { $0.filter("cat", keyPath: \.title) }.count == 0)
        #expect(self.items.compactMap { $0.filter("dog", keyPath: \.title) }.count == 2)
        #expect(self.items.compactMap { $0.filter("dow", keyPath: \.title) }.count == 1)
    }
}
