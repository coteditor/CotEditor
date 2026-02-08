//
//  DefaultKeyTests.swift
//  DefaultsTests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2026-02-08.
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
@testable import Defaults

struct DefaultKeyTests {
    
    @Test func defaultKeysMetadata() {
        
        let key = DefaultKey<Bool>("Metadata Key")
        
        #expect(key.rawValue == "Metadata Key")
        #expect(key.description == "Metadata Key")
    }
    
    
    @Test func newValue() throws {
        
        let key = DefaultKey<Int>("Int Key")
        let value = try key.newValue(from: 42)
        
        #expect(value == 42)
    }
    
    
    @Test func newValueOptional() throws {
        
        let key = DefaultKey<String?>("Optional Key")
        
        let nilValue = try key.newValue(from: nil)
        #expect(nilValue == nil)
        
        let stringValue = try key.newValue(from: "cat")
        #expect(stringValue == "cat")
    }
    
    
    @Test func newValueInvalid() {
        
        let key = DefaultKey<Int>("Invalid Key")
        
        #expect(throws: DefaultKeyError.invalidValue) {
            try key.newValue(from: "not-int")
        }
    }
    
    
    @Test func rawRepresentableNewValue() throws {
        
        enum Animal: String { case cat, dog }
        
        let key = RawRepresentableDefaultKey<Animal>("Animal Key")
        let value = try key.newValue(from: "dog")
        
        #expect(value == .dog)
    }
    
    
    @Test func rawRepresentableInvalid() {
        
        enum Animal: Int { case cat = 1, dog = 2 }
        
        let key = RawRepresentableDefaultKey<Animal>("Animal Key")
        
        #expect(throws: DefaultKeyError.invalidValue) {
            try key.newValue(from: 99)
        }
    }
    
    
    @Test func defaultInitializable() {
        
        enum Drink: String, DefaultInitializable {
            
            case coffee
            case tea
            
            static let defaultValue: Drink = .coffee
        }
        
        #expect(Drink("tea") == .tea)
        #expect(Drink(nil) == .coffee)
        #expect(Drink("unknown") == .coffee)
    }
}
