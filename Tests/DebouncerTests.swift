//
//  DebouncerTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-03-24.
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

final class DebouncerTests: XCTestCase {
    
    func testDebounce() {
        
        let expectation = self.expectation(description: "Debouncer executed")
        let waitingExpectation = self.expectation(description: "Debouncer waiting")
        waitingExpectation.isInverted = true
        
        var value = 0
        let debouncer = Debouncer(delay: .seconds(0.5)) {
            value += 1
            expectation.fulfill()
            waitingExpectation.fulfill()
        }
        
        XCTAssertEqual(value, 0)
        
        debouncer.schedule()
        debouncer.schedule()
        
        self.wait(for: [waitingExpectation], timeout: 0.1)
        
        XCTAssertEqual(value, 0)
        
        self.wait(for: [expectation], timeout: 0.5)
        
        XCTAssertEqual(value, 1)
    }
    
    
    func testImidiateFire() {
        
        var value = 0
        let debouncer = Debouncer {
            value += 1
        }
        
        XCTAssertEqual(0, value)
        
        debouncer.fireNow()
        XCTAssertEqual(value, 0, "The action is performed only when scheduled.")
        
        debouncer.schedule()
        XCTAssertEqual(value, 0)
        
        debouncer.fireNow()
        XCTAssertEqual(value, 1, "The scheduled action must be performed immediately.")
    }
    
    
    func testCancellation() {
        
        let expectation = self.expectation(description: "Debouncer cancelled")
        expectation.isInverted = true
        
        let debouncer = Debouncer {
            expectation.fulfill()
        }
        
        debouncer.schedule()
        debouncer.cancel()
        
        self.waitForExpectations(timeout: 1)
    }
}
