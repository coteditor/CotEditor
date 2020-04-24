//
//  NSBezierPathTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-04-23.
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

final class NSBezierPathTests: XCTestCase {
    
    func testBezierPathCreationFromCGPath() throws {
        
        let rect = CGRect(x: 1, y: 2, width: 3, height: 4)
        let path = CGPath(rect: rect, transform: nil)
        let bezierPath = NSBezierPath(path: path)
        let expectedPath = NSBezierPath(rect: rect)
        
        XCTAssertEqual(bezierPath.bounds, expectedPath.bounds)
        XCTAssertEqual(bezierPath.elementCount, expectedPath.elementCount)
        
        for index in 0..<bezierPath.elementCount {
            var points1 = [NSPoint](repeating: .zero, count: 3)
            var points2 = [NSPoint](repeating: .zero, count: 3)
            XCTAssertEqual(bezierPath.element(at: index, associatedPoints: &points1),
                           expectedPath.element(at: index, associatedPoints: &points2))
            XCTAssertEqual(points1, points2)
        }
    }
    
}
