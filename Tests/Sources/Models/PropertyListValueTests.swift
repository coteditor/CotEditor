//
//  PropertyListValueTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2025-11-09.
//
//  ---------------------------------------------------------------------------
//
//  © 2025-2026 1024jp
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

struct PropertyListValueTests {
    
    @Test func string() {
        
        let string = "Dogcow"
        let value = PropertyListValue(string)
        
        #expect(value == .string(string))
        #expect(value.any as? String == string)
    }
    
    
    @Test func bool() {
        
        let bool = true
        let value = PropertyListValue(bool)
        
        #expect(value == .bool(bool))
        #expect(value.any as? Bool == bool)
    }
    
    
    @Test func int() {
        
        let int = 42
        let value = PropertyListValue(int)
        
        #expect(value == .int(int))
        #expect(value.any as? Int == int)
    }
    
    
    @Test func double() {
        
        let double = -1.0
        let value = PropertyListValue(double)
        
        #expect(value == .double(double))
        #expect(value.any as? Double == double)
    }
    
    
    @Test func bridgedNumbers() {
        
        #expect(PropertyListValue(propertyList: NSNumber(value: true)) == .bool(true))
        #expect(PropertyListValue(propertyList: NSNumber(value: 1)) == .int(1))
        #expect(PropertyListValue(propertyList: NSNumber(value: 1.0)) == .double(1.0))
    }
    
    
    @Test func data() {
        
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let value = PropertyListValue(data)
        
        #expect(value == .data(data))
        #expect(value.any as? Data == data)
    }
    
    
    @Test func date() {
        
        let date = Date.now
        let value = PropertyListValue(date)
        
        #expect(value == .date(date))
        #expect(value.any as? Date == date)
    }
    
    
    @Test func array() {
        
        let array: [Any] = [
            "A",
            1,
            5.2,
            false,
            [2, 3],
        ]
        let value = PropertyListValue(array)
        
        #expect(value == .array([
            .string("A"),
            .int(1),
            .double(5.2),
            .bool(false),
            .array([.int(2), .int(3)])
        ]))
        // use NSArray for equitability comparison
        #expect(value.any as? NSArray == array as NSArray)
    }
    
    
    @Test func dictionary() {
        
        let dictionary: [String: Any] = [
            "title": "Dogcow",
            "name": 1024,
            "enabled": true,
            "options": [
                "data": Data([0xDE]),
                "double": 2.0,
            ],
        ]
        let value = PropertyListValue(dictionary)
        
        #expect(value == .dictionary([
            "title": .string("Dogcow"),
            "name": .int(1024),
            "enabled": .bool(true),
            "options": .dictionary([
                "data": .data(Data([0xDE])),
                "double": .double(2.0),
            ])
        ]))
        // use NSDictionary for equitability comparison
        #expect(value.any as? NSDictionary == dictionary as NSDictionary)
    }
    
    
    @Test func invalidValue() {
        
        #expect(PropertyListValue(propertyList: NSObject()) == nil)
        #expect(PropertyListValue(propertyList: ["invalid": NSObject()]) == nil)
    }
    
    
    @Test func plist() throws {
        
        let dictionary: [String: Any] = [
            "title": "Dogcow",
            "name": 1024,
            "enabled": true,
            "options": [
                "data": Data([0xDE]),
                "double": 2.0,
            ],
        ]
        
        #expect(PropertyListSerialization.propertyList(dictionary, isValidFor: .xml))
        
        let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .xml, options: 0)
        
        #expect(!data.isEmpty)
    }
    
    
    @Test func plistRoundTrip() throws {
        
        let value: PropertyListValue = .dictionary([
            "title": .string("Dogcow"),
            "name": .int(1024),
            "enabled": .bool(true),
            "options": .dictionary([
                "data": .data(Data([0xDE])),
                "double": .double(2.0),
            ]),
        ])
        
        let data = try PropertyListSerialization.data(fromPropertyList: value.any, format: .xml, options: 0)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        
        #expect(PropertyListValue(propertyList: plist) == value)
    }
}
