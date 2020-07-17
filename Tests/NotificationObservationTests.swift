//
//  NotificationObservationTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-06-29.
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

final class NotificationObservationTests: XCTestCase {
    
    private static let testNotification = Notification.Name("TestNotification")
    
    
    func testSimpleObservation() {
        
        let expectation = self.expectation(description: "Notification observation")
        
        var observer: NotificationObservation? = NotificationCenter.default.addObserver(forName: Self.testNotification, object: nil, queue: nil) { _ in
            expectation.fulfill()
        }
        XCTAssertNotNil(observer)
        
        NotificationCenter.default.post(name: Self.testNotification, object: self)
        
        self.wait(for: [expectation], timeout: .zero)
        
        observer = nil
        NotificationCenter.default.post(name: Self.testNotification, object: self)
    }
    
    
    func testInvalidation() {
        
        let expectation = self.expectation(description: "Notification observation")
        
        var observer: NotificationObservation? = NotificationCenter.default.addObserver(forName: Self.testNotification, object: nil, queue: nil) { _ in
            expectation.fulfill()
        }
        XCTAssertNotNil(observer)
        
        NotificationCenter.default.post(name: Self.testNotification, object: self)
        
        self.wait(for: [expectation], timeout: .zero)
        
        observer?.invalidate()
        observer?.invalidate()
        NotificationCenter.default.post(name: Self.testNotification, object: self)
        
        observer = nil
    }
    
    
    func testWeakObservation() {
        
        let expectation = self.expectation(description: "Notification observation")
        expectation.isInverted = true
        
        weak var observer: NotificationObservation? = NotificationCenter.default.addObserver(forName: Self.testNotification, object: nil, queue: nil) { _ in
            expectation.fulfill()
        }
        XCTAssertNil(observer)
        
        NotificationCenter.default.post(name: Self.testNotification, object: self)
        
        self.wait(for: [expectation], timeout: .zero)
    }
    
}
