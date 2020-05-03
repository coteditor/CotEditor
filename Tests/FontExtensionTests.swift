//
//  FontExtensionTests.swift
//  Tests
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-06-10.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
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

final class FontExtensionTests: XCTestCase {
    
    func testFontSize() {
        
        let font = NSFont(name: "Menlo-Regular", size: 11)
        
        XCTAssertEqual(font?.width(of: " "), 6.62255859375)
    }
    
    
    func testFontWeight() {
        
        let regularFont = NSFont(name: "Menlo-Regular", size: 11)
        let boldFont = NSFont(name: "Menlo-Bold", size: 11)
        
        XCTAssertEqual(regularFont?.weight, .regular)
        XCTAssertEqual(boldFont!.weight.rawValue, NSFont.Weight.bold.rawValue, accuracy: 0.00001)
        
        // The const value is (unfortunately) not exact equal...
        XCTAssertEqual(boldFont?.weight.rawValue, 0.4)
        XCTAssertNotEqual(NSFont.Weight.bold.rawValue, 0.4)
    }
    
    
    func testNamedFont() {
        
        let menlo = NSFont(named: .menlo, size: 11)
        XCTAssertNotNil(menlo)
        XCTAssertEqual(menlo, NSFont(name: "Menlo-Regular", size: 11))
        
        let avenirNextCondensed = NSFont(named: .avenirNextCondensed, weight: .bold, size: 11)
        XCTAssertNotNil(avenirNextCondensed)
        XCTAssertEqual(avenirNextCondensed, NSFont(name: "AvenirNextCondensed-Bold", size: 11))
        XCTAssertEqual(avenirNextCondensed!.weight.rawValue, NSFont.Weight.bold.rawValue, accuracy: 0.00001)
    }
    
}
