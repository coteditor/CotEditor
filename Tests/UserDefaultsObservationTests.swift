//
//  UserDefaultsObservationTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2019-11-22.
//
//  ---------------------------------------------------------------------------
//
//  © 2019-2021 1024jp
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

import Combine
import XCTest
@testable import CotEditor

final class UserDefaultsObservationTests: XCTestCase {
    
    private enum Clarus: Int {
        
        case dog, cow
    }
    
    
    private static let key = DefaultKey<Bool>("TestKey")
    private static let optionalKey = DefaultKey<String?>("OptionalTestKey")
    private static let rawRepresentableKey = RawRepresentableDefaultKey<Clarus>("RawRepresentableTestKey")
    
    
    override func tearDown() {
        
        super.tearDown()
        
        UserDefaults.standard.restore(key: Self.key)
        UserDefaults.standard.restore(key: Self.optionalKey)
        UserDefaults.standard.restore(key: Self.rawRepresentableKey)
    }
    
    
    func testKeyObservation() {
        
        let expectation = self.expectation(description: "UserDefaults observation")
        
        UserDefaults.standard[Self.key] = false
        
        let observer = UserDefaults.standard.publisher(for: Self.key)
            .sink { (value) in
                XCTAssertTrue(value)
                XCTAssertEqual(OperationQueue.current, .main)
                
                expectation.fulfill()
            }
        
        UserDefaults.standard[Self.key] = true
        self.wait(for: [expectation], timeout: .zero)
        // -> Waiting with zero timeout can be failed when the closure is performed not immediately but in another runloop.
        
        observer.cancel()
        UserDefaults.standard[Self.key] = false
    }
    
    
    func testInitialEmission() {
        
        let expectation = self.expectation(description: "UserDefaults observation")
        
        UserDefaults.standard[Self.key] = false
        
        let observer = UserDefaults.standard.publisher(for: Self.key, initial: true)
            .sink { (value) in
                XCTAssertFalse(value)
                expectation.fulfill()
            }
        
        observer.cancel()
        UserDefaults.standard[Self.key] = true
        
        self.wait(for: [expectation], timeout: .zero)
    }
    
    
    func testOptionalKey() {
        
        XCTAssertNil(UserDefaults.standard[Self.optionalKey])
        
        UserDefaults.standard[Self.optionalKey] = "cow"
        XCTAssertEqual(UserDefaults.standard[Self.optionalKey], "cow")
        
        let expectation = self.expectation(description: "UserDefaults observation")
        let observer = UserDefaults.standard.publisher(for: Self.optionalKey)
            .sink { (value) in
                XCTAssertNil(value)
                expectation.fulfill()
            }
        
        UserDefaults.standard[Self.optionalKey] = nil
        self.wait(for: [expectation], timeout: .zero)
        
        XCTAssertNil(UserDefaults.standard[Self.optionalKey])
        
        observer.cancel()
        UserDefaults.standard[Self.optionalKey] = "dog"
        XCTAssertEqual(UserDefaults.standard[Self.optionalKey], "dog")
    }
    
    
    func testRawRepresentable() {
        
        let expectation = self.expectation(description: "UserDefaults observation")
        
        UserDefaults.standard[Self.rawRepresentableKey] = .dog
        
        let observer = UserDefaults.standard.publisher(for: Self.rawRepresentableKey)
            .sink { (value) in
                XCTAssertEqual(value, .cow)
                expectation.fulfill()
            }
        
        UserDefaults.standard[Self.rawRepresentableKey] = .cow
        self.wait(for: [expectation], timeout: .zero)
        
        observer.cancel()
        UserDefaults.standard[Self.rawRepresentableKey] = .dog
        XCTAssertEqual(UserDefaults.standard[Self.rawRepresentableKey], .dog)
    }
    
}
