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
    
    func testKeyObservation() {
        
        let key = DefaultKey<Bool>("Test Key")
        defer { UserDefaults.standard.restore(key: key) }
        
        let expectation = self.expectation(description: "UserDefaults observation for normal key")
        
        UserDefaults.standard[key] = false
        
        let observer = UserDefaults.standard.publisher(for: key)
            .sink { (value) in
                XCTAssertTrue(value)
                XCTAssertEqual(OperationQueue.current, .main)
                
                expectation.fulfill()
            }
        
        UserDefaults.standard[key] = true
        self.wait(for: [expectation], timeout: .zero)
        // -> Waiting with zero timeout can be failed when the closure is performed not immediately but in another runloop.
        
        observer.cancel()
        UserDefaults.standard[key] = false
    }
    
    
    func testInitialEmission() {
        
        let key = DefaultKey<Bool>("Initial Emission Test Key")
        defer { UserDefaults.standard.restore(key: key) }
        
        let expectation = self.expectation(description: "UserDefaults observation for initial emission")
        
        UserDefaults.standard[key] = false
        
        let observer = UserDefaults.standard.publisher(for: key, initial: true)
            .sink { (value) in
                XCTAssertFalse(value)
                expectation.fulfill()
            }
        
        observer.cancel()
        UserDefaults.standard[key] = true
        
        self.wait(for: [expectation], timeout: .zero)
    }
    
    
    func testOptionalKey() {
        
        let key = DefaultKey<String?>("Optional Test Key")
        defer { UserDefaults.standard.restore(key: key) }
        
        XCTAssertNil(UserDefaults.standard[key])
        
        UserDefaults.standard[key] = "cow"
        XCTAssertEqual(UserDefaults.standard[key], "cow")
        
        let expectation = self.expectation(description: "UserDefaults observation for optional key")
        let observer = UserDefaults.standard.publisher(for: key)
            .sink { (value) in
                XCTAssertNil(value)
                expectation.fulfill()
            }
        
        UserDefaults.standard[key] = nil
        self.wait(for: [expectation], timeout: .zero)
        
        XCTAssertNil(UserDefaults.standard[key])
        
        observer.cancel()
        UserDefaults.standard[key] = "dog"
        XCTAssertEqual(UserDefaults.standard[key], "dog")
    }
    
    
    func testRawRepresentable() {
        
        enum Clarus: Int  { case dog, cow }
        
        let key = RawRepresentableDefaultKey<Clarus>("Raw Representable Test Key")
        defer { UserDefaults.standard.restore(key: key) }
        
        let expectation = self.expectation(description: "UserDefaults observation for raw representable")
        
        UserDefaults.standard[key] = .dog
        
        let observer = UserDefaults.standard.publisher(for: key)
            .sink { (value) in
                XCTAssertEqual(value, .cow)
                expectation.fulfill()
            }
        
        UserDefaults.standard[key] = .cow
        self.wait(for: [expectation], timeout: .zero)
        
        observer.cancel()
        UserDefaults.standard[key] = .dog
        XCTAssertEqual(UserDefaults.standard[key], .dog)
    }
}
