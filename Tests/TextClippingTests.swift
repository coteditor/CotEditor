//
//  TextClippingTests.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2020-03-13.
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

final class TextClippingTests: XCTestCase {
    
    func testReadingTextClippingFile() throws {
        
        let url = Bundle(for: type(of: self)).url(forResource: "moof", withExtension: "textClipping")!
        let textClipping = try TextClipping(url: url)
        
        XCTAssertEqual(textClipping.string, "🐕moof🐄")
    }
}
