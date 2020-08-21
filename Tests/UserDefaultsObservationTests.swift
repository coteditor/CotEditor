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
//  © 2019-2020 1024jp
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

final class UserDefaultsObservationTests: XCTestCase {
    
    private static let key = DefaultKey<Bool>("TestKey")
    
    private var observer: UserDefaultsObservation?
    
    
    override class func tearDown() {
        
        super.tearDown()
        
        UserDefaults.standard.restore(key: Self.key)
    }
    
    
    func testKeyObservation() {
        
        let expectation = self.expectation(description: "UserDefaults observation")
        
        UserDefaults.standard[Self.key] = false
        
        self.observer = UserDefaults.standard.observe(key: Self.key) { (value) in
            XCTAssertTrue(value!)
            XCTAssertEqual(OperationQueue.current, .main)
            
            expectation.fulfill()
        }
        
        UserDefaults.standard[Self.key] = true
        self.wait(for: [expectation], timeout: .zero)
        // -> Waiting with zero timeout can be failed when the closure is performed not immediately but in another runloop.
        
        self.observer = nil
        UserDefaults.standard[Self.key] = false
    }
    
}
